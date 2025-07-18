import 'package:flutter/material.dart';

class CustomTextBox extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // Nullable callback
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  CustomTextBox({
    required this.text,
    this.onPressed, // Optional callback
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.grey,
    this.textColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed != null ? () => onPressed!() : null,
      child: Container(
        padding: EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 10.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: borderColor, width: 0.4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontFamily: 'Quicksand-SemiBold',
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
