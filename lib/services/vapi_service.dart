import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:permission_handler/permission_handler.dart';

enum VapiCallStatus { idle, connecting, active, ended, error }

class VapiMessage {
  final String type;
  final String? role;      // 'assistant' | 'user'
  final String? content;
  final Map<String, dynamic>? raw;

  VapiMessage({required this.type, this.role, this.content, this.raw});
}

class VapiService {
  // Replace with your actual Vapi public key and assistant ID
  static const String _vapiPublicKey = 'YOUR_VAPI_PUBLIC_KEY';
  static const String _assistantId = 'YOUR_VAPI_ASSISTANT_ID';

  WebSocketChannel? _channel;
  final StreamController<VapiMessage> _messageController =
      StreamController<VapiMessage>.broadcast();
  final StreamController<VapiCallStatus> _statusController =
      StreamController<VapiCallStatus>.broadcast();

  Stream<VapiMessage> get messages => _messageController.stream;
  Stream<VapiCallStatus> get statusStream => _statusController.stream;

  VapiCallStatus _status = VapiCallStatus.idle;
  VapiCallStatus get status => _status;

  // Accumulated transcript
  final List<Map<String, String>> _transcript = [];
  List<Map<String, String>> get transcript => List.unmodifiable(_transcript);

  // ─── Start Call ───────────────────────────────────────────────────────────

  Future<String?> startInterview({
    required String jobRole,
    required String domain,
    required String difficulty,
    String? resumeContext,
  }) async {
    // 1. Request microphone permission
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      _emitStatus(VapiCallStatus.error);
      throw Exception('Microphone permission denied');
    }

    _emitStatus(VapiCallStatus.connecting);
    _transcript.clear();

    try {
      // 2. Open WebSocket to Vapi
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://api.vapi.ai/call/web'),
      );

      // 3. Send start message with assistant configuration
      final startPayload = jsonEncode({
        'type': 'start',
        'publicKey': _vapiPublicKey,
        'assistantId': _assistantId,
        'assistantOverrides': {
          'variableValues': {
            'jobRole': jobRole,
            'domain': domain,
            'difficulty': difficulty,
            'resumeContext': resumeContext ?? 'Not provided',
          },
          'firstMessage':
              'Hello! I\'m your PrepX AI interviewer today. We\'ll be doing a $difficulty $domain interview for a $jobRole position. Are you ready to begin?',
        },
      });

      _channel!.sink.add(startPayload);

      // 4. Listen for messages
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          _emitStatus(VapiCallStatus.error);
          _messageController.addError(error);
        },
        onDone: () {
          if (_status == VapiCallStatus.active) {
            _emitStatus(VapiCallStatus.ended);
          }
        },
      );

      return null; // callId comes via message event
    } catch (e) {
      _emitStatus(VapiCallStatus.error);
      rethrow;
    }
  }

  // ─── Message Handler ──────────────────────────────────────────────────────

  void _handleMessage(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';

      switch (type) {
        case 'call-start':
          _emitStatus(VapiCallStatus.active);
          final callId = data['callId'] as String?;
          _messageController.add(
            VapiMessage(type: type, raw: data, content: callId),
          );
          break;

        case 'transcript':
          final role = data['role'] as String?;
          final text = data['transcript'] as String? ?? '';
          if (text.isNotEmpty) {
            _transcript.add({'role': role ?? 'unknown', 'text': text});
            _messageController.add(
              VapiMessage(type: type, role: role, content: text, raw: data),
            );
          }
          break;

        case 'call-end':
          _emitStatus(VapiCallStatus.ended);
          _messageController.add(VapiMessage(type: type, raw: data));
          break;

        case 'error':
          _emitStatus(VapiCallStatus.error);
          _messageController.add(
            VapiMessage(type: type, content: data['message']?.toString(), raw: data),
          );
          break;

        default:
          _messageController.add(VapiMessage(type: type, raw: data));
      }
    } catch (_) {
      // Ignore malformed messages
    }
  }

  // ─── Stop Call ────────────────────────────────────────────────────────────

  Future<void> stopInterview() async {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({'type': 'stop'}));
      await Future.delayed(const Duration(milliseconds: 300));
      await _channel!.sink.close();
      _channel = null;
    }
    _emitStatus(VapiCallStatus.ended);
  }

  // ─── Utils ────────────────────────────────────────────────────────────────

  void _emitStatus(VapiCallStatus s) {
    _status = s;
    _statusController.add(s);
  }

  String buildTranscriptString() {
    return _transcript
        .map((t) => '${t['role']?.toUpperCase()}: ${t['text']}')
        .join('\n');
  }

  void dispose() {
    _channel?.sink.close();
    _messageController.close();
    _statusController.close();
  }
}
