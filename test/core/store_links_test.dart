/// 스토어 주소 시험 (2026-08-24). 주소는 한 곳에서만 나온다.
import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/core/store_links.dart';

void main() {
  test('앱스토어 주소에는 우리 앱 번호가 들어 있다', () {
    expect(appStoreUrl(), contains('6802185169'));
  });

  test('평가 주소는 리뷰 작성 화면으로 바로 간다', () {
    expect(appStoreReviewUrl(), contains('action=write-review'));
    expect(appStoreReviewUrl(), contains(kAppStoreId));
  });

  test('공유 주소 — 아이폰은 스토어, 나머지는 소개 페이지', () {
    expect(shareUrl(isIOS: true), appStoreUrl());
    expect(shareUrl(isIOS: false), landingUrl());
  });
}
