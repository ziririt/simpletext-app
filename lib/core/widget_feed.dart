/// 홈 화면 위젯에 내보낼 목록 — 무엇을 내보내고 무엇을 빼는가.
///
/// 2026-08-19 소유자가 정한 넷 중 셋째. 화면을 그리는 코드는 여기 없다.
/// 안드로이드는 코틀린, 아이폰은 스위프트로 각각 그리고, 이 파일은 그 둘에게
/// **같은 목록**을 건네는 일만 한다. 두 쪽이 서로 다른 규칙으로 고르기
/// 시작하면 한쪽만 고치는 사고가 반드시 난다.
///
/// ## 잠긴 메모는 통째로 뺀다
///
/// 위젯은 **잠금 화면에도 뜬다.** 자물쇠를 걸어 놓은 메모의 본문이 잠금
/// 화면에 떠 있으면 그건 자물쇠가 아니다. 제목만 내보내는 길도 있었지만
/// 안 골랐다 — 이 앱의 제목은 대개 본문 첫 줄에서 자동으로 뽑은 것이라,
/// 제목만 내보내는 것이 곧 본문 첫 줄을 내보내는 것이다.
///
/// 그래서 위젯은 앱 목록의 거울이 아니다. 지름길이다. 인계서 8-3절.
library;

import 'note_lock.dart';

/// 위젯이 알아야 하는 만큼의 메모.
class FeedNote {
  const FeedNote({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
    required this.pinned,
    required this.locked,
  });

  final String id;
  final String title;
  final String body;
  final int updatedAt;
  final bool pinned;
  final bool locked;
}

/// 위젯 한 줄.
class FeedItem {
  const FeedItem({
    required this.id,
    required this.title,
    required this.preview,
    required this.updatedAt,
    required this.pinned,
  });

  final String id;
  final String title;
  final String preview;
  final int updatedAt;
  final bool pinned;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'preview': preview,
        'at': updatedAt,
        'pin': pinned,
      };

  @override
  String toString() => 'FeedItem($id, "$title", "$preview")';
}

/// 위젯에 몇 줄까지 보낼 것인가.
///
/// 여덟이면 안드로이드 4x4, 아이폰 큰 위젯을 채우고도 조금 남는다. 더
/// 보내 봐야 위젯이 안 그리는데, 글은 그만큼 잠금 화면 쪽 저장소에 쌓인다.
const int kWidgetFeedMax = 8;

/// 미리보기를 몇 글자에서 자를 것인가. 위젯 한 줄은 두 줄까지만 그린다.
const int kWidgetPreviewLen = 80;

/// 메모 목록에서 위젯이 그릴 목록을 만든다.
///
/// 차례는 앱 목록과 같다 — 고정한 것이 위, 그다음은 고친 시각 역순. 위젯을
/// 열었을 때 앱과 다른 차례로 서 있으면 같은 물건으로 안 보인다.
List<FeedItem> widgetFeed(
  List<FeedNote> notes, {
  required String untitled,
  int max = kWidgetFeedMax,
}) {
  final live = notes.where((n) => !n.locked).toList();
  live.sort((a, b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    return b.updatedAt.compareTo(a.updatedAt);
  });
  final out = <FeedItem>[];
  for (final n in live) {
    if (out.length >= max) break;
    final head = listTitle(locked: false, title: n.title, body: n.body);
    final flat = listPreview(locked: false, body: n.body);
    // 제목이 본문 첫 줄에서 온 것이면 미리보기에서 그 줄을 뺀다. 같은
    // 문장이 위아래로 두 번 서면 두 줄짜리 칸에서 한 줄을 버리는 셈이다.
    final rest = (n.title.trim().isNotEmpty || head.isEmpty)
        ? flat
        : _dropHead(flat, head);
    out.add(FeedItem(
      id: n.id,
      title: head.isEmpty ? untitled : head,
      preview: _clip(rest, kWidgetPreviewLen),
      updatedAt: n.updatedAt,
      pinned: n.pinned,
    ));
  }
  return out;
}

String _dropHead(String flat, String head) {
  if (!flat.startsWith(head)) return flat;
  return flat.substring(head.length).trimLeft();
}

String _clip(String s, int n) {
  final one = s.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (one.length <= n) return one;
  return '${one.substring(0, n).trimRight()}…';
}

/// 네이티브 쪽으로 건네는 글. 코틀린과 스위프트가 이걸 읽는다.
///
/// 판 번호를 넣는다. 위젯은 앱과 **따로 갱신된다** — 앱을 지웠다 깔아도
/// 위젯은 옛 글을 들고 있을 수 있다. 모양이 바뀌었을 때 네이티브 쪽이
/// "이건 내가 아는 판이 아니다"라고 말할 수 있어야 한다.
Map<String, dynamic> widgetPayload(List<FeedItem> items, int nowMs) => {
      'v': 1,
      'at': nowMs,
      'items': items.map((e) => e.toJson()).toList(),
    };
