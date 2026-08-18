// 붙여넣은 글의 뼈대를 바로잡는 규칙.
//
// 2026-08-18. 소유자가 그록 답변을 붙여넣고 정리했더니 '-'와 '• : •'가
// 튀어나온 그 사고를 못 박는다. 눈으로는 못 본다 — 탭과 U+2028 은 화면에
// 안 보이는 글자다.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/inbound_text.dart';

void main() {
  group('보이지 않는 줄바꿈', () {
    test('U+2028 은 줄바꿈이다', () {
      expect(normalizeInbound('가\u2028나'), '가\n나');
    });
    test('U+2029 와 U+0085 도', () {
      expect(normalizeInbound('가\u2029나'), '가\n나');
      expect(normalizeInbound('가\u0085나'), '가\n나');
    });
    test('윈도 줄바꿈도 그대로 다룬다', () {
      expect(normalizeInbound('가\r\n나\r다'), '가\n나\n다');
    });
  });

  group('탭 글머리표 — 그록·챗GPT가 목록을 내는 모양', () {
    test('탭·점·탭은 목록이지 표가 아니다', () {
      expect(normalizeInbound('\t\u2022\tHome Depot'), '- Home Depot');
    });
    test('탭 여러 개도', () {
      expect(normalizeInbound('\t-\t\t내용'), '- 내용');
    });
    test('번호는 번호를 살린다', () {
      expect(normalizeInbound('\t1.\t첫째'), '1. 첫째');
      expect(normalizeInbound('\t12)\t열둘'), '12) 열둘');
    });
    test('여러 줄이 다 바뀐다 — 여기가 표로 읽히던 자리다', () {
      const src = '\t\u2022\t가\n\t\u2022\t나';
      expect(normalizeInbound(src), '- 가\n- 나');
      expect(normalizeInbound(src).contains('\t'), isFalse);
    });
  });

  group('남은 탭', () {
    test('앞머리 탭은 들여쓰기가 된다', () {
      expect(normalizeInbound('\t안쪽'), '  안쪽');
      expect(normalizeInbound('\t\t더 안쪽'), '    더 안쪽');
    });
    test('가운데 탭은 안 건드린다 — 진짜 표일 수 있다', () {
      expect(normalizeInbound('이름\t값'), '이름\t값');
    });
  });

  test('특수 공백은 보통 공백으로', () {
    expect(normalizeInbound('가\u00a0나'), '가 나');
    expect(normalizeInbound('가\u3000나'), '가 나');
  });

  test('평범한 글은 하나도 안 바뀐다', () {
    const t = '오늘은 날씨가 좋다.\n- 첫째\n- 둘째';
    expect(normalizeInbound(t), t);
  });

  test('빈 글', () => expect(normalizeInbound(''), ''));
}
