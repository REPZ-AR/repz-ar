import 'package:flutter/material.dart';

import '../../config/app_colors.dart';

class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.text,
    required this.backgroundColor,
    this.textColor = AppColors.black,
    this.onPressed,
    this.isLoading = false,
    this.showLoadingIndicator = true,
    this.height = 54,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;
  final bool showLoadingIndicator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          minimumSize: Size.fromHeight(height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          elevation: 0,
        ),
        child:
            isLoading && showLoadingIndicator
                ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: textColor,
                  ),
                )
                : Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 1,
                    color: textColor,
                  ),
                ),
      ),
    );
  }
}
