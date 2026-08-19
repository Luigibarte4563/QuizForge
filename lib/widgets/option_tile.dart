import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool showResult;
  final VoidCallback onTap;
  final int index;

  const OptionTile({
    super.key,
    required this.label,
    required this.text,
    required this.isSelected,
    this.isCorrect = false,
    this.showResult = false,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.cardBg;
    Color fgColor = AppColors.textPrimary;
    Color borderColor = AppColors.border;
    FontWeight fontWeight = FontWeight.w500;

    if (showResult) {
      if (isCorrect) {
        bgColor = AppColors.success;
        fgColor = Colors.white;
        fontWeight = FontWeight.w700;
      } else if (isSelected && !isCorrect) {
        bgColor = AppColors.error;
        fgColor = Colors.white;
        fontWeight = FontWeight.w700;
      }
    } else if (isSelected) {
      bgColor = AppColors.primaryBlue;
      fgColor = Colors.white;
      fontWeight = FontWeight.w700;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: fgColor, width: 1.5),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: fgColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: fgColor,
                  fontSize: 15,
                  fontWeight: fontWeight,
                ),
              ),
            ),
            if (showResult && isCorrect)
              Icon(Icons.check_circle, color: fgColor, size: 22),
            if (showResult && isSelected && !isCorrect)
              Icon(Icons.cancel, color: fgColor, size: 22),
          ],
        ),
      ),
    );
  }
}
