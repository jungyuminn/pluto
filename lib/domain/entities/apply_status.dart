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

  /// 진행이 앞선 단계일수록 큰 값. 서류제출 < 서류합격 < 필기합격 < 면접합격 < 최종합격.
  static int stageRank(String status) {
    return switch (status) {
      finalPassed => 4,
      interviewPassed => 3,
      writtenPassed => 2,
      documentPassed => 1,
      documentSubmitted => 0,
      _ => -1,
    };
  }

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
