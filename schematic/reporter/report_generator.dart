import 'dart:io';

import '../core/result.dart';
import '../agent/debugger.dart';
import '../core/scenario.dart';

class ReportGenerator {
  static Future<String> generateFullReport({
    required TestSuiteResult testResult,
    required List<Scenario> scenarios,
    required List<DebugReport> debugReports,
    required String guide,
  }) async {
    final buf = StringBuffer();
    buf.writeln('# 🤖 AI Agent Test Report');
    buf.writeln('');
    buf.writeln('**Generated:** ${DateTime.now()}');
    buf.writeln('');
    buf.writeln('---');
    buf.writeln('');

    // Summary
    buf.writeln('## 📊 Summary');
    buf.writeln('');
    buf.writeln(testResult.summary);
    buf.writeln('');

    // Per-scenario details
    buf.writeln('---');
    buf.writeln('## 📋 Scenario Details');
    buf.writeln('');

    for (var i = 0; i < testResult.scenarios.length; i++) {
      final result = testResult.scenarios[i];
      final scenario = scenarios[i];
      buf.writeln('### ${result.passed ? "✅" : "❌"} ${scenario.description}');
      buf.writeln('');
      buf.writeln('| Step | Status | Detail |');
      buf.writeln('|------|--------|--------|');

      for (final step in result.steps) {
        final icon = step.passed ? '✅' : (step.errored ? '⚠️' : '❌');
        final detail = step.errorMessage ?? step.assertionMessages.join('; ');
        buf.writeln('| ${step.stepId} | $icon | $detail |');
      }
      buf.writeln('');

      // Debug if failed
      if (!result.passed && i < debugReports.length) {
        buf.writeln('**Debug:**');
        buf.writeln('```');
        buf.writeln(debugReports[i].formatted);
        buf.writeln('```');
        buf.writeln('');
      }
    }

    // User Guide
    buf.writeln('---');
    buf.writeln('## 📖 Panduan Pengguna');
    buf.writeln('');
    buf.writeln(guide);

    return buf.toString();
  }

  static Future<void> saveToFile(String report, String path) async {
    await File(path).writeAsString(report);
    print('\n📄 Report saved to: $path');
  }
}
