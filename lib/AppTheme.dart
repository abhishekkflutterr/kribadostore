class AppTheme {
  final String theme_color;
  final String text_color;

  AppTheme({required this.theme_color, required this.text_color});

  // Convert a AppTheme object to a map
  Map<String, dynamic> toMap() {
    return {
      'theme_color': theme_color,
      'text_color': text_color,
    };
  }

  // Factory constructor to create a AppTheme object from a map
  factory AppTheme.fromJson(Map<String, dynamic> json) {
    return AppTheme(
      theme_color: json['theme_color'],
      text_color: json['text_color'],
    );
  }
}
