/// 설정 > 릴리즈 노트에 보이는 버전별 업데이트.
///
/// 새 릴리즈를 만들 때 이 목록 **맨 위**에 버전을 추가하세요.
/// 기능은 [items], 버그 수정은 [fixes]에 적습니다.
class ReleaseNote {
  const ReleaseNote({
    required this.version,
    this.items = const [],
    this.fixes = const [],
  });

  final String version;
  final List<String> items;
  final List<String> fixes;
}

abstract final class ReleaseNotes {
  static const all = [
    ReleaseNote(
      version: '1.0.10',
      items: [
        '홈에서 카드를 길게 눌러 순서를 바꿀 수 있어요',
        '카드를 누르면 할 일 라벨처럼 바운스돼요',
        '설정에서 업데이트 내용을 볼 수 있어요',
        '일주일 위젯을 홈 화면에 둘 수 있어요',
      ],
      fixes: [
        '홈 카드 순서를 바꾼 뒤 한 번 깜빡이던 문제를 고쳤어요',
        '할 일 추가 버튼을 누르면 카드 전체가 같이 움츠러들던 문제를 고쳤어요',
        '다시 시작하기를 눌러도 홈 카드가 바로 안 바뀌던 문제를 고쳤어요',
        '할 일 완료 체크가 늦게 반응하던 문제를 고쳤어요',
      ],
    ),
    ReleaseNote(
      version: '1.0.9',
      fixes: [
        '릴리즈 버전에서 알림이 안 오던 문제를 고쳤어요',
      ],
    ),
    ReleaseNote(
      version: '1.0.8',
      fixes: [
        '알림 시간을 한국 시간으로 맞췄어요',
      ],
    ),
    ReleaseNote(
      version: '1.0.7',
      fixes: [
        '알림이 예약된 시각에 안 오던 문제를 고쳤어요',
      ],
    ),
    ReleaseNote(
      version: '1.0.6',
      items: [
        '언젠가 목표를 만들고 오늘 기록을 남길 수 있어요',
        '테마마다 아이콘·버튼 강조색이 달라져요',
      ],
      fixes: [
        '알림이 늦은 새벽으로 밀려 울리던 문제를 고쳤어요',
      ],
    ),
    ReleaseNote(
      version: '1.0.5',
      items: [
        '홈과 캘린더 분위기를 테마로 바꿀 수 있어요',
        '글꼴과 할 일·캘린더 글자 크기를 고를 수 있어요',
        '설정 화면을 더 보기 쉽게 정리했어요',
      ],
      fixes: [
        '할 일 알림이 오지 않던 문제를 고쳤어요',
        '위젯에서 할 일을 완료하면 알림이 전부 지워지던 문제를 고쳤어요',
      ],
    ),
    ReleaseNote(
      version: '1.0.4',
      items: [
        '홈 화면을 위젯으로 볼 수 있어요',
        '지난주·지난달 요약을 받을 수 있어요',
      ],
      fixes: [
        '테스트용 알림이 자꾸 오던 문제를 고쳤어요',
      ],
    ),
    ReleaseNote(
      version: '1.0.3',
      items: [
        '할 일 시작 전에 알림을 받을 수 있어요',
        '하루 요약을 원하는 시간에 받을 수 있어요',
      ],
      fixes: [
        '위젯으로 앱을 열면 뒤로가기가 생기던 문제를 고쳤어요',
      ],
    ),
    ReleaseNote(
      version: '1.0.2',
      items: [
        '라이트 모드와 다크 모드를 고를 수 있어요',
        '초성·띄어쓰기로도 검색할 수 있어요',
      ],
    ),
    ReleaseNote(
      version: '1.0.1',
      items: [
        '홈에 보여줄 카드를 설정에서 고를 수 있어요',
        '대체공휴일이 캘린더에 표시돼요',
      ],
    ),
    ReleaseNote(
      version: '1.0.0',
      items: [
        '오늘·내일 할 일과 캘린더를 한곳에서 볼 수 있어요',
        '취업 과정을 기업별로 정리할 수 있어요',
      ],
    ),
  ];

  static String get latestVersion => all.first.version;
}
