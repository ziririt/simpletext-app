// 최신 판 확인의 셈 — 2026-09-11.
//
// 이 시험이 지키는 것은 하나다. **앱이 제 나이를 틀리게 말하지 않는 것.**
// 애플이 돌려주는 이름(1.6)과 앱 안 이름(3.17.18)이 다른 줄기라, 잘못
// 견주면 영원히 "최신입니다"라고 답하거나 늘 "새 판이 있다"고 말한다.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/update_check.dart';

void main() {
  group('버전 견주기', () {
    test('같으면 0', () {
      expect(compareVersions('1.6', '1.6'), 0);
      expect(compareVersions('1', '1.0'), 0);
      expect(compareVersions(' 1.6 ', '1.6'), 0);
    });

    test('자릿수가 아니라 숫자로 견준다 — 1.10 은 1.9 보다 크다', () {
      expect(compareVersions('1.9', '1.10'), -1);
      expect(compareVersions('1.10', '1.9'), 1);
    });

    test('앞자리가 먼저다', () {
      expect(compareVersions('1.99', '2.0'), -1);
      expect(compareVersions('2.0', '1.99'), 1);
    });

    test('숫자가 아닌 찌꺼기는 앞의 숫자만 본다', () {
      expect(versionSegments('1.6b'), [1, 6]);
      expect(versionSegments('1.6.2'), [1, 6, 2]);
      expect(versionSegments(''), [0]);
    });
  });

  group('판정', () {
    test('스토어가 더 새것이면 낡았다', () {
      expect(verdictFor('1.6', '1.7'), UpdateVerdict.outdated);
    });

    test('같으면 최신이다', () {
      expect(verdictFor('1.6', '1.6'), UpdateVerdict.current);
    });

    // 소유자는 늘 테스트플라이트로 스토어보다 앞선 판을 쓴다.
    // 그를 낡았다고 하면 이 기능은 그 자리에서 쓸모를 잃는다.
    test('내 것이 더 앞서면 최신이다 — 테스트플라이트 사용자', () {
      expect(verdictFor('1.7', '1.6'), UpdateVerdict.current);
    });

    test('한쪽이 비면 모른다고 한다', () {
      expect(verdictFor('', '1.6'), UpdateVerdict.unknown);
      expect(verdictFor('1.6', '  '), UpdateVerdict.unknown);
    });
  });

  group('애플의 답 읽기', () {
    // 2026-09-11에 실제로 받은 모양 그대로.
    const real =
        '{"resultCount":1,"results":[{"trackName":"Skyblue Note",'
        '"version":"1.6","currentVersionReleaseDate":"2026-09-10T17:50:47Z",'
        '"trackViewUrl":"https://apps.apple.com/kr/app/skyblue-note/id6802185169?uo=4"}]}';

    test('이름·주소·날짜를 뽑는다', () {
      final r = parseLookup(real);
      expect(r, isNotNull);
      expect(r!.version, '1.6');
      expect(r.url, contains('id6802185169'));
      expect(r.at, DateTime.utc(2026, 9, 10, 17, 50, 47));
    });

    test('빈 답·깨진 답·이름 없는 답은 null', () {
      expect(parseLookup('{"resultCount":0,"results":[]}'), isNull);
      expect(parseLookup('<html>차단됨</html>'), isNull);
      expect(parseLookup('{"results":[{"trackName":"x"}]}'), isNull);
      expect(parseLookup('{"results":[{"version":"  "}]}'), isNull);
    });
  });

  test('조회 주소에는 앱 번호와 캐시 깨는 값이 들어간다', () {
    final u = lookupUri('6802185169', nonce: 42);
    expect(u.host, 'itunes.apple.com');
    expect(u.queryParameters['id'], '6802185169');
    expect(u.queryParameters['t'], '42');
  });
}
