class LoginResponse {
  String status;
  String message;
  LoginData data;

  LoginResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: LoginData.fromJson(json['data'] ?? {}),
    );
  }
}

class LoginData {
  String token;
  String tokenType;
  int expiresIn;
  User user;
  AwsCreds awsCreds;
  Doctors doctors;
  AppVersion appVersion; // Use the AppVersion class

  LoginData({
    required this.token,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
    required this.awsCreds,
    required this.doctors,
    required this.appVersion, // Update the constructor
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      token: json['token'] ?? '',
      tokenType: json['token_type'] ?? '',
      expiresIn: json['expires_in'] ?? 0,
      user: User.fromJson(json['user'] ?? {}),
      awsCreds: AwsCreds.fromJson(json['aws_creds'] ?? {}),
      doctors: Doctors.fromJson(json['doctors'] ?? {}),
      appVersion: AppVersion.fromJson(json['app_version'] ?? {}), // Use the AppVersion class
    );
  }
}



class AppVersion {
  String version;
  String buildNumber;
  String releaseDate;

  AppVersion({
    required this.version,
    required this.buildNumber,
    required this.releaseDate,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      version: json['version'] ?? '',
      buildNumber: json['build_number'] ?? '',
      releaseDate: json['release_date'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'build_number': buildNumber,
      'release_date': releaseDate,
    };
  }
}


class User {
  String id;
  String name;
  String email;
  String? profilePhotoPath;
  String? emailVerifiedAt;
  String username;
  String? avatar;
  String mobileNumber;
  String designation;
  String empCode;
  String area;
  String hq;
  String region;
  String zone;
  int status;
  String? manager;
  String createdAt;
  String updatedAt;
  String? lastLoginAt;
  String? lastLoginIp;
  String role;
  int mrId;
  List<Division> divisions;
  List<Role> roles;
  List<Doctors> doctors;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhotoPath,
    this.emailVerifiedAt,
    required this.username,
    this.avatar,
    required this.mobileNumber,
    required this.designation,
    required this.empCode,
    required this.area,
    required this.hq,
    required this.region,
    required this.zone,
    required this.status,
    this.manager,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.lastLoginIp,
    required this.role,
    required this.mrId,
    required this.divisions,
    required this.roles,
    required this.doctors,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    List<Division> divisionsList = (json['divisions'] as List?)
        ?.map((division) => Division.fromJson(division ?? {}))
        .toList() ??
        [];
    List<Role> rolesList = (json['roles'] as List?)
        ?.map((role) => Role.fromJson(role ?? {}))
        .toList() ??
        [];

    List<Doctors> docList = (json['doctors'] as List?)
        ?.map((doctors) => Doctors.fromJson(doctors ?? {}))
        .toList() ??
        [];

    return User(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        profilePhotoPath: json['profile_photo_path'],
        emailVerifiedAt: json['email_verified_at'],
        username: json['username'] ?? '',
        avatar: json['avatar'],
        mobileNumber: json['mobile_number'] ?? '',
        designation: json['designation'] ?? '',
        empCode: json['emp_code'] ?? '',
        area: json['area'] ?? '',
        hq: json['hq'] ?? '',
        region: json['region'] ?? '',
        zone: json['zone'] ?? '',
        status: json['status'] ?? 0,
        manager: json['manager'],
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
        lastLoginAt: json['last_login_at'],
        lastLoginIp: json['last_login_ip'],
        role: json['role'] ?? '',
        mrId: json['mr_id'] ?? 0,
        divisions: divisionsList,
        roles: rolesList,
        doctors: docList
    );
  }
}

class Division {
  String divisionName;
  String logo;
  String subscriptionCode;
  String? verified;
  int id;
  String planName;
  String divisionId;
  String fromDate;
  String toDate;
  int isDemo;
  String? poNumber;
  String? poQuantity;
  String rmName;
  String rmEmail;
  String rmMobile;
  int status;
  String? deletedAt;
  String createdAt;
  String updatedAt;
  String base64_logo;
  int divisionIdInt;
  int camp_count_today;
  int camp_count_yesterday;
  int camp_count_this_week;
  int camp_count_last_week;
  int camp_count_this_month;
  int camp_count_last_month;
  int camp_count_total;
  int pat_count_today;
  int pat_count_yesterday;
  int pat_count_this_week;
  int pat_count_last_week;
  int pat_count_this_month;
  int pat_count_last_month;
  int pat_count_total;
  late List<Meta1> meta;



  Division({
    required this.divisionName,
    required this.logo,
    required this.subscriptionCode,
    required this.verified,
    required this.id,
    required this.planName,
    required this.divisionId,
    required this.fromDate,
    required this.toDate,
    required this.isDemo,
    this.poNumber,
    this.poQuantity,
    required this.rmName,
    required this.rmEmail,
    required this.rmMobile,
    required this.status,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.divisionIdInt,
    required this.base64_logo,
    required this.camp_count_today,
    required this.camp_count_yesterday,
    required this.camp_count_this_week,
    required this.camp_count_last_week,
    required this.camp_count_this_month,
    required this.camp_count_last_month,
    required this.camp_count_total,
    required this.pat_count_today,
    required this.pat_count_yesterday,
    required this.pat_count_this_week,
    required this.pat_count_last_week,
    required this.pat_count_this_month,
    required this.pat_count_last_month,
    required this.pat_count_total,
    required this.meta
  });



