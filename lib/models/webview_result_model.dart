class WebviewResultModel {
  final QnaResult qna;
  final String? options;
  final String? mode;
  final String? scaleName;
  final String? references;

  WebviewResultModel({
    required this.qna,
    this.options,
    this.mode,
    this.scaleName,
    this.references,
  });

  factory WebviewResultModel.fromJson(Map<String, dynamic> json) {
    return WebviewResultModel(
      qna: QnaResult.fromJson(json['results']['qna']),
      options: json['options'],
      mode: json['mode'],
      scaleName: json['scale_name'],
      references: json['references'],
    );
  }
}

class QnaResult {
  final Map<String, QnaItem> items;
  final Interpretation interpretation;

  QnaResult({
    required this.items,
    required this.interpretation,
  });

  factory QnaResult.fromJson(Map<String, dynamic> json) {
    final qnaMap = <String, QnaItem>{};
    if (json['qna'] != null) {
      json['qna'].forEach((key, value) {
        qnaMap[key] = QnaItem.fromJson(value);
      });
    }
    return QnaResult(
      items: qnaMap,
      interpretation: Interpretation.fromJson(json['interpretation']),
    );
  }
}

class QnaItem {
  final String title;
  final String questionId;
  final String label;
  final dynamic score;
  final String answer;
  final String b64data;

  QnaItem({
    required this.title,
    required this.questionId,
    required this.label,
    required this.score,
    required this.answer,
    required this.b64data,
  });

  factory QnaItem.fromJson(Map<String, dynamic> json) {
    return QnaItem(
      title: json['title'] ?? '',
      questionId: json['question_id'] ?? '',
      label: json['label'] ?? '',
      score: json['score'],
      answer: json['answer'] ?? '',
      b64data: json['b64data'] ?? '',
    );
  }
}

class Interpretation {
  final String finalInterpretation;
  final dynamic finalResult;
  final dynamic dyspeptic;
  final dynamic reflux;

  Interpretation({
    required this.finalInterpretation,
    required this.finalResult,
    required this.dyspeptic,
    required this.reflux,
  });

  factory Interpretation.fromJson(Map<String, dynamic> json) {
    return Interpretation(
      finalInterpretation: json['finalInterpretation'] ?? '',
      finalResult: json['finalResult'],
      dyspeptic: json['dyspeptic'],
      reflux: json['reflux'],
    );
  }
}
