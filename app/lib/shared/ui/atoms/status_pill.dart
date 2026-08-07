import 'package:flutter/material.dart';
import 'package:inventy_app/shared/theme/app_colors.dart';

enum StockStatus { inStock, low, out }

/// Atom: a rounded status badge (En stock / Stock bajo / Sin stock).
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final StockStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (status) {
      StockStatus.inStock => ('En stock', AppColors.success, AppColors.successBg),
      StockStatus.low => ('Stock bajo', AppColors.warning, AppColors.warningBg),
      StockStatus.out => ('Sin stock', AppColors.danger, AppColors.dangerBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
