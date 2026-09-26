import 'package:flutter/material.dart';

class LessonBoxWidget extends StatelessWidget {
  final int number;
  final String title;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final Color numberColor;
  final Color numberBackgroundColor;
  final double width;
  final double scale;

  const LessonBoxWidget({
    super.key,
    required this.number,
    required this.title,
    this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.numberColor,
    required this.numberBackgroundColor,
    this.width = 150,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Lección $number: $title',
      hint: 'Toca para abrir',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          constraints: BoxConstraints(minHeight: 60 * scale),
          padding: EdgeInsets.symmetric(
            horizontal: 14 * scale,
            vertical: 12 * scale,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E88E5).withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36 * scale,
                height: 36 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: numberBackgroundColor,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 16 * scale,
                      fontWeight: FontWeight.bold,
                      color: numberColor,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10 * scale),
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 14 * scale,
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
