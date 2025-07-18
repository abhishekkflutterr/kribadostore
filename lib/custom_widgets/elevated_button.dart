import 'package:flutter/material.dart';
import 'package:kribadostore/constants/ColorConstants.dart';

class CustomElevatedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final bool enabled;
  final double verticalPadding;
  final double horizontalPadding;
  final Icon? icon; // Optional icon field
  final Color? backgroundColor; // Optional background color field

  CustomElevatedButton({
    required this.onPressed,
    required this.text,
    this.enabled = true,
    this.verticalPadding = 16.0,
    this.horizontalPadding = 40.0,
    this.icon, // Icon is optional, default is null
    this.backgroundColor, // Background color is optional, default is null
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor, // Use provided color or default to primary color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.symmetric(
          vertical: verticalPadding,
          horizontal: horizontalPadding,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 8), // Space between icon and text
          ],
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600, // Use the weight corresponding to SemiBold
              fontFamily: 'Quicksand-SemiBold',
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
