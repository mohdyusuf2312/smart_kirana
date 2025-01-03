import 'package:flutter/material.dart';
import 'package:smart_kirana/utils/constants.dart';

enum ButtonType { primary, secondary, outline, text }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonType type;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double height;
  final IconData? icon;
  final bool iconLeading;
  final bool enabled;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.width,
    this.height = 50.0,
    this.icon,
    this.iconLeading = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height,
      child: _buildButton(),
    );
  }

  Widget _buildButton() {
    switch (type) {
      case ButtonType.primary:
        return ElevatedButton(
          onPressed: isLoading || !enabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                enabled ? AppColors.primary : AppColors.primary.withAlpha(128),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            elevation: 0,
          ),
          child: _buildButtonContent(),
        );
      case ButtonType.secondary:
        return ElevatedButton(
          onPressed: isLoading || !enabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                enabled
                    ? AppColors.secondary
                    : AppColors.secondary.withAlpha(128),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
            elevation: 0,
          ),
          child: _buildButtonContent(),
        );
      case ButtonType.outline:
        return OutlinedButton(
          onPressed: isLoading || !enabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor:
                enabled ? AppColors.primary : AppColors.primary.withAlpha(128),
            side: BorderSide(
              color:
                  enabled
                      ? AppColors.primary
                      : AppColors.primary.withAlpha(128),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
          ),
          child: _buildButtonContent(),
        );
      case ButtonType.text:
        return TextButton(
          onPressed: isLoading || !enabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor:
                enabled ? AppColors.primary : AppColors.primary.withAlpha(128),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppBorderRadius.medium),
            ),
          ),
          child: _buildButtonContent(),
        );
    }
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (iconLeading) ...[
            Icon(icon, size: 20),
            const SizedBox(width: AppPadding.small),
          ],
          Text(text, style: AppTextStyles.button),
          if (!iconLeading) ...[
            const SizedBox(width: AppPadding.small),
            Icon(icon, size: 20),
          ],
        ],
      );
    }

    return Text(text, style: AppTextStyles.button);
  }
}
