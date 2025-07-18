import 'dart:convert';

class ExecuteCamp {
  final String doctorId;
  final DateTime planDate;
  final String camp_id;

  ExecuteCamp({
    required this.doctorId,
    required this.planDate,
    required this.camp_id,
  });

  factory ExecuteCamp.fromJson(String str) => ExecuteCamp.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory ExecuteCamp.fromMap(Map<String, dynamic> json) => ExecuteCamp(
    doctorId: json["doctor_id"],
    planDate: DateTime.parse(json["plan_date"]),
    camp_id: json["camp_id"],
  );

  Map<String, dynamic> toMap() => {
    "doctor_id": doctorId,
    "plan_date": planDate.toIso8601String().split('T').first,
    "camp_id": camp_id,
  };
}
