// #region agent log
import 'dart:convert';
import 'dart:io';

const _logPath = '/Users/zhouzirui/Desktop/tempo/.cursor/debug-c0bcb2.log';
const _ingestUrl =
    'http://127.0.0.1:7539/ingest/ed007f7d-2b9e-42cb-ae5d-69108bed2252';

/// Debug-mode NDJSON logger (session c0bcb2). Remove after verification.
void agentDebugLog({
  required String location,
  required String message,
  Map<String, dynamic>? data,
  String? hypothesisId,
  String runId = 'pre-fix',
}) {
  final payload = <String, dynamic>{
    'sessionId': 'c0bcb2',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'location': location,
    'message': message,
    'data': data ?? <String, dynamic>{},
    'hypothesisId': hypothesisId,
    'runId': runId,
  };
  final line = '${jsonEncode(payload)}\n';

  try {
    File(_logPath).writeAsStringSync(line, mode: FileMode.append, flush: true);
  } catch (_) {}

  try {
    final client = HttpClient();
    client
        .postUrl(Uri.parse(_ingestUrl))
        .then((request) {
          request.headers.set('Content-Type', 'application/json');
          request.headers.set('X-Debug-Session-Id', 'c0bcb2');
          request.add(utf8.encode(jsonEncode(payload)));
          return request.close();
        })
        .then((response) => response.drain())
        .whenComplete(client.close);
  } catch (_) {}
}
// #endregion