  factory Division.fromJson(Map<String, dynamic> json) {
    return Division(
        divisionName: json['division_name'] ?? '',
        logo: json['logo'] ?? '',
        subscriptionCode: json['subscription_code'] ?? '',
        verified: json['verified'],
        id: json['id'] ?? 0,
        planName: json['plan_name'] ?? '',
        divisionId: json['division_id'] ?? '',
        fromDate: json['from_date'] ?? '',
        toDate: json['to_date'] ?? '',
        isDemo: json['is_demo'] ?? 0,
        poNumber: json['po_number'],
        poQuantity: json['po_quantity'],
        rmName: json['rm_name'] ?? '',
        rmEmail: json['rm_email'] ?? '',
        rmMobile: json['rm_mobile'] ?? '',
        status: json['status'] ?? 0,
        deletedAt: json['deleted_at'],
        createdAt: json['created_at'] ?? '',
        updatedAt: json['updated_at'] ?? '',
        divisionIdInt: json['division_id_int'] ?? 0,
        base64_logo: json['base64_logo'] ?? '',
        camp_count_today: json['camp_count_today'] ?? 0,
        camp_count_yesterday: json['camp_count_yesterday'] ?? 0,
        camp_count_this_week: json['camp_count_this_week'] ?? 0,
        camp_count_last_week: json['camp_count_last_week'] ?? 0,
        camp_count_last_month: json['camp_count_last_month'] ?? 0,
        camp_count_total: json['camp_count_total'] ?? 0,
        pat_count_today: json['pat_count_today'] ?? 0,
        pat_count_yesterday: json['pat_count_yesterday'] ?? 0,
        pat_count_this_week: json['pat_count_this_week'] ?? 0,
        pat_count_last_week: json['pat_count_last_week'] ?? 0,
        pat_count_this_month: json['pat_count_this_month'] ?? 0,
        pat_count_last_month: json['pat_count_last_month'] ?? 0,
        pat_count_total: json['pat_count_total'] ?? 0,
        camp_count_this_month: json['camp_count_this_month'] ?? 0,
        meta: (json['meta'] as List?)?.map((item) => Meta1.fromJson(item ?? {})).toList() ?? [],


    );
  }


}

// meta.dart
class Meta1 {
  late String key;
  late String value;

  Meta1({required this.key, required this.value});

  factory Meta1.fromJson(Map<String, dynamic> json) {
    return Meta1(
      key: json['key'] ?? '',
      value: json['value'] ?? '',
    );
  }
}

class Role {
  int id;
  String name;
  String guardName;
  String createdAt;
  String updatedAt;
  Pivot pivot;

  Role({
    required this.id,
    required this.name,
    required this.guardName,
    required this.createdAt,
    required this.updatedAt,
    required this.pivot,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      guardName: json['guard_name'] ?? '',
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      pivot: Pivot.fromJson(json['pivot'] ?? {}),
    );
  }
}

class Pivot {
  String modelType;
  int modelId;
  int roleId;

  Pivot({
    required this.modelType,
    required this.modelId,
    required this.roleId,
  });

  factory Pivot.fromJson(Map<String, dynamic> json) {
    return Pivot(
      modelType: json['model_type'] ?? '',
      modelId: json['model_id'] ?? 0,
      roleId: json['role_id'] ?? 0,
    );
  }
}

class AwsCreds {
  String accessKeyId;
  String secretAccessKey;
  String defaultRegion;
  String bucket;
  String bucketFolder;

  AwsCreds({
    required this.accessKeyId,
    required this.secretAccessKey,
    required this.defaultRegion,
    required this.bucket,
    required this.bucketFolder,
  });

  factory AwsCreds.fromJson(Map<String, dynamic> json) {
    return AwsCreds(
      accessKeyId: json['AWS_ACCESS_KEY_ID'] ?? '',
      secretAccessKey: json['AWS_SECRET_ACCESS_KEY'] ?? '',
      defaultRegion: json['AWS_DEFAULT_REGION'] ?? '',
      bucket: json['AWS_BUCKET'] ?? '',
      bucketFolder: json['AWS_BUCKET_FOLDER'] ?? '',
    );
  }
}
class Doctors {
  String id;
  String name;
  String scCode;
  String? mobile;
  String? state;
  String? city;
  String speciality;
  int divisionId;
  String createdAt;
  String updatedAt;
  Pivot pivot;

  Doctors({
    required this.id,
    required this.name,
    required this.scCode,
    this.mobile,
    this.state,
    this.city,
    required this.speciality,
    required this.divisionId,
    required this.createdAt,
    required this.updatedAt,
    required this.pivot,
  });

  factory Doctors.fromJson(Map<String, dynamic> json) {
    return Doctors(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      scCode: json['sc_code'] ?? '',
      mobile: json['mobile'],
      state: json['state'],
      city: json['city'],
      speciality: json['speciality'] ?? '',
      divisionId: json['division_id'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      pivot: Pivot.fromJson(json['pivot'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sc_code': scCode,
      'mobile': mobile,
      'state': state,
      'city': city,
      'speciality': speciality,
      'division_id': divisionId,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
