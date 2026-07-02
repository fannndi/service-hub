class AssertionResult {
  final bool passed;
  final String message;

  const AssertionResult({required this.passed, required this.message});
}

class Assertion {
  final String type; // equals | contains | notNull | gt | lt | length_gt
  final String path;
  final dynamic expected;

  const Assertion({
    required this.type,
    required this.path,
    this.expected,
  });

  factory Assertion.fromYaml(Map<String, dynamic> yaml) {
    return Assertion(
      type: yaml['type'] as String? ?? 'equals',
      path: yaml['path'] as String? ?? '',
      expected: yaml['expected'],
    );
  }

  AssertionResult evaluate(Map<String, dynamic> response) {
    final actual = _getValue(response, path);
    switch (type) {
      case 'equals':
        final pass = actual == expected;
        return AssertionResult(
          passed: pass,
          message: pass
              ? '$path = $expected ✓'
              : '$path: expected "$expected", got "$actual"',
        );
      case 'notNull':
        final pass = actual != null;
        return AssertionResult(
          passed: pass,
          message: pass ? '$path is present ✓' : '$path is null ✗',
        );
      case 'contains':
        final pass = actual is String && actual.toString().contains(expected.toString());
        return AssertionResult(
          passed: pass,
          message: pass
              ? '$path contains "$expected" ✓'
              : '$path does not contain "$expected"',
        );
      case 'gt':
        final pass = (actual is num) && (expected is num) && actual > expected;
        return AssertionResult(
          passed: pass,
          message: pass
              ? '$path ($actual) > $expected ✓'
              : '$path ($actual) is not > $expected',
        );
      case 'length_gt':
        final list = actual is List ? actual : null;
        final pass = list != null && list.length > (expected as int? ?? 0);
        return AssertionResult(
          passed: pass,
          message: pass
              ? '$path length (${list.length}) > $expected ✓'
              : '$path length is not > $expected',
        );
      default:
        return AssertionResult(passed: false, message: 'Unknown assertion type: $type');
    }
  }

  static dynamic _getValue(Map<String, dynamic> data, String path) {
    if (path.isEmpty) return data;
    final parts = path.split('.');
    dynamic current = data;
    for (final part in parts) {
      if (current is Map) {
        if (part.startsWith('[') && part.endsWith(']')) {
          final idx = int.tryParse(part.substring(1, part.length - 1));
          if (idx != null && current is List && idx < current.length) {
            current = current[idx];
          } else {
            return null;
          }
        } else {
          current = current[part];
        }
      } else if (current is List) {
        final idx = int.tryParse(part);
        if (idx != null && idx < current.length) {
          current = current[idx];
        } else {
          return null;
        }
      } else {
        return null;
      }
    }
    return current;
  }
}
