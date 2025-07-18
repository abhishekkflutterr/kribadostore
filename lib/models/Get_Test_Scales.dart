class GetTestScales {
  String type;
  String version;
  String id;
  String title;
  String description;
  String b64Data;
  List<String> tToken;
  List<Input> inputs;
  List<Evaluation> evaluations;
  Locale locale;

  GetTestScales({
    required this.type,
    required this.version,
    required this.id,
    required this.title,
    required this.description,
    required this.b64Data,
    required this.tToken,
    required this.inputs,
    required this.evaluations,
    required this.locale,
  });

}

class Evaluation {
  int l;
  int h;
  String score;
  List<String> tToken;

  Evaluation({
    required this.l,
    required this.h,
    required this.score,
    required this.tToken,
  });

}

class Input {
  String title;
  bool isRequired;
  List<Option>? options;
  String type;
  String b64Data;
  int id;
  List<String> tToken;
  int? inputDefault;
  int? min;
  int? max;
  List<Range>? ranges;

  Input({
    required this.title,
    required this.isRequired,
    this.options,
    required this.type,
    required this.b64Data,
    required this.id,
    required this.tToken,
    this.inputDefault,
    this.min,
    this.max,
    this.ranges,
  });

}

class Option {
  String title;
  String value;
  int score;
  String b64Data;
  bool selected;
  int id;
  List<String> tToken;
  List<Action>? actions;

  Option({
    required this.title,
    required this.value,
    required this.score,
    required this.b64Data,
    required this.selected,
    required this.id,
    required this.tToken,
    this.actions,
  });

}

class Action {
  bool visible;

  Action({
    required this.visible,
  });

}

class Range {
  String title;
  int min;
  int max;
  int score;
  int id;
  List<String> tToken;

  Range({
    required this.title,
    required this.min,
    required this.max,
    required this.score,
    required this.id,
    required this.tToken,
  });

}

class Locale {
  Mr mr;
  Gu gu;

  Locale({
    required this.mr,
    required this.gu,
  });

}

class Gu {
  String gu1;
  String gu11;
  String gu12;
  String guE1;
  String gu2;
  String gu21;
  String gu22;
  String guE2;
  String gu3;
  String gu31;
  String gu32;
  String guE3;

  Gu({
    required this.gu1,
    required this.gu11,
    required this.gu12,
    required this.guE1,
    required this.gu2,
    required this.gu21,
    required this.gu22,
    required this.guE2,
    required this.gu3,
    required this.gu31,
    required this.gu32,
    required this.guE3,
  });

}

class Mr {
  String mr1;
  String mr11;
  String mr12;
  String mrE1;
  String mr2;
  String mr21;
  String mr22;
  String mrE2;
  String mr3;
  String mr31;
  String mr32;
  String mrE3;

  Mr({
    required this.mr1,
    required this.mr11,
    required this.mr12,
    required this.mrE1,
    required this.mr2,
    required this.mr21,
    required this.mr22,
    required this.mrE2,
    required this.mr3,
    required this.mr31,
    required this.mr32,
    required this.mrE3,
  });

}
