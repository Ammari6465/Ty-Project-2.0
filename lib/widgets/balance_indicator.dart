import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BalanceIndicator extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;
  final IconData icon;
  final double? size;

  const BalanceIndicator({
    super.key,
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double baseSize;
        if (size != null) {
          baseSize = size!;
        } else if (constraints.maxWidth.isFinite) {
          baseSize = constraints.maxWidth.clamp(80.0, 120.0);
        } else {
          baseSize = 100.0;
        }
        final iconSize = (baseSize * 0.32).clamp(22.0, 36.0);
        final labelSize = (baseSize * 0.11).clamp(9.0, 12.0);
        final amountSize = (baseSize * 0.2).clamp(16.0, 22.0);

        return Column(
          children: [
            Container(
              width: baseSize,
              height: baseSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.3), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: iconSize),
                  SizedBox(height: baseSize * 0.04),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: labelSize,
                      fontWeight: FontWeight.w500,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: baseSize * 0.12),
            Text(
              amount,
              style: TextStyle(
                fontSize: amountSize,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ],
        );
      },
    );
  }
}
