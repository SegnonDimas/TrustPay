import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppButton extends StatefulWidget {
  Function()? onTap;
  Color backgroundColor;
  Color foregroundColor;
  double? width;
  double? height;
  Widget? child;
   AppButton({super.key,
   this.onTap,
   this.backgroundColor = AppColors.primary,
   this.foregroundColor = Colors.white,
     this.width,
   this.height,
   this.child,
   });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,

      child: Container(
        alignment: Alignment.center,
        width: widget.width ?? double.infinity,
        height: widget.height!=null? widget.height : (Platform.isAndroid || Platform.isIOS)? MediaQuery.of(context).size.height * 0.06 : MediaQuery.of(context).size.height * 0.08,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration:

        BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: widget.child),
      );
  }
}