class MetaDetails {
  final String qr_url;
  final String qr_label;

  MetaDetails({required this.qr_url, required this.qr_label});

  // Convert a MetaDetails object to a map
  Map<String, dynamic> toMap() {
    return {
      'qr_url': qr_url,
      'qr_label': qr_label,
    };
  }

  // Factory constructor to create a MetaDetails object from a map
  factory MetaDetails.fromJson(Map<String, dynamic> json) {
    return MetaDetails(
      qr_url: json['qr_url'],
      qr_label: json['qr_label'],
    );
  }
}
