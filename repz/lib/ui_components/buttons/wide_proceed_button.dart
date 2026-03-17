import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class WideProceedButton extends StatelessWidget {
  const WideProceedButton({
    super.key,
    required this.onPressed,
    this.leftWidget,
    this.text = 'Continue',
    this.height = 58,
    this.backgroundColor = AppColors.white,
    this.textColor = AppColors.black,
    this.arrowBackgroundColor = AppColors.accent,
    this.arrowIconColor = AppColors.black,
    this.arrowIcon = Icons.arrow_forward,
    this.horizontalPadding = const EdgeInsets.symmetric(horizontal: 14),
  });

  final VoidCallback onPressed;
  final Widget? leftWidget;
  final String text;
  final double height;
  final Color backgroundColor;
  final Color textColor;
  final Color arrowBackgroundColor;
  final Color arrowIconColor;
  final IconData arrowIcon;
  final EdgeInsetsGeometry horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Padding(
            padding: horizontalPadding,
            child: Row(
              children: [
                leftWidget ?? const SizedBox(width: 40, height: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: arrowBackgroundColor,
                  ),
                  child: Icon(
                    arrowIcon,
                    color: arrowIconColor,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

