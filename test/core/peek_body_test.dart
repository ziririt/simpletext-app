// 길게 눌러 뜨는 미리보기의 본문 — 제목 줄을 빼는 규칙.
//
// 2026-09-13 소유자 신고에서 나온 것이라 재현 사례를 그대로 시험에 남긴다.
// "미리보기가 미리보기 같은 느낌이 애플 메모앱은 확 드는데 내 앱은 어설프다."
// 화면을 나란히 놓고 보니 제목이 두 번 나오고 있었다.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/note_lock.dart';

void main() {
  group('peekBodyBelowTitle', () {
    test('본문 첫 줄이 제목과 같으면 뺀다 — 신고된 그 사례', () {
      const t = '김성동 — 시황 · 투자 · 투자자의 사고 (sungdong.kim@)';
      const b = '$t\n실명, 실제 사람\n2019년부터 미국주식 투자.';
      expect(
        peekBodyBelowTitle(locked: false, title: t, body: b),
        '실명, 실제 사람\n2019년부터 미국주식 투자.',
      );
    });

    test('제목이 본문 첫 줄에서 온 경우도 같은 구멍이다', () {
      const b = '첫 줄이 곧 제목\n둘째 줄\n셋째 줄';
      expect(
        peekBodyBelowTitle(locked: false, title: '첫 줄이 곧 제목', body: b),
        '둘째 줄\n셋째 줄',
      );
    });

    test('제목과 첫 줄이 다르면 본문을 그대로 둔다', () {
      const b = '아주 다른 첫 줄\n둘째 줄';
      expect(peekBodyBelowTitle(locked: false, title: '제목', body: b), b);
    });

    test('제목이 없으면 본문 그대로', () {
      expect(
        peekBodyBelowTitle(locked: false, title: '', body: '한 줄'),
        '한 줄',
      );
    });

    test('제목 줄을 빼고 나면 아무것도 안 남는 메모', () {
      expect(
        peekBodyBelowTitle(locked: false, title: '제목뿐', body: '제목뿐'),
        '',
      );
    });

    test('잠긴 메모는 한 글자도 안 내보낸다 — 자물쇠를 옆문으로 지나가지 않는다', () {
      expect(
        peekBodyBelowTitle(locked: true, title: '제목', body: '비밀 본문'),
        '',
      );
    });

    test('앞뒤 공백은 다듬는다', () {
      expect(
        peekBodyBelowTitle(locked: false, title: '  제목  ', body: '제목\n\n  본문  '),
        '본문',
      );
    });
  });
}
