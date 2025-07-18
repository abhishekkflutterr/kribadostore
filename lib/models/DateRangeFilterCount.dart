import 'dart:convert';


class DateRangeFilterCount {
  final DateTime fromDate;
  final DateTime toDate;
  final String? scaleId; // Make scaleId optional


  DateRangeFilterCount({
    required this.fromDate,
    required this.toDate,
    this.scaleId, // Make scaleId optional in constructor
  });


  factory DateRangeFilterCount.fromJson(String str) => DateRangeFilterCount.fromMap(json.decode(str));


  String toJson() => json.encode(toMap());


  factory DateRangeFilterCount.fromMap(Map<String, dynamic> json) => DateRangeFilterCount(
    fromDate: DateTime.parse(json["from_date"]),
    toDate: DateTime.parse(json["to_date"]),
    scaleId: json["scale_id"]?.toString(), // Use `?.toString()` to handle null
  );


  Map<String, dynamic> toMap() => {
    "from_date": fromDate.toIso8601String().split('T').first,
    "to_date": toDate.toIso8601String().split('T').first,
    "scale_id": scaleId, // Allow null value
  };
}
