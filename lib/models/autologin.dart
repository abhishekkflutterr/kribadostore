class AutoLoginResp {
  final String resp;


  AutoLoginResp({required this.resp});

  Map<String, dynamic> toMap() {
    return {
      'resp': resp,

    };
  }
}
