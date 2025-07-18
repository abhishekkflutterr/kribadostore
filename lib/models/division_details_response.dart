class DivisionDetailsResponse {
  late String status;
  late String message;
  late DivisionDetailsData data;


  DivisionDetailsResponse(
      {required this.status, required this.message, required this.data});


  factory DivisionDetailsResponse.fromJson(Map<String, dynamic> json) {
    return DivisionDetailsResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: DivisionDetailsData.fromJson(json['data'] ?? {}),
    );
  }
}


// division_details_data.dart
class DivisionDetailsData {
  late Division division;
  late List<Meta> meta;
  late SubscriptionPlan subscriptionPlan;
  late List<Scales> scales;
  late List<Brands> brands;


  DivisionDetailsData(
      {required this.division,
        required this.meta,
        required this.subscriptionPlan,
        required this.scales,
        required this.brands});


  factory DivisionDetailsData.fromJson(Map<String, dynamic> json) {
    return DivisionDetailsData(
      division: Division.fromJson(json['division'] ?? {}),
      meta: (json['meta'] as List?)
          ?.map((item) => Meta.fromJson(item ?? {}))
          .toList() ??
          [],
      subscriptionPlan:
      SubscriptionPlan.fromJson(json['subscription_plan'] ?? {}),
      scales: (json['scales'] as List?)
          ?.map((item) => Scales.fromJson(item ?? {}))
          .toList() ??
          [],
      brands: (json['brands'] as List?)
          ?.map((item) => Brands.fromJson(item ?? {}))
          .toList() ??
          [],
    );
  }
}


// division.dart
class Division {
  late String id;
  late String name;
  late int companyId;


  Division({required this.id, required this.name, required this.companyId});


  factory Division.fromJson(Map<String, dynamic> json) {
    return Division(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      companyId: json['company_id'] ?? 0,
    );
  }
}


// meta.dart
class Meta {
  late String key;
  late String value;


  Meta({required this.key, required this.value});


  factory Meta.fromJson(Map<String, dynamic> json) {
    return Meta(
      key: json['key'] ?? '',
      value: json['value'] ?? '',
    );
  }
}


// subscription_plan.dart
class SubscriptionPlan {
  late String id;
  late String planName;


  SubscriptionPlan({required this.id, required this.planName});


  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] ?? '',
      planName: json['plan_name'] ?? '',
    );
  }
}


class Scales {
  final String name;
  final String displayName;
  final String s3Url;
  final String? b64data; // Nullable field to store the base64 data
  final Map<String, dynamic>?
  scaleJson; // New field to store the entire scale_json


  Scales({
    required this.name,
    required this.displayName,
    required this.s3Url,
    this.b64data, // This is now optional
    this.scaleJson, // New optional field
  });


  factory Scales.fromJson(Map<String, dynamic> json) {
    final scaleJson = json['scale_json'] as Map<String, dynamic>?;
    String? b64data;
    if (scaleJson != null && scaleJson['b64data'] != null) {
      b64data = scaleJson['b64data'] is String
          ? scaleJson['b64data'] as String
          : scaleJson['b64data'].toString();
    }
    return Scales(
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? '',
      s3Url: json['s3_url'] ?? '',
      b64data: b64data,
      scaleJson: scaleJson,
    );
  }
}


class Brands {
  final String id;
  final String name;


  Brands({
    required this.id,
    required this.name,
  });


  factory Brands.fromJson(Map<String, dynamic> json) {
    return Brands(id: json['id'] ?? '', name: json['name'] ?? '');
  }
}





