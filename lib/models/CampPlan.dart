import 'dart:convert';

class CampPlan {
  final String doctorId;
  final String prescriberType;
  final DateTime planDate;

  CampPlan({
    required this.doctorId,
    required this.prescriberType,
    required this.planDate,
  });

  factory CampPlan.fromJson(String str) => CampPlan.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CampPlan.fromMap(Map<String, dynamic> json) => CampPlan(
    doctorId: json["doctor_id"],
    prescriberType: json["prescriber_type"],
    planDate: DateTime.parse(json["plan_date"]),
  );

  Map<String, dynamic> toMap() => {
    "doctor_id": doctorId,
    "prescriber_type": prescriberType,
    "plan_date": planDate.toIso8601String().split('T').first,
  };
}
