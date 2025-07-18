import 'package:flutter/material.dart';

class ScoreWidget extends StatelessWidget {
  final String score;

  const ScoreWidget({Key? key, required this.score}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double fontSize = score.length >= 5 ? 20 : 34; // Adjust font size based on score length
    double innerCircleSize = score.length > 2 ? 100 : 80; // Adjust inner circle size based on score length
    double middleCircleSize = score.length > 2 ? 130 : 110; // Adjust middle circle size based on score length
    double outerCircleSize = score.length > 2 ? 160 : 140; // Adjust outer circle size based on score length

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Outer Circle 1
          Container(
            width: outerCircleSize,
            height: outerCircleSize,
            decoration: BoxDecoration(
              color: Colors.blue.shade100, // Adjust color as needed
              shape: BoxShape.circle,
            ),
            child: Center(
              // Outer Circle 2
              child: Container(
                width: middleCircleSize,
                height: middleCircleSize,
                decoration: BoxDecoration(
                  color: Colors.blue.shade200, // Adjust color as needed
                  shape: BoxShape.circle,
                ),
                child: Center(
                  // Inner Circle (with score)
                  child: Container(
                    width: innerCircleSize,
                    height: innerCircleSize,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade400, // Adjust color as needed
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0), // Adjust padding as needed
                        child: Text(
                          '$score',
                          style: TextStyle(
                            fontSize: fontSize,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 20),
          // Description Text
        ],
      ),
    );
  }
}
