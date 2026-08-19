// 위젯이 무엇을 내보내고 무엇을 빼는가 — 잠금 화면에 뜨는 물건이라
// 여기가 틀리면 자물쇠가 뚫린다.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/widget_feed.dart';

FeedNote n(String id,
        {String title = '',
        String body = '',
        int at = 0,
        bool pin = false,
        bool lock = false}) =>
    FeedNote(
        id: id,
        title: title,
        body: body,
        updatedAt: at,
        pinned: pin,
        locked: lock);

void main() {
  group('무엇을 빼는가', () {
    test('잠긴 메모는 통째로 빠진다', () {
      final f = widgetFeed([
        n('a', title: '열린 것', body: '본문', at: 2),
        n('b', title: '잠근 것', body: '비밀', at: 3, lock: true),
      ], untitled: '제목 없음');
      expect(f.map((e) => e.id).toList(), ['a']);
    });

    test('제목만 내보내는 길도 안 간다 — 잠긴 것은 이름조차 없다', () {
      final f = widgetFeed([n('b', title: '잠근 것', at: 1, lock: true)],
          untitled: '제목 없음');
      expect(f, isEmpty);
    });
  });

  group('차례', () {
    test('고정한 것이 위, 그다음 고친 시각 역순', () {
      final f = widgetFeed([
        n('old', title: 'old', at: 1),
        n('new', title: 'new', at: 9),
        n('pin', title: 'pin', at: 2, pin: true),
      ], untitled: '제목 없음');
      expect(f.map((e) => e.id).toList(), ['pin', 'new', 'old']);
    });

    test('여덟에서 끊는다', () {
      final many = [for (var i = 0; i < 20; i++) n('n$i', title: 't$i', at: i)];
      expect(widgetFeed(many, untitled: '-').length, 8);
      expect(widgetFeed(many, untitled: '-', max: 3).length, 3);
    });
  });

  group('한 줄의 모양', () {
    test('제목이 없으면 본문 첫 줄이 제목, 미리보기는 그 다음부터', () {
      final f = widgetFeed([n('a', body: '첫 줄이다\n둘째 줄\n셋째 줄', at: 1)],
          untitled: '제목 없음');
      expect(f.first.title, '첫 줄이다');
      expect(f.first.preview, '둘째 줄 셋째 줄');
    });

    test('제목이 있으면 미리보기는 본문 전부', () {
      final f = widgetFeed([n('a', title: '제목', body: '첫 줄\n둘째 줄', at: 1)],
          untitled: '제목 없음');
      expect(f.first.title, '제목');
      expect(f.first.preview, '첫 줄 둘째 줄');
    });

    test('본문이 아예 없으면 제목 없음', () {
      final f = widgetFeed([n('a', at: 1)], untitled: '제목 없음');
      expect(f.first.title, '제목 없음');
      expect(f.first.preview, '');
    });

    test('미리보기는 여든 글자에서 자른다', () {
      final long = List.filled(200, '가').join();
      final f = widgetFeed([n('a', title: '제목', body: long, at: 1)],
          untitled: '-');
      expect(f.first.preview.length, kWidgetPreviewLen + 1); // 말줄임표 한 자
      expect(f.first.preview.endsWith('…'), isTrue);
    });
  });

  test('네이티브로 건네는 글에는 판 번호가 있다', () {
    final p = widgetPayload(
        widgetFeed([n('a', title: '제목', at: 5)], untitled: '-'), 12345);
    expect(p['v'], 1);
    expect(p['at'], 12345);
    expect((p['items'] as List).length, 1);
    expect((p['items'] as List).first['id'], 'a');
  });
}
