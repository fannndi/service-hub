import 'dart:io';

import 'executor/supabase_client.dart';
import 'executor/scenario_runner.dart';
import 'agent/inspector.dart';
import 'agent/debugger.dart';
import 'agent/guide_generator.dart';
import 'reporter/report_generator.dart';
import 'definitions/all_scenarios.dart';

void main(List<String> args) async {
  final config = _parseArgs(args);
  if (config['help'] == true) {
    _printHelp();
    return;
  }

  print('');
  print('╔═══════════════════════════════════════╗');
  print('║   🤖 Schematic AI Agent — Service Me ║');
  print('╚═══════════════════════════════════════╝');
  print('');

  final supabaseUrl = config['supabase_url'] != null
      ? config['supabase_url'] as String
      : (Platform.environment['SUPABASE_URL'] ?? _prompt('Supabase URL'));
  final anonKey = config['anon_key'] != null
      ? config['anon_key'] as String
      : (Platform.environment['SUPABASE_ANON_KEY'] ?? _prompt('Supabase Anon Key'));
  final serviceKey = config['service_key'] as String? ??
      Platform.environment['SUPABASE_SERVICE_ROLE_KEY'] ??
      '';
  final mgmtToken = config['mgmt_token'] as String? ??
      Platform.environment['SUPABASE_ACCESS_TOKEN'] ??
      '';
  final projectRef = config['project_ref'] as String? ??
      Platform.environment['SUPABASE_PROJECT_REF'] ??
      'eboplbemgtvmviwhdlfa';

  final client = AgentSupabaseClient(
    supabaseUrl: supabaseUrl,
    anonKey: anonKey,
    serviceRoleKey: serviceKey.isNotEmpty ? serviceKey : null,
    managementToken: mgmtToken.isNotEmpty ? mgmtToken : null,
    projectRef: projectRef,
  );

  final scenarios = AllScenarios.list;
  final filtered = config['flow'] != null
      ? scenarios.where((s) => s.id.contains(config['flow'] as String)).toList()
      : scenarios;

  if (filtered.isEmpty) {
    print('❌ No scenarios found');
    return;
  }

  print('Running ${filtered.length} scenario(s)\n');
  final runner = ScenarioRunner(client: client, verbose: config['verbose'] as bool? ?? false);
  final inspector = StateInspector(client);
  final debugger = Debugger(inspector);

  final testResult = await runner.runAll(filtered);

  final debugReports = <DebugReport>[];
  for (final result in testResult.scenarios) {
    if (!result.passed) {
      final debug = await debugger.debug(result);
      debugReports.add(debug);
      print('\n${debug.formatted}');
    }
  }

  final guide = UserGuide.generate(filtered, testResult);

  final report = await ReportGenerator.generateFullReport(
    testResult: testResult,
    scenarios: filtered,
    debugReports: debugReports,
    guide: guide,
  );

  final reportPath = config['report'] as String? ?? 'schematic_report.md';
  await ReportGenerator.saveToFile(report, reportPath);

  final showGuide = ((config['guide'] as bool?) ?? false) || testResult.failed == 0;
  if (showGuide) {
    print('\n${'=' * 60}');
    print('📖 USER GUIDE');
    print('${'=' * 60}');
    print(guide);
  }

  exit(testResult.failed == 0 ? 0 : 1);
}

Map<String, dynamic> _parseArgs(List<String> args) {
  final config = <String, dynamic>{'verbose': false, 'guide': false, 'help': false, 'all': true};
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--help': case '-h': config['help'] = true; break;
      case '--verbose': case '-v': config['verbose'] = true; break;
      case '--guide': case '-g': config['guide'] = true; break;
      case '--flow': case '-f': if (i + 1 < args.length) { config['flow'] = args[++i]; config['all'] = false; } break;
      case '--report': case '-r': if (i + 1 < args.length) config['report'] = args[++i]; break;
      case '--supabase-url': if (i + 1 < args.length) config['supabase_url'] = args[++i]; break;
      case '--anon-key': if (i + 1 < args.length) config['anon_key'] = args[++i]; break;
      case '--service-key': if (i + 1 < args.length) config['service_key'] = args[++i]; break;
      case '--mgmt-token': if (i + 1 < args.length) config['mgmt_token'] = args[++i]; break;
    }
  }
  return config;
}

void _printHelp() => print('''
Usage: dart run schematic/main.dart [options]
  --all                    Run all scenarios (default)
  --flow, -f <name>        Run scenario by name filter
  --verbose, -v            Verbose output
  --guide, -g              Print user guide
  --report, -r <path>      Report path (default: schematic_report.md)
  --help, -h               Show help

Env: SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY,
     SUPABASE_ACCESS_TOKEN, SUPABASE_PROJECT_REF
''');

String _prompt(String label) {
  stdout.write('$label: ');
  return stdin.readLineSync() ?? '';
}
