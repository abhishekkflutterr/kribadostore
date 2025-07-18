import 'dart:convert';

class CampPlanList {
  final String prescriberType;
  final DateTime from_date;
  final DateTime to_date;

  CampPlanList({
    required this.from_date,
    required this.to_date,
    required this.prescriberType,

  });

  factory CampPlanList.fromJson(String str) => CampPlanList.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory CampPlanList.fromMap(Map<String, dynamic> json) => CampPlanList(
    from_date: DateTime.parse(json["from_date"]),
    to_date: DateTime.parse(json["to_date"]),
    prescriberType: json["status"],

  );

  Map<String, dynamic> toMap() => {
    "from_date": from_date.toIso8601String().split('T').first,
    "to_date": to_date.toIso8601String().split('T').first,
    "status": prescriberType,

  };
}
