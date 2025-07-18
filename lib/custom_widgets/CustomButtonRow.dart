import 'package:flutter/material.dart';

class CustomButtonRow extends StatelessWidget {
  final List<String> buttonLabels = ['New Patient', 'Print', 'Download', 'End Camp'];
  final List<VoidCallback> buttonActions;
  final List<String> buttonVisibility;
  final List<Color> buttonColors;
  final List<IconData> buttonIcons = [
    Icons.person_add_alt, // Icon for 'New Patient'
    Icons.print_outlined, // Icon for 'Print'
    Icons.file_download_outlined, // Icon for 'Download'
    Icons.stop_circle_outlined, // Icon for 'End Camp'
  ];

  CustomButtonRow({
    required this.buttonVisibility,
    required this.buttonActions,
    required this.buttonColors,
  })  : assert(buttonVisibility.length == 4),
        assert(buttonActions.length == 4),
        assert(buttonColors.length == 4);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _buildButtons(context),
    );
  }

  List<Widget> _buildButtons(BuildContext context) {
    List<Widget> buttons = [];
    for (int i = 0; i < buttonLabels.length; i++) {
      if (buttonVisibility[i] == "true") {
        buttons.add(
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 10.0), // Adjust vertical margin only

            width: double.infinity, // Match width of the parent container
            child: ElevatedButton.icon( // Use ElevatedButton.icon for an icon and label
              onPressed: buttonActions[i],
              icon: Icon(buttonIcons[i], size: 24), // Icon before the text
              label: Text(
                buttonLabels[i],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Theme.of(context).textTheme.bodyMedium?.color,
                backgroundColor: buttonLabels[i] == 'End Camp' ? Colors.red : buttonColors[i],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        );
      }
    }
    return buttons;
  }
}
