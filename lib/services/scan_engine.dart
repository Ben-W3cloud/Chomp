import 'dart:async';
import 'dart:convert';
import '../core/constants.dart';
import 'api_client.dart';

enum ScanPhase {
  fetching,
  ingesting,
  analysing,
  codeReview,
  securityCheck,
  docsEval,
  testsEval,
  complete,
  error,
}

class ScanPhaseEvent {
  final ScanPhase phase;
  final String message;
  final Map<String, dynamic>? payload; // only set on `complete`
  const ScanPhaseEvent(this.phase, this.message, [this.payload]);
}

/// Runs a manual, live scan for one repo. All the real work — GitHub
/// fetch, NVIDIA analysis, Groq evaluation — happens server-side (the
/// API keys never touch the phone). This just opens a Server-Sent
/// Events connection and turns each event into a line for the UI's
/// scan log.
class ScanEngine {
  final _api = ApiClient.instance;

  Stream<ScanPhaseEvent> runScan(String repoId) {
    final controller = StreamController<ScanPhaseEvent>();
    _stream(repoId, controller);
    return controller.stream;
  }

  Future<void> _stream(
      String repoId, StreamController<ScanPhaseEvent> controller) async {
    try {
      final streamed =
          await _api.openStream('${ApiEndpoints.scanRepo}/$repoId');
      final lines = streamed.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      String? eventName;
      final buffer = StringBuffer();

      await for (final line in lines) {
        if (line.startsWith('event:')) {
          eventName = line.substring(6).trim();
        } else if (line.startsWith('data:')) {
          buffer.write(line.substring(5).trim());
        } else if (line.isEmpty && buffer.isNotEmpty) {
          final data = jsonDecode(buffer.toString()) as Map<String, dynamic>;
          buffer.clear();
          final phase = _parsePhase(eventName ?? data['phase'] as String?);
          controller.add(ScanPhaseEvent(
            phase,
            data['message'] as String? ?? phase.name,
            data['result'] as Map<String, dynamic>?,
          ));
          eventName = null;
          if (phase == ScanPhase.complete || phase == ScanPhase.error) {
            await controller.close();
            return;
          }
        }
      }
      await controller.close();
    } catch (e) {
      controller.add(ScanPhaseEvent(ScanPhase.error, 'Scan failed: $e'));
      await controller.close();
    }
  }

  ScanPhase _parsePhase(String? raw) {
    switch (raw) {
      case 'fetching':
        return ScanPhase.fetching;
      case 'ingesting':
        return ScanPhase.ingesting;
      case 'analysing':
        return ScanPhase.analysing;
      case 'code_review':
        return ScanPhase.codeReview;
      case 'security_check':
        return ScanPhase.securityCheck;
      case 'docs_eval':
        return ScanPhase.docsEval;
      case 'tests_eval':
        return ScanPhase.testsEval;
      case 'complete':
        return ScanPhase.complete;
      default:
        return ScanPhase.error;
    }
  }
}
