import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final String text;
  final Color? color;

  const GradientButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDisabled
              ? [AppTheme.surfaceVariant, AppTheme.surfaceVariant]
              : [AppTheme.primary, AppTheme.primaryDark],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: isDisabled
            ? []
            : [
                BoxShadow(color: Colors.white.withOpacity(0.15), blurRadius: 20, spreadRadius: 0, offset: const Offset(0, 6)),
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 2)),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                : Text(
                    text,
                    style: TextStyle(
                      color: isDisabled ? AppTheme.textHint : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
