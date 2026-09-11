/// 최신 판이 나왔는지 애플에게 직접 물어보는 길 (2026-09-11 신설).
///
/// 소유자 지시: "설정에 추가. 최신 버전 체크해서 바로 업데이트되게."
///
/// ── 왜 이 파일이 필요했나 ────────────────────────────────────────────
///
/// 2026-09-10, 소유자가 제 아이폰에서 옛 판을 쓰고 있으면서 그것이
/// 최신인 줄 알았다. 앱스토어 화면의 단추가 '업데이트'가 아니라 '열기'
/// 였기 때문이다. 이미 고쳐 놓은 것을 "아직도 안 고쳐졌다"고 신고했다.
/// **앱이 제 나이를 모르면, 사람이 대신 헷갈린다.**
///
/// ── 함정 하나 ────────────────────────────────────────────────────────
///
/// 애플의 공개 조회 창구
///
///   https://itunes.apple.com/lookup?id=<앱번호>
///
/// 가 돌려주는 version 은 **스토어 페이지에 보이는 이름**(1.6)이지
/// 앱 안 버전(3.17.18)이 아니다. 둘은 다른 줄기다(version.dart 참고).
/// 그래서 비교는 반드시 kStoreVersion 하고 한다. appVersion 과 비교하면
/// 3.17.18 > 1.6 이라 **영원히 "최신입니다"** 라고 답하는 앱이 된다.
///
/// ── 앞선 판을 쓰는 사람을 낡았다고 말하지 않는다 ────────────────────
///
/// 소유자는 늘 테스트플라이트로 스토어보다 앞선 판을 쓴다. 내 것이 더
/// 크면 '최신'이다. 부등호를 한쪽으로만 본다.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// 판정 결과.
enum UpdateVerdict {
  /// 물어보지 못했거나 값이 비었다.
  unknown,

  /// 내 것이 스토어 것과 같거나 더 앞선다.
  current,

  /// 스토어에 더 새 판이 있다.
  outdated,
}

/// 스토어가 알려 준 한 줄.
class StoreRelease {
  const StoreRelease({required this.version, this.url, this.at});

  /// 스토어 페이지에 보이는 이름. 예: '1.6'
  final String version;

  /// 그 앱의 스토어 주소. 애플이 내려 준 값을 그대로 쓴다.
  final String? url;

  /// 그 판이 나간 시각.
  final DateTime? at;
}

/// 점으로 끊어 숫자로 견준다. 앞자리부터, 없는 자리는 0으로 친다.
///
/// '1.10' 은 '1.9' 보다 크다 — 글자로 견주면 반대가 되는 자리라
/// 이 함수가 있어야 한다.
int compareVersions(String a, String b) {
  final pa = versionSegments(a);
  final pb = versionSegments(b);
  final n = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < n; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x < y ? -1 : 1;
  }
  return 0;
}

/// '1.6.2' → [1, 6, 2]. 숫자가 아닌 찌꺼기('1.6b')는 앞의 숫자만 취한다.
List<int> versionSegments(String v) {
  final parts = v.trim().split('.');
  final out = <int>[];
  for (final p in parts) {
    final m = RegExp(r'\d+').firstMatch(p);
    out.add(m == null ? 0 : (int.tryParse(m.group(0)!) ?? 0));
  }
  return out.isEmpty ? <int>[0] : out;
}

/// 내 것[mine]과 스토어 것[store]을 견준 판정.
UpdateVerdict verdictFor(String mine, String store) {
  if (mine.trim().isEmpty || store.trim().isEmpty) return UpdateVerdict.unknown;
  return compareVersions(mine, store) < 0
      ? UpdateVerdict.outdated
      : UpdateVerdict.current;
}

/// 애플이 돌려준 덩어리에서 필요한 것만 뽑는다.
///
/// 네트워크와 떼어 놓아야 시험할 수 있다. 그래서 따로 뒀다.
StoreRelease? parseLookup(String body) {
  Object? j;
  try {
    j = jsonDecode(body);
  } catch (_) {
    return null;
  }
  if (j is! Map) return null;
  final results = j['results'];
  if (results is! List || results.isEmpty) return null;
  final r = results.first;
  if (r is! Map) return null;
  final v = r['version'];
  if (v is! String || v.trim().isEmpty) return null;
  final url = r['trackViewUrl'];
  final at = r['currentVersionReleaseDate'];
  return StoreRelease(
    version: v.trim(),
    url: url is String && url.isNotEmpty ? url : null,
    at: at is String ? DateTime.tryParse(at) : null,
  );
}

/// 조회 주소. 나라를 안 붙인다 — 판 이름은 나라마다 다르지 않고,
/// 안 붙이는 쪽이 실패할 구멍이 하나 적다.
///
/// [nonce] 는 중간 저장소가 옛 답을 물고 있는 것을 피하려고 붙인다.
Uri lookupUri(String appStoreId, {int? nonce}) => Uri.parse(
  'https://itunes.apple.com/lookup?id=$appStoreId'
  '&t=${nonce ?? DateTime.now().millisecondsSinceEpoch}',
);

/// 애플에게 물어본다. 못 물어보면 null — 예외를 밖으로 내보내지 않는다.
///
/// 이 물음이 실패하는 것은 앱이 하는 일 중 가장 안 중요한 축에 든다.
/// 비행기 안이거나 지하철이면 그냥 실패한다. 그것 때문에 설정 화면이
/// 멈추거나 붉은 화면이 뜨면 그게 더 큰 사고다.
Future<StoreRelease?> fetchStoreRelease(
  String appStoreId, {
  http.Client? client,
  Duration timeout = const Duration(seconds: 6),
}) async {
  final c = client ?? http.Client();
  try {
    final res = await c.get(lookupUri(appStoreId)).timeout(timeout);
    if (res.statusCode != 200) return null;
    return parseLookup(res.body);
  } catch (_) {
    return null;
  } finally {
    if (client == null) c.close();
  }
}
