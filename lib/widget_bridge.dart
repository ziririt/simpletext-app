/// 홈 화면 위젯에 목록을 건네는 자리.
///
/// 2026-08-19. 그리는 일은 각 운영체제가 한다(안드로이드는 코틀린,
/// 아이폰은 스위프트). 여기가 하는 일은 **무엇을 그릴지 정해서 넘기는 것**
/// 하나뿐이고, 무엇을 그릴지의 규칙은 core/widget_feed.dart 에 있다.
///
/// ## 글자를 네이티브에 두지 않는다
///
/// 위젯에 쓸 말('제목 없음', '메모가 없습니다')을 코틀린과 스위프트의
/// 문자열 자원에 각각 두는 길이 있다. 안 골랐다. 그러면 아홉 언어짜리 말
/// 뭉치가 세 군데(다트·코틀린·스위프트)로 갈라지고, 갈라진 것은 반드시
/// 어긋난다. 대신 **다트가 말까지 담아서 보낸다.** 덤으로 위젯이 기기
/// 언어가 아니라 **앱에서 고른 언어**를 따라간다.
///
/// ## 언제 보내나
///
/// Store.persist() 가 부른다. 그건 글자를 칠 때마다 일어나므로 2초를
/// 모았다가 한 번만 보낸다 — 아이클라우드 올리기와 같은 방식이다.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import 'core/widget_feed.dart';
import 'main.dart' show Store;

/// 위젯에 실어 보낼 말들. 다트가 아는 언어로 채운다.
class WidgetWords {
  const WidgetWords({
    required this.title,
    required this.untitled,
    required this.empty,
    required this.allLocked,
  });

  final String title;
  final String untitled;
  final String empty;
  final String allLocked;

  @override
  bool operator ==(Object other) =>
      other is WidgetWords &&
      other.title == title &&
      other.untitled == untitled &&
      other.empty == empty &&
      other.allLocked == allLocked;

  @override
  int get hashCode => Object.hash(title, untitled, empty, allLocked);
}

class WidgetBridge {
  WidgetBridge._();

  /// 아이폰과 안드로이드에만 홈 화면 위젯이 있다. 맥·윈도우·웹은 부르지도
  /// 않는다 — 없는 플러그인을 부르면 오류가 나고, 그 오류를 삼키는 코드가
  /// 또 늘어난다.
  static bool get supported =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  /// 애플에서 앱과 위젯이 같은 서랍을 보게 하는 이름. ios/Runner.entitlements
  /// 의 application-groups 와 **글자 하나까지 같아야 한다.**
  static const String appGroup = 'group.com.ziririt.simpletext';

  static const String androidProvider = 'SkyblueWidgetProvider';
  static const String iosWidget = 'SkyblueWidget';

  static WidgetWords? _words;
  static Timer? _timer;
  static bool _ready = false;

  static Future<void> init() async {
    if (!supported || _ready) return;
    try {
      await HomeWidget.setAppGroupId(appGroup);
      _ready = true;
    } catch (_) {
      // 위젯이 없다고 앱이 멈출 이유는 없다.
    }
  }

  /// 화면이 아는 말을 알려 준다. 바뀐 게 없으면 아무 일도 안 한다 —
  /// 이 함수는 화면이 다시 그려질 때마다 불린다.
  static void words(WidgetWords w) {
    if (_words == w) return;
    _words = w;
    schedule();
  }

  /// 2초 모았다 한 번 보낸다.
  static void schedule() {
    if (!supported || _words == null) return;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), publish);
  }

  static Future<void> publish() async {
    final w = _words;
    if (!supported || w == null) return;
    await init();
    try {
      final all = Store.instance.notes
          .map((n) => FeedNote(
                id: n.id,
                title: n.title,
                body: n.body,
                updatedAt: n.updatedAt,
                pinned: n.pinned,
                locked: n.locked,
              ))
          .toList();
      final items = widgetFeed(all, untitled: w.untitled);
      // 비어 보이는 까닭이 둘이다. 정말 메모가 없는 것과, 있는데 전부
      // 잠긴 것. 둘을 같은 말로 알리면 두 번째 사람은 메모가 사라진 줄 안다.
      final hidden = items.isEmpty && all.any((n) => n.locked);
      final payload = widgetPayload(
          items, DateTime.now().millisecondsSinceEpoch)
        ..['title'] = w.title
        ..['empty'] = hidden ? w.allLocked : w.empty;
      await HomeWidget.saveWidgetData<String>('feed', jsonEncode(payload));
      await HomeWidget.updateWidget(
          androidName: androidProvider, iOSName: iosWidget);
    } catch (_) {
      // 위젯 갱신이 실패해도 앱은 그대로 돌아야 한다.
    }
  }

  /// 위젯에서 눌러 들어온 주소에서 메모 아이디를 꺼낸다.
  ///
  /// skybluenote://note?id=n123  →  'n123'
  /// skybluenote://new           →  '' (새 메모)
  /// 그 밖                        →  null
  static String? noteIdFrom(Uri? uri) {
    if (uri == null || uri.scheme != 'skybluenote') return null;
    if (uri.host == 'new') return '';
    if (uri.host != 'note') return null;
    final id = uri.queryParameters['id'] ?? '';
    return id.isEmpty ? null : id;
  }
}
