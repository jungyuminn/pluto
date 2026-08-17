class ApplyStatus {
  ApplyStatus._();

  static const documentSubmitted = '서류제출';
  static const documentPassed = '서류합격';
  static const documentRejected = '서류탈락';
  static const writtenPassed = '필기합격';
  static const writtenRejected = '필기탈락';
  static const interviewPassed = '면접합격';
  static const interviewRejected = '면접탈락';
  static const finalPassed = '최종합격';

  static const rejectedValues = [
    documentRejected,
    writtenRejected,
    interviewRejected,
  ];

  static bool isRejected(String status) => rejectedValues.contains(status);

  static const values = [
    documentSubmitted,
    documentPassed,
    writtenPassed,
    interviewPassed,
    finalPassed,
    documentRejected,
    writtenRejected,
    interviewRejected,
  ];
}
