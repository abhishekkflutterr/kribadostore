class Buttons {
  final String print_btn;
  final String download_btn;
  final String print_download_btn;

  Buttons({required this.print_btn, required this.download_btn,required this.print_download_btn});

  // Convert a Buttons object to a map
  Map<String, dynamic> toMap() {
    return {
      'print_btn': print_btn,
      'download_btn': download_btn,
      'print_download_btn': print_download_btn,
    };
  }

  // Factory constructor to create a Buttons object from a map
  factory Buttons.fromJson(Map<String, dynamic> json) {
    return Buttons(
      print_btn: json['print_btn'],
      download_btn: json['download_btn'],
      print_download_btn: json['print_download_btn'],
    );
  }
}
