import 'package:flutter/material.dart';
import 'package:kribadostore/constants/ColorConstants.dart';

class CustomElevatedButton1 extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final bool enabled;

  CustomElevatedButton1({
    required this.onPressed,
    required this.text,
    this.enabled = true, // Making enabled optional with a default value of true
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).primaryColor,
        backgroundColor: Theme.of(context).textTheme.bodyMedium?.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
