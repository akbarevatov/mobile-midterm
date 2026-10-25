import 'package:flutter/material.dart';

import '../../models/household_member.dart';
import '../../theme/app_colors.dart';

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.member, this.radius = 18});

  final HouseholdMember? member;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final m = member;
    final color = m == null
        ? Theme.of(context).colorScheme.outline
        : AppColors.member(m.colorIndex);
    return Semantics(
      label: m?.displayName,
      excludeSemantics: true,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: m != null && !m.isActive
            ? color.withValues(alpha: 0.4)
            : color,
        child: Text(
          m?.initials ?? '?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: radius * 0.8,
          ),
        ),
      ),
    );
  }
}
