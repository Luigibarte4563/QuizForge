import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class NeoButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final bool fullWidth;
  final bool outlined;
  final IconData? icon;

  const NeoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color,
    this.textColor,
    this.fullWidth = true,
    this.outlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = outlined ? Colors.transparent : (color ?? AppColors.primaryBlue);
    final fgColor = outlined ? (color ?? AppColors.primaryBlue) : (textColor ?? Colors.white);

    final button = Material(
      color: bgColor,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 1.5),
            boxShadow: outlined
                ? []
                : [
                    const BoxShadow(
                      color: AppColors.shadow,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: fgColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return fullWidth
        ? button
        : IntrinsicWidth(child: button);
  }
}
