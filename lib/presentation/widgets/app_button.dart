import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final double? width;
  final double? height;
  final Widget? child;

  const AppButton({
    super.key,
    this.onTap,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = Colors.white,
    this.width,
    this.height,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedHeight = height ??
        ((Platform.isAndroid || Platform.isIOS)
            ? MediaQuery.of(context).size.height * 0.06
            : MediaQuery.of(context).size.height * 0.08);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        width: width ?? double.infinity,
        height: resolvedHeight,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: foregroundColor),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
