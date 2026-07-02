class TestSuiteResult {
  final List<ScenarioResult> scenarios;
  final DateTime startedAt;
  final DateTime finishedAt;
  final String? reportPath;

  TestSuiteResult({
    required this.scenarios,
    required this.startedAt,
    required this.finishedAt,
    this.reportPath,
  });

  int get total => scenarios.length;
  int get passed => scenarios.where((s) => s.passed).length;
  int get failed => scenarios.where((s) => !s.passed && !s.errored).length;
  int get errored => scenarios.where((s) => s.errored).length;
  Duration get duration => finishedAt.difference(startedAt);

  String get summary {
    final buf = StringBuffer();
    buf.writeln('Test Suite Summary');
    buf.writeln('=' * 60);
    buf.writeln('Total:     $total');
    buf.writeln('Passed:    $passed ✅');
    buf.writeln('Failed:    $failed ❌');
    buf.writeln('Errored:   $errored ⚠️');
    buf.writeln('Duration:  ${duration.inSeconds}s');
    buf.writeln('');
    for (final s in scenarios) {
      buf.writeln('  ${s.passed ? "✅" : "❌"} ${s.scenarioId}: ${s.stepsPassed}/${s.stepsTotal} passed');
    }
    return buf.toString();
  }
}

class ScenarioResult {
  final String scenarioId;
  final String description;
  final List<StepResult> steps;
  final DateTime startedAt;
  final DateTime finishedAt;

  ScenarioResult({
    required this.scenarioId,
    required this.description,
    required this.steps,
    required this.startedAt,
    required this.finishedAt,
  });

  bool get passed => steps.every((s) => s.passed);
  bool get errored => steps.any((s) => s.errored);
  int get stepsPassed => steps.where((s) => s.passed).length;
  int get stepsTotal => steps.length;

  String get failedStepDescription {
    for (final s in steps) {
      if (!s.passed) return 'Step "${s.stepId}": ${s.errorMessage ?? "assertion failed"}';
    }
    return '';
  }
}

class StepResult {
  final String stepId;
  final String description;
  final bool passed;
  final bool errored;
  final String? errorMessage;
  final String? suggestion;
  final Map<String, dynamic>? responseData;
  final List<String> assertionMessages;
  final DateTime timestamp;

  StepResult({
    required this.stepId,
    required this.description,
    required this.passed,
    this.errored = false,
    this.errorMessage,
    this.suggestion,
    this.responseData,
    this.assertionMessages = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
