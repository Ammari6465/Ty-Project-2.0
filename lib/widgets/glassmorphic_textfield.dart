import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

// Modern Glassmorphic Text Field
class GlassmorphicTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final IconData? prefixIcon;
  final int maxLines;
  final Color labelColor;

  const GlassmorphicTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.prefixIcon,
    this.maxLines = 1,
    this.labelColor = AppTheme.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.lightBrand,
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                obscureText: obscureText,
                maxLines: maxLines,
                style: const TextStyle(color: AppTheme.textDark),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: const TextStyle(color: AppTheme.textLight),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.primaryBrand) : null,
                  suffixIcon: suffixIcon,
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.85),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
