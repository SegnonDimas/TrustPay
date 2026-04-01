import 'package:flutter/material.dart';

class AppText extends StatefulWidget {
  String text;
  Color? color;
  double? fontSize;
  FontWeight? fontWeight;

  AppText(this.text,{super.key, this.color, this.fontSize, this.fontWeight});

  @override
  State<AppText> createState() => _AppTextState();
}

class _AppTextState extends State<AppText> {
  @override
  Widget build(BuildContext context) {
    return Text(
      widget.text,
      style:  TextStyle(
        fontSize: widget.fontSize ?? 14,
        fontWeight: widget.fontWeight ?? FontWeight.normal,
      color: widget.color
      ),
    );
  }
}