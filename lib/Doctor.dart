
class Doctor {

  final String country_code;
  final String state_code;
  final String city_code;
  final String area_code;
  final String doc_code;
  final String doc_name;
  final String doc_speciality;
  final int div_id;
  final String dr_id;
  final String doctor_meta;


  final int dr_consent;


  Doctor({required this.country_code,required this.state_code, required this.city_code,required this.area_code,required this.doc_code,required this.doc_name,required this.doc_speciality,required this.div_id,required this.dr_id,required this.dr_consent,required this.doctor_meta});

  Map<String, dynamic> toMap() {
    return {
      'country_code': country_code,
      'state_code': state_code,
      'city_code': city_code,
      'area_code': area_code,
      'doc_code': doc_code,
      'doc_name': doc_name,
      'doc_speciality': doc_speciality,
      'div_id': div_id,

      'dr_id': dr_id,
      'dr_consent ': dr_consent,
      'doctor_meta ': doctor_meta

    };
  }
}