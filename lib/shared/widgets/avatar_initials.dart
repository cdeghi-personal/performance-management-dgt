import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AvatarInitials extends StatelessWidget {
  final String name;
  final double size;
  final Color? background;
  final double fontSize;

  const AvatarInitials({
    super.key,
    required this.name,
    this.size = 38,
    this.background,
    this.fontSize = 14,
  });

  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? AppColors.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: TextStyle(
          color: AppColors.darkGray,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
