class Resources {
  final String user_id;
  final String division_detail;
  final String scales_list;
  final String s3_json;

  Resources({required this.user_id,required this.division_detail,required this.scales_list, required this.s3_json});

  Map<String, dynamic> toMap() {
    return {
      'user_id': user_id,
      'division_detail': division_detail,
      'scales_list': scales_list,
      's3_json':s3_json
    };
  }
}
