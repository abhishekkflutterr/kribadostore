class FilterByDateCountResponse {
  final Data data;

  FilterByDateCountResponse({required this.data});

  factory FilterByDateCountResponse.fromJson(Map<String, dynamic> json) {
    return FilterByDateCountResponse(
      data: Data.fromJson(json['data']),
    );
  }
}

class Data {
  final int patCount;
  final int campCount;
  final int prescriptionCount;
  final bool showPres;
  final PrescriptionTotalCounts prescriptionTotalCounts;

  Data({
    required this.patCount,
    required this.campCount,
    required this.prescriptionCount,
    required this.prescriptionTotalCounts,
    required this.showPres,
  });

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
      patCount: json['pat_count'],
      campCount: json['camp_count'],
      prescriptionCount: json['prescription_count'],
      showPres: json['show_prescription'],
      prescriptionTotalCounts: PrescriptionTotalCounts.fromJson(json['prescription_total_counts']),
    );
  }
}

class PrescriptionTotalCounts {
  final Map<String, int> brands;
  final int total;

  PrescriptionTotalCounts({required this.brands, required this.total});

  factory PrescriptionTotalCounts.fromJson(Map<String, dynamic> json) {
    return PrescriptionTotalCounts(
      brands: Map<String, int>.from(json['brands']),
      total: json['total'],
    );
  }
}
