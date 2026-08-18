// 언제 회사를 부를 것인가 — 돈이 나가는 판단이라 시험으로 못 박는다.
//
// 2026-08-18. 눈으로 봐서는 틀린 줄 모르는 종류다. 요금 고지서가 와야
// 알고, 그때는 이미 사용자가 떠난 뒤다.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/auto_tag_gate.dart';

bool g({
  bool hasKey = true,
  bool enabled = true,
  bool tagsAuto = true,
  int bodyLen = 1000,
  int taggedLen = 1000,
  int tagCount = 3,
  bool bodyChanged = true,
}) =>
    shouldAutoTag(
      hasKey: hasKey,
      enabled: enabled,
      tagsAuto: tagsAuto,
      bodyLen: bodyLen,
      taggedLen: taggedLen,
      tagCount: tagCount,
      bodyChanged: bodyChanged,
    );

void main() {
  group('안 부르는 자리', () {
    test('키가 없으면', () => expect(g(hasKey: false), isFalse));
    test('설정에서 껐으면', () => expect(g(enabled: false), isFalse));
    test('사람이 태그를 만졌으면 — 영영', () {
      expect(g(tagsAuto: false), isFalse);
      // 본문이 아무리 바뀌어도 마찬가지다.
      expect(g(tagsAuto: false, bodyLen: 9000, taggedLen: 100), isFalse);
      // 태그가 하나도 없어도 마찬가지다. 사람이 다 지운 것도 뜻이 있다.
      expect(g(tagsAuto: false, tagCount: 0), isFalse);
    });
    test('열어 보기만 했으면', () => expect(g(bodyChanged: false), isFalse));
    test('글이 너무 짧으면', () => expect(g(bodyLen: 79, tagCount: 0), isFalse));
    test('길이가 거의 안 바뀌었으면', () {
      expect(g(bodyLen: 1299, taggedLen: 1000), isFalse);
      expect(g(bodyLen: 701, taggedLen: 1000), isFalse);
    });
  });

  group('부르는 자리', () {
    test('태그가 아직 하나도 없으면 길이와 무관하게 한 번', () {
      expect(g(tagCount: 0, bodyLen: 80, taggedLen: 80), isTrue);
    });
    test('한 번도 안 뽑았으면', () => expect(g(taggedLen: -1), isTrue));
    test('300자 늘었으면', () => expect(g(bodyLen: 1300, taggedLen: 1000), isTrue));
    test('300자 줄었으면', () => expect(g(bodyLen: 700, taggedLen: 1000), isTrue));
  });

  test('문턱은 딱 300이다', () {
    expect(g(bodyLen: 1300, taggedLen: 1000), isTrue);
    expect(g(bodyLen: 1299, taggedLen: 1000), isFalse);
  });
}
