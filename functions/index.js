const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const axios = require("axios");

initializeApp();
const db = getFirestore();

// ─── Helper: call Gemini API ────────────────────────────────────────────────

async function callGemini(prompt) {
  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) throw new HttpsError("internal", "Gemini API key not configured");

  const res = await axios.post(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${apiKey}`,
    {
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        responseMimeType: "application/json",
        temperature: 0.4,
      },
    },
    { timeout: 55000 }
  );

  const raw = res.data?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!raw) throw new HttpsError("internal", "Empty Gemini response");

  try {
    return JSON.parse(raw);
  } catch {
    // Attempt to extract JSON from markdown code blocks
    const match = raw.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (match) return JSON.parse(match[1]);
    throw new HttpsError("internal", "Could not parse Gemini JSON response");
  }
}

// ─── analyzeTranscript ───────────────────────────────────────────────────────

exports.analyzeTranscript = onCall(
  { timeoutSeconds: 120, memory: "512MiB" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be authenticated");
    }

    const { sessionId, userId, transcript, jobRole, domain, difficulty } =
      request.data;

    if (!sessionId || !transcript) {
      throw new HttpsError("invalid-argument", "Missing sessionId or transcript");
    }

    // Verify the session belongs to the requesting user
    const sessionSnap = await db.collection("sessions").doc(sessionId).get();
    if (!sessionSnap.exists || sessionSnap.data().userId !== request.auth.uid) {
      throw new HttpsError("permission-denied", "Access denied");
    }

    const prompt = `
You are an expert interview evaluator. Analyze the following mock interview transcript 
for a ${difficulty} ${domain} interview for the role of "${jobRole}".

TRANSCRIPT:
${transcript}

Return a JSON object with EXACTLY this structure (no extra keys):
{
  "overallScore": <integer 0-100>,
  "categoryScores": {
    "communication": <integer 0-100>,
    "technical": <integer 0-100>,
    "problemSolving": <integer 0-100>,
    "confidence": <integer 0-100>
  },
  "strengths": ["<strength 1>", "<strength 2>", "<strength 3>"],
  "improvements": ["<improvement 1>", "<improvement 2>", "<improvement 3>"],
  "generalFeedback": ["<feedback point 1>", "<feedback point 2>"],
  "questionResults": [
    {
      "question": "<the question asked>",
      "answer": "<summary of candidate's answer>",
      "score": <integer 0-10>,
      "feedback": "<specific feedback>",
      "idealAnswer": "<what a strong answer would include>"
    }
  ]
}

Be specific, constructive, and encouraging. Base everything strictly on the transcript.
`;

    let analysis;
    try {
      analysis = await callGemini(prompt);
    } catch (err) {
      console.error("Gemini analysis error:", err.message);
      throw new HttpsError("internal", `Analysis failed: ${err.message}`);
    }

    // Write result to Firestore
    const resultData = {
      ...analysis,
      sessionId,
      userId,
      transcript,
      createdAt: FieldValue.serverTimestamp(),
    };

    await db.collection("results").doc(sessionId).set(resultData);

    // Update session status
    await db.collection("sessions").doc(sessionId).update({
      status: "completed",
      endedAt: FieldValue.serverTimestamp(),
    });

    // Update user stats atomically
    const userRef = db.collection("users").doc(userId);
    await db.runTransaction(async (tx) => {
      const userSnap = await tx.get(userRef);
      const data = userSnap.data() || {};
      const prevTotal = data.totalSessions || 0;
      const prevAvg = data.avgScore || 0;
      const newTotal = prevTotal + 1;
      const newAvg = ((prevAvg * prevTotal) + analysis.overallScore) / newTotal;
      tx.update(userRef, {
        totalSessions: newTotal,
        avgScore: parseFloat(newAvg.toFixed(1)),
      });
    });

    return analysis;
  }
);

// ─── generateQuestions ───────────────────────────────────────────────────────

exports.generateQuestions = onCall(
  { timeoutSeconds: 60 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be authenticated");
    }

    const { jobRole, domain, difficulty, count = 10 } = request.data;

    const prompt = `
Generate ${count} interview questions for a ${difficulty} ${domain} interview 
for the role of "${jobRole}".

Return a JSON array with EXACTLY this structure:
[
  {
    "text": "<the interview question>",
    "domain": "${domain}",
    "level": "${difficulty}",
    "tags": ["<tag1>", "<tag2>"],
    "hint": "<optional interviewer hint>"
  }
]

Make questions realistic, varied in depth, and appropriate for ${difficulty} level.
`;

    const questions = await callGemini(prompt);
    return Array.isArray(questions) ? questions : [];
  }
);

// ─── createVapiAssistant ─────────────────────────────────────────────────────

exports.createVapiAssistant = onCall(
  { timeoutSeconds: 30 },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Must be authenticated");
    }

    const { jobRole, domain, difficulty, resumeContext } = request.data;
    const vapiApiKey = process.env.VAPI_API_KEY;

    if (!vapiApiKey) {
      throw new HttpsError("internal", "Vapi API key not configured");
    }

    const systemPrompt = `You are an expert technical interviewer conducting a ${difficulty} ${domain} 
interview for the position of ${jobRole}. 

${resumeContext ? `Candidate's resume context:\n${resumeContext}\n` : ""}

Your task:
1. Greet the candidate warmly
2. Ask 5-7 relevant interview questions based on the role and difficulty
3. Listen carefully and ask follow-up questions when needed
4. Be professional, encouraging, and constructive
5. End the interview politely after 15-20 minutes

Focus on: ${domain === "technical" ? "coding concepts, system design, algorithms" : 
           domain === "hr" ? "culture fit, motivation, career goals" : 
           domain === "behavioral" ? "STAR method stories, past experiences" : 
           "a mix of technical and behavioral questions"}`;

    try {
      const res = await axios.post(
        "https://api.vapi.ai/assistant",
        {
          name: `PrepX Interview - ${jobRole}`,
          model: {
            provider: "openai",
            model: "gpt-4o",
            messages: [{ role: "system", content: systemPrompt }],
          },
          voice: {
            provider: "11labs",
            voiceId: "21m00Tcm4TlvDq8ikWAM", // Rachel voice
          },
          firstMessage: `Hello! I'm your PrepX AI interviewer. We'll be having a ${difficulty} ${domain} interview today for the ${jobRole} position. Are you ready to begin?`,
          endCallMessage: "Thank you for your time! Your interview has been completed and we'll send you detailed feedback shortly. Good luck!",
          maxDurationSeconds: 1800, // 30 minutes max
        },
        {
          headers: {
            Authorization: `Bearer ${vapiApiKey}`,
            "Content-Type": "application/json",
          },
        }
      );

      return { assistantId: res.data.id };
    } catch (err) {
      console.error("Vapi assistant creation error:", err.response?.data || err.message);
      throw new HttpsError("internal", "Failed to create Vapi assistant");
    }
  }
);
