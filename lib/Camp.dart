class Camp {

  final String camp_id;
  final String camp_date;
  final String test_date;
  final String test_start_time;
  final String test_end_time;
  final String created_at;
  final String scale_id;
  final num test_score;
  final String interpretation;
  final String language;

  final String pat_age;
  final String pat_gender;
  final String pat_email;
  final String pat_mobile;
  final String pat_name;
  final String pat_id;
  final int division_id;

  final String answers;

  final String subscriber_id;
  final String doc_speciality;
  final String mr_code;

  final String country_code;
  final String state_code;
  final String city_code;
  final String area_code;
  final String doc_code;
  final String doc_name;
  final String dr_id;
  final int patient_consent;
  final int dr_consent;
  final String doctor_meta;
  final String patient_meta;


  Camp({required this.camp_id,required this.camp_date, required this.test_date,required this.test_start_time,required this.test_end_time,required this.created_at,required this.scale_id,required this.test_score,required this.interpretation,required this.language,
    required this.pat_age,required this.pat_gender,required this.pat_email,required this.pat_mobile,required this.pat_name,required this.pat_id,required this.answers,required this.division_id,required this.subscriber_id,required this.doc_speciality,required this.mr_code,
    required this.country_code,required this.state_code,required this.city_code,required this.area_code,required this.doc_code,required this.doc_name,required this.dr_id,required this.patient_consent,required this.dr_consent,required this.doctor_meta,required this.patient_meta});

  /*Camp({required this.camp_id,required this.camp_date, required this.test_date,required this.test_start_time,required this.test_end_time,required this.created_at,required this.scale_id,required this.test_score,required this.interpretation,required this.language,
    required this.pat_age,required this.pat_gender,required this.pat_email,required this.pat_mobile,required this.pat_name,required this.pat_id,required this.answers,required this.division_id});
*/
  Map<String, dynamic> toMap() {
    return {
      'camp_id': camp_id,
      'camp_date': camp_date,
      'test_date': test_date,
      'test_start_time': test_start_time,
      'test_end_time': test_end_time,
      'created_at': created_at,
      'scale_id': scale_id,
      'test_score': test_score,
      'interpretation': interpretation,
      'language': language,

      'pat_age': pat_age,
      'pat_gender': pat_gender,
      'pat_email': pat_email,
      'pat_mobile': pat_mobile,
      'pat_name': pat_name,
      'pat_id': pat_id,
      'patient_consent': patient_consent,
      'dr_consent': dr_consent,
      'division_id': division_id,

      'answers': answers,

      'subscriber_id': subscriber_id,
      'doc_speciality': doc_speciality,
      'mr_code': mr_code,

      'country_code': country_code,
      'state_code': state_code,
      'city_code': city_code,
      'area_code': area_code,
      'doc_code': doc_code,
      'doc_name': doc_name,
      'dr_id': dr_id,
      'doctor_meta': doctor_meta,
      'patient_meta': patient_meta

    };
  }
}