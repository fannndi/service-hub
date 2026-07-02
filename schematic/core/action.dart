class SchematicAction {
  final String type; // invoke | query | rpc | auth_login | wait
  final String target;
  final Map<String, dynamic>? body;
  final String? asRole;

  const SchematicAction({
    required this.type,
    required this.target,
    this.body,
    this.asRole,
  });

  factory SchematicAction.fromYaml(Map<String, dynamic> yaml) {
    return SchematicAction(
      type: yaml['type'] as String? ?? 'invoke',
      target: yaml['target'] as String? ?? '',
      body: yaml['body'] as Map<String, dynamic>?,
      asRole: yaml['asRole'] as String?,
    );
  }

  Map<String, dynamic> resolve(Map<String, String> vars) {
    if (body == null) return const {};
    return _resolveVars(body!, vars);
  }

  String resolveTarget(Map<String, String> vars) {
    var t = target;
    for (final e in vars.entries) {
      t = t.replaceAll('{${e.key}}', e.value);
    }
    return t;
  }

  static Map<String, dynamic> _resolveVars(Map<String, dynamic> map, Map<String, String> vars) {
    final result = <String, dynamic>{};
    for (final e in map.entries) {
      if (e.value is String) {
        var v = e.value as String;
        for (final ve in vars.entries) {
          v = v.replaceAll('{${ve.key}}', ve.value);
        }
        result[e.key] = v;
      } else if (e.value is Map<String, dynamic>) {
        result[e.key] = _resolveVars(e.value as Map<String, dynamic>, vars);
      } else if (e.value is List) {
        result[e.key] = (e.value as List).map((item) {
          if (item is Map<String, dynamic>) return _resolveVars(item, vars);
          if (item is String) {
            var v = item;
            for (final ve in vars.entries) {
              v = v.replaceAll('{${ve.key}}', ve.value);
            }
            return v;
          }
          return item;
        }).toList();
      } else {
        result[e.key] = e.value;
      }
    }
    return result;
  }
}
