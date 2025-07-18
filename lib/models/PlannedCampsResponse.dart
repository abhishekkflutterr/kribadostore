class PlannedCampsResponse {
  final String status;
  final String message;
  final List<PlannedCamps> data; // Change this to a list

  PlannedCampsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory PlannedCampsResponse.fromJson(Map<String, dynamic> json) {
    return PlannedCampsResponse(
      status: json['status'],
      message: json['message'],
      data: List<PlannedCamps>.from(json['data'].map((item) => PlannedCamps.fromJson(item))),  // Convert the JSON array into a list of PlannedCamps objects
    );
  }
}

class PlannedCamps {
  final String doctorName;
  final String doctorCode;
  final String date;
  final String prescriberType;
  final String id;
  final String status;

  PlannedCamps({
    required this.doctorName,
    required this.doctorCode,
    required this.date,
    required this.prescriberType,
    required this.id,
    required this.status,
  });

  factory PlannedCamps.fromJson(Map<String, dynamic> json) {
    return PlannedCamps(
      doctorName: json['doctor_name'],
      doctorCode: json['doctor_code'],
      date: json['date'],
      prescriberType: json['prescriber_type'],
      id: json['id'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'doctor_name': doctorName,
      'doctor_code': doctorCode,
      'date': date,
      'prescriber_type': prescriberType,
      'id': id,
      'status': status,
    };
  }
}
