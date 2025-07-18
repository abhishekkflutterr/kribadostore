
class UserMr {

  final String mr_code;
  final int subscriber_id;


  UserMr({required this.mr_code,required this.subscriber_id});

  Map<String, dynamic> toMap() {
    return {
      'mr_code': mr_code,
      'subscriber_id': subscriber_id,
    };
  }
}