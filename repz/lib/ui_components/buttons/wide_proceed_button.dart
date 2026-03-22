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
    this.arrowIcon = Icons.arrow_forward_rounded,
    this.arrowIconSize = 20,
    this.horizontalPadding = const EdgeInsets.symmetric(horizontal: 14),
    this.enabled = true,
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
  final double arrowIconSize;
  final EdgeInsetsGeometry horizontalPadding;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = enabled ? backgroundColor : backgroundColor.withValues(alpha: 0.6);
    final effectiveTextColor = enabled ? textColor : textColor.withValues(alpha: 0.5);
    final effectiveArrowBgColor = enabled ? arrowBackgroundColor : arrowBackgroundColor.withValues(alpha: 0.5);
    final effectiveArrowIconColor = enabled ? arrowIconColor : arrowIconColor.withValues(alpha: 0.5);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(999)
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: enabled ? onPressed : null,
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
                      color: effectiveTextColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: effectiveArrowBgColor,
                  ),
                  child: Icon(
                    arrowIcon,
                    color: effectiveArrowIconColor,
                    size: arrowIconSize,
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

