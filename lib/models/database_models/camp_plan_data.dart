class CampPlanData {
  final String camp_plan_data;

  CampPlanData({required this.camp_plan_data});

  Map<String, dynamic> toMap() {
    return {
      'camp_plan_data': camp_plan_data,
    };
  }
}
