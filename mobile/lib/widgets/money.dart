import 'package:flutter/material.dart';

import '../utils/money.dart';

class Money extends StatelessWidget {
  const Money({
    super.key,
    required this.cents,
    this.currency = 'USD',
    this.style,
  });

  final int cents;
  final String currency;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatCents(cents, currency),
      style: style,
    );
  }
}
