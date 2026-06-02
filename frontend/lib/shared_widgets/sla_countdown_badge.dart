import 'package:flutter/material.dart';

import '../shared_widgets/status_badge.dart';

class SlaCountdownBadge extends StatelessWidget {
  const SlaCountdownBadge({super.key, required this.hoursLeft});

  final int hoursLeft;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(label: 'SLA ${hoursLeft}j', isDanger: hoursLeft < 6);
  }
}
