import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:permission_handler/permission_handler.dart';

enum VapiCallStatus { idle, connecting, active, ended, error }

class VapiMessage {
  final String type;
  final String? role;
  final String? content;
  final Map<String, dynamic>? raw;

  VapiMessage({required this.type, this.role, this.content, this.raw});
}

class VapiService {
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

  final List<Map<String, String>> _transcript = [];
  List<Map<String, String>> get transcript => List.unmodifiable(_transcript);

  bool _isDisposed = false;

  // ─── START INTERVIEW ──────────────────────────────────────────────────────
  Future<String?> startInterview({
    required String jobRole,
    required String domain,
    required String difficulty,
    String? resumeContext,
  }) async {
    if (_isDisposed) return null;

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      _emitStatus(VapiCallStatus.error);
      throw Exception('Microphone permission denied');
    }

    _emitStatus(VapiCallStatus.connecting);
    _transcript.clear();

    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://api.vapi.ai/call/web'),
      );

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
          'firstMessage': 'Hello! I\'m your PrepX AI interviewer today. Ready?',
        },
      });

      _channel!.sink.add(startPayload);

      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          _emitStatus(VapiCallStatus.error);
          _safeAddMessage(
            VapiMessage(type: 'error', content: error.toString()),
          );
        },
        onDone: () {
          if (_status == VapiCallStatus.active) {
            _emitStatus(VapiCallStatus.ended);
          }
        },
      );

      return null;
    } catch (e) {
      _emitStatus(VapiCallStatus.error);
      rethrow;
    }
  }

  // ─── HANDLE MESSAGE ───────────────────────────────────────────────────────
  void _handleMessage(dynamic raw) {
    if (_isDisposed) return;

    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      final type = data['type'] as String? ?? '';

      switch (type) {
        case 'call-start':
          _emitStatus(VapiCallStatus.active);
          _safeAddMessage(
            VapiMessage(type: type, content: data['callId']),
          );
          break;

        case 'transcript':
          final role = data['role'] as String?;
          final text = data['transcript'] as String? ?? '';

          if (text.isNotEmpty) {
            _transcript.add({'role': role ?? 'unknown', 'text': text});
            _safeAddMessage(
              VapiMessage(type: type, role: role, content: text),
            );
          }
          break;

        case 'call-end':
          _emitStatus(VapiCallStatus.ended);
          _safeAddMessage(VapiMessage(type: type));
          break;

        case 'error':
          _emitStatus(VapiCallStatus.error);
          _safeAddMessage(
            VapiMessage(type: type, content: data['message']?.toString()),
          );
          break;

        default:
          _safeAddMessage(VapiMessage(type: type, raw: data));
      }
    } catch (_) {}
  }

  // ─── SAFE ADD METHODS (CRITICAL FIX) ───────────────────────────────────────
  void _safeAddMessage(VapiMessage msg) {
    if (!_messageController.isClosed && !_isDisposed) {
      _messageController.add(msg);
    }
  }

  void _emitStatus(VapiCallStatus s) {
    _status = s;
    if (!_statusController.isClosed && !_isDisposed) {
      _statusController.add(s);
    }
  }

  // ─── STOP INTERVIEW ───────────────────────────────────────────────────────
  Future<void> stopInterview() async {
    if (_channel != null) {
      try {
        _channel!.sink.add(jsonEncode({'type': 'stop'}));
        await Future.delayed(const Duration(milliseconds: 200));
        await _channel!.sink.close();
      } catch (_) {}
      _channel = null;
    }

    _emitStatus(VapiCallStatus.ended);
  }

  // ─── DISPOSE (FIXED) ──────────────────────────────────────────────────────
  Future<void> dispose() async {
    _isDisposed = true;

    try {
      await stopInterview();
    } catch (_) {}

    if (!_messageController.isClosed) {
      await _messageController.close();
    }

    if (!_statusController.isClosed) {
      await _statusController.close();
    }
  }

  // ─── UTIL ─────────────────────────────────────────────────────────────────
  String buildTranscriptString() {
    return _transcript
        .map((t) => '${t['role']?.toUpperCase()}: ${t['text']}')
        .join('\n');
  }
}
