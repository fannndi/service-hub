import '../core/result.dart';
import 'inspector.dart';

class DebugReport {
  final ScenarioResult scenarioResult;
  final List<String> rootCauses;
  final String? fixSuggestion;

  DebugReport({
    required this.scenarioResult,
    required this.rootCauses,
    this.fixSuggestion,
  });

  String get formatted {
    final buf = StringBuffer();
    buf.writeln('🔍 DEBUG REPORT');
    buf.writeln('${'=' * 60}');
    buf.writeln('Scenario: ${scenarioResult.description}');
    buf.writeln('Failed at: ${scenarioResult.failedStepDescription}');
    buf.writeln('');
    buf.writeln('Root Causes:');
    for (final cause in rootCauses) {
      buf.writeln('  $cause');
    }
    if (fixSuggestion != null) {
      buf.writeln('');
      buf.writeln('💡 Suggestion:');
      buf.writeln('  $fixSuggestion');
    }
    return buf.toString();
  }
}

class Debugger {
  final StateInspector inspector;

  Debugger(this.inspector);

  Future<DebugReport> debug(ScenarioResult result) async {
    final rootCauses = <String>[];

    for (final step in result.steps) {
      if (!step.passed && step.errorMessage != null) {
        final causes = await inspector.diagnoseError(step.errorMessage!);
        rootCauses.addAll(causes);
      }
    }

    final fixSuggestion = _generateFix(result, rootCauses);

    return DebugReport(
      scenarioResult: result,
      rootCauses: rootCauses,
      fixSuggestion: fixSuggestion,
    );
  }

  String? _generateFix(ScenarioResult result, List<String> causes) {
    if (causes.isEmpty) return null;

    final combined = causes.join(' ').toLowerCase();

    if (combined.contains('auth_error')) {
      return 'Pastikan credentials di flow definition sudah benar. '
          'Coba login manual dulu untuk verifikasi.';
    }
    if (combined.contains('state_error')) {
      return 'Cek urutan status di scenario. Gunakan state machine: '
          'waiting_device → device_received → diagnosing → waiting_approval → '
          'repairing → quality_check → waiting_payment → completed';
    }
    if (combined.contains('not_found')) {
      return 'Cek apakah seed data sudah dijalankan. '
          'Pastikan store_id, sparepart_id, order_id ada di database.';
    }
    if (combined.contains('fk_error')) {
      return 'Foreign key violation. Pastikan semua referensi ID valid '
          'dengan cek database langsung.';
    }
    if (combined.contains('timeout')) {
      return 'Cold start issue. Jalankan ulang scenario — setelah warmup '
          'seharusnya lebih cepat.';
    }

    return 'Lihat error detail di atas dan perbaiki sesuai penyebab.';
  }
}
