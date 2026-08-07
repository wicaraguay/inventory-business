import 'package:flutter/material.dart';

/// Lays out a set of [MetricCard]s responsively:
///  - wide screens  -> equal columns in a Row
///  - narrow screens -> a horizontal, swipeable strip (so the numbers stay big
///    and readable instead of being squeezed into tiny columns)
class MetricCardRow extends StatelessWidget {
  const MetricCardRow(this.cards, {super.key});

  final List<Widget> cards;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 640) {
          return Row(
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                if (i > 0) const SizedBox(width: 16),
                Expanded(child: cards[i]),
              ],
            ],
          );
        }
        return SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(width: 156, child: cards[i]),
          ),
        );
      },
    );
  }
}
