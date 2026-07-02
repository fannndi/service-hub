import '../core/scenario.dart';
import '../core/result.dart';
import 'supabase_client.dart';
import 'retry_handler.dart';
import 'warmupper.dart';

class ScenarioRunner {
  final AgentSupabaseClient client;
  final bool verbose;
  final RetryHandler _retry = const RetryHandler();

  ScenarioRunner({required this.client, this.verbose = false});

  Future<TestSuiteResult> runAll(List<Scenario> scenarios) async {
    final startedAt = DateTime.now();
    final results = <ScenarioResult>[];

    await WarmUpper.warmAll(client);

    for (var i = 0; i < scenarios.length; i++) {
      print('\n${'=' * 60}');
      print('Scenario ${i + 1}/${scenarios.length}: ${scenarios[i].description}');
      print('${'=' * 60}');

      final result = await runScenario(scenarios[i]);
      results.add(result);

      print(result.passed ? '  ✅ PASS' : '  ❌ FAIL');
      if (verbose && !result.passed) {
        print('  ${result.failedStepDescription}');
      }

      // Delay between scenarios (respect free tier)
      if (i < scenarios.length - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    final finishedAt = DateTime.now();
    return TestSuiteResult(
      scenarios: results,
      startedAt: startedAt,
      finishedAt: finishedAt,
    );
  }

  Future<ScenarioResult> runScenario(Scenario scenario) async {
    final startedAt = DateTime.now();
    final stepResults = <StepResult>[];
    final vars = <String, String>{};

    // Setup: run seed if configured
    if (scenario.setupData != null) {
      print('  📦 Setting up test data...');
      await _runSetup(scenario.setupData!, vars);
    }

    for (var i = 0; i < scenario.steps.length; i++) {
      final step = scenario.steps[i];
      print('  Step ${i + 1}/${scenario.steps.length}: ${step.description}');

      final result = await _runStep(step, vars);

      if (verbose && result.responseData != null) {
        print('    Response: ${result.responseData}');
      }
      for (final msg in result.assertionMessages) {
        print('    ${msg.startsWith("✓") ? "  ✅" : "  ❌"} $msg');
      }

      stepResults.add(result);

      if (!result.passed) {
        print('  ❌ Step failed: ${result.errorMessage}');
        if (result.suggestion != null) {
          print('  💡 ${result.suggestion}');
        }
        break;
      }

      // Delay between steps (respect free tier)
      if (i < scenario.steps.length - 1) {
        await Future.delayed(const Duration(milliseconds: 1500));
      }
    }

    // Cleanup
    if (scenario.cleanupData != null) {
      await _runCleanup(scenario.cleanupData!);
    }

    return ScenarioResult(
      scenarioId: scenario.id,
      description: scenario.description,
      steps: stepResults,
      startedAt: startedAt,
      finishedAt: DateTime.now(),
    );
  }

  Future<StepResult> _runStep(ScenarioStep step, Map<String, String> vars) async {
    try {
      final action = step.action;
      final resolvedBody = action.resolve(vars);
      final resolvedTarget = action.resolveTarget(vars);

      Map<String, dynamic>? response;

      switch (action.type) {
        case 'invoke':
          response = await _retry.execute(
            () => client.invoke(resolvedTarget, resolvedBody),
            label: 'invoke $resolvedTarget',
          );
          break;
        case 'auth_login':
          final email = resolvedBody['email'] as String? ?? '';
          final password = resolvedBody['password'] as String? ?? '';
          await client.login(email, password);
          response = {'success': true, 'data': {'email': email}};
          break;
        case 'admin_query':
          final sql = resolvedBody['query'] as String? ?? '';
          response = await client.adminQuery(sql);
          break;
        case 'admin_table':
          final table = resolvedBody['table'] as String? ?? '';
          final select = resolvedBody['select'] as String?;
          final limit = resolvedBody['limit'] as int?;
          final data = await client.adminTable(table, select: select, limit: limit);
          response = {'success': true, 'data': data};
          break;
        case 'wait':
          final seconds = resolvedBody['seconds'] as int? ?? 2;
          await Future.delayed(Duration(seconds: seconds));
          response = {'success': true, 'data': {'waited': seconds}};
          break;
        default:
          return StepResult(
            stepId: step.id,
            description: step.description,
            passed: false,
            errored: true,
            errorMessage: 'Unknown action type: ${action.type}',
          );
      }

      // Evaluate assertions
      final assertionMessages = <String>[];
      var allPassed = true;
      for (final assertion in step.asserts) {
        final result = assertion.evaluate(response ?? {});
        assertionMessages.add(result.message);
        if (!result.passed) allPassed = false;
      }

      // If no assertions, check success field
      if (step.asserts.isEmpty) {
        if (response?['success'] == false) {
          allPassed = false;
          assertionMessages.add('Response success=false');
        } else {
          assertionMessages.add('Response OK');
        }
      }

      return StepResult(
        stepId: step.id,
        description: step.description,
        passed: allPassed,
        assertionMessages: assertionMessages,
        responseData: response,
      );
    } catch (e) {
      final suggestion = _generateSuggestion(step, e);
      return StepResult(
        stepId: step.id,
        description: step.description,
        passed: false,
        errored: true,
        errorMessage: e.toString(),
        suggestion: suggestion,
      );
    }
  }

  String? _generateSuggestion(ScenarioStep step, Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('401') || msg.contains('unauthorized')) {
      return 'Auth error: pastikan login credentials benar dan role sesuai';
    }
    if (msg.contains('404') || msg.contains('not found')) {
      return 'Data tidak ditemukan: pastikan test data sudah di-seed';
    }
    if (msg.contains('invalid status transition') || msg.contains('INVALID_STATUS_TRANSITION')) {
      return 'State machine: transisi status tidak valid. Cek urutan status yang benar';
    }
    if (msg.contains('violates foreign key')) {
      return 'Foreign key violation: pastikan referensi ID valid';
    }
    if (msg.contains('duplicate') || msg.contains('unique constraint')) {
      return 'Duplicate data: coba gunakan data yang unik';
    }
    if (msg.contains('timeout')) {
      return 'Timeout: Supabase cold start. Coba jalankan ulang step ini';
    }
    return null;
  }

  Future<void> _runSetup(Map<String, dynamic> setup, Map<String, String> vars) async {
    // Will be implemented for seeding test data
  }

  Future<void> _runCleanup(Map<String, dynamic> cleanup) async {
    // Will be implemented for cleaning up test data
  }
}
