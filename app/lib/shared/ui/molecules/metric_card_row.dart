import 'package:flutter/material.dart';

/// One-shot fade + upward slide entrance animation for a single card.
///
/// Uses [AnimationController.forward()] — the animation runs ONCE and stops.
/// This keeps [tester.pumpAndSettle()] from hanging in widget tests.
class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({
    required this.child,
    required this.index,
  });

  final Widget child;

  /// Card position (0-based). Each card starts [index] × 65 ms later.
  final int index;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08), // ~12 px upward in fractional units
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // Stagger: delay each card by index × 65 ms, then forward() once.
    final delay = Duration(milliseconds: widget.index * 65);
    if (delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Lays out a set of [MetricCard]s responsively:
///  - wide screens  -> equal columns in a Row
///  - narrow screens -> a horizontal, swipeable strip (so the numbers stay big
///    and readable instead of being squeezed into tiny columns)
///
/// Each card has a one-shot fade + slide-up entrance animation (staggered by
/// index). The animation is finite and does not repeat, so it does not
/// interfere with [tester.pumpAndSettle()] in widget tests.
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
                Expanded(child: _FadeSlideIn(index: i, child: cards[i])),
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
            itemBuilder: (_, i) => SizedBox(
              width: 156,
              child: _FadeSlideIn(index: i, child: cards[i]),
            ),
          ),
        );
      },
    );
  }
}
