import 'package:meta/meta.dart';
import 'dart:convert';

class CheckPassword {
    String status;
    String message;
    int hasPassword;

    CheckPassword({
        required this.status,
        required this.message,
        required this.hasPassword,
    });

    factory CheckPassword.fromRawJson(String str) => CheckPassword.fromJson(json.decode(str));

    String toRawJson() => json.encode(toJson());

    factory CheckPassword.fromJson(Map<String, dynamic> json) => CheckPassword(
        status: json["status"],
        message: json["message"],
        hasPassword: json["has_password"],
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "has_password": hasPassword,
    };
}
