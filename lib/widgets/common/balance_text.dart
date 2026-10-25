import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'app_scope.dart';

class BalanceText extends StatelessWidget {
  const BalanceText({
    super.key,
    required this.net,
    this.style,
    this.showLabel = true,
    this.labelForYou = false,
    this.alignStart = false,
  });

  final int net;
  final TextStyle? style;
  final bool showLabel;
  final bool labelForYou;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final colors = AppColors.of(context);
    final color = net > 0
        ? colors.positive
        : net < 0
        ? colors.negative
        : colors.muted;
    final icon = net > 0
        ? Icons.south_west
        : net < 0
        ? Icons.north_east
        : Icons.check;
    final label = net > 0
        ? (labelForYou ? s.owedToYou : s.isOwed)
        : net < 0
        ? (labelForYou ? s.youOwe : s.owes)
        : (labelForYou ? s.settledUp : s.even);
    final base = style ?? Theme.of(context).textTheme.titleSmall;

    return Column(
      crossAxisAlignment: alignStart
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: (base?.fontSize ?? 14) + 2, color: color),
            const SizedBox(width: 2),
            Text(
              s.money(net.abs()),
              style: base?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        if (showLabel)
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color),
          ),
      ],
    );
  }
}
