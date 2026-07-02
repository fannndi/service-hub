import 'action.dart';
import 'assertion.dart';

class Scenario {
  final String id;
  final String description;
  final List<ScenarioStep> steps;
  final Map<String, dynamic>? setupData;
  final Map<String, dynamic>? cleanupData;

  const Scenario({
    required this.id,
    required this.description,
    required this.steps,
    this.setupData,
    this.cleanupData,
  });

  factory Scenario.fromYaml(Map<String, dynamic> yaml) {
    final stepsList = (yaml['steps'] as List?) ?? [];
    return Scenario(
      id: yaml['id'] as String? ?? '',
      description: yaml['description'] as String? ?? '',
      steps: stepsList.map((s) => ScenarioStep.fromYaml(s as Map<String, dynamic>)).toList(),
      setupData: yaml['setup'] as Map<String, dynamic>?,
      cleanupData: yaml['cleanup'] as Map<String, dynamic>?,
    );
  }
}

class ScenarioStep {
  final String id;
  final String description;
  final SchematicAction action;
  final List<Assertion> asserts;
  final int timeoutSeconds;

  const ScenarioStep({
    required this.id,
    required this.description,
    required this.action,
    this.asserts = const [],
    this.timeoutSeconds = 20,
  });

  factory ScenarioStep.fromYaml(Map<String, dynamic> yaml) {
    final actionYaml = yaml['action'] as Map<String, dynamic>? ?? {};
    final assertsList = (yaml['asserts'] as List?) ?? [];
    return ScenarioStep(
      id: yaml['id'] as String? ?? '',
      description: yaml['description'] as String? ?? '',
      action: SchematicAction.fromYaml(actionYaml),
      asserts: assertsList.map((a) => Assertion.fromYaml(a as Map<String, dynamic>)).toList(),
      timeoutSeconds: yaml['timeout'] as int? ?? 20,
    );
  }
}
