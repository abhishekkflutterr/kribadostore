import 'package:meta/meta.dart';
import 'dart:convert';

class BrandPrescriptionsRequest {
    final String campId;
    final String doctorId;
    final List<Prescription> prescriptions;
    final String? remarkByDoctor; // Optional field


    BrandPrescriptionsRequest({
        required this.campId,
        required this.doctorId,
        required this.prescriptions,
        this.remarkByDoctor, // Optional parameter

    });

    factory BrandPrescriptionsRequest.fromJson(String str) => BrandPrescriptionsRequest.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory BrandPrescriptionsRequest.fromMap(Map<String, dynamic> json) => BrandPrescriptionsRequest(
        campId: json["camp_id"],
        doctorId: json["doctor_id"],
        prescriptions: List<Prescription>.from(json["prescriptions"].map((x) => Prescription.fromMap(x))),
        remarkByDoctor: json["remarks"],

    );

    Map<String, dynamic> toMap() => {
        "camp_id": campId,
        "doctor_id": doctorId,
        "prescriptions": List<dynamic>.from(prescriptions.map((x) => x.toMap())),
        if (remarkByDoctor != null) "remarks": remarkByDoctor,

    };
}

class Prescription {
    final String brand;
    final String count;

    Prescription({
        required this.brand,
        required this.count,
    });

    factory Prescription.fromJson(String str) => Prescription.fromMap(json.decode(str));

    String toJson() => json.encode(toMap());

    factory Prescription.fromMap(Map<String, dynamic> json) => Prescription(
        brand: json["brand"],
        count: json["count"],
    );

    Map<String, dynamic> toMap() => {
        "brand": brand,
        "count": count,
    };
}
