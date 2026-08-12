/// 다국어 전수 검사 — 노하우 문서 6절의 교훈을 코드로 박은 것.
/// "번역 파일은 조용히 썩는다. 키가 다 있는가가 아니라 값이 비어 있지 않은가를 검사하라."
/// - 키 누락: L10n의 추상 멤버라 컴파일러가 잡는다.
/// - all 맵 등록 누락: 아래 개수 비교 + tool/l10n_check.py가 잡는다.
/// - 빈 값·매개변수 미포함: 이 테스트가 잡는다.
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:simpletext/l10n/l10n.dart';

void main() {
  final translations = L10n.allTranslations;

  test('지원 언어는 9개이고 로케일 태그가 서로 다르다', () {
    expect(translations.length, 9);
    expect(L10n.supportedLocales.length, 9);
    final tags = translations.map((t) => t.localeTag).toSet();
    expect(tags.length, 9);
  });

  test('모든 언어의 모든 키 값이 비어 있지 않다', () {
    for (final t in translations) {
      t.all.forEach((key, value) {
        expect(value.trim(), isNotEmpty, reason: '${t.localeTag}.$key 가 비어 있다');
      });
    }
  });

  test('언어별 키 개수가 전부 동일하다 (all 맵 등록 누락 방지)', () {
    final counts = translations.map((t) => t.all.length).toSet();
    expect(counts.length, 1, reason: '언어별 all 맵 크기가 다르다: $counts');
  });

  test('매개변수 있는 문구는 매개변수를 실제로 포함한다', () {
    for (final t in translations) {
      final tag = t.localeTag;
      expect(t.appliedDone('XSUMX'), contains('XSUMX'), reason: '$tag.appliedDone');
      expect(t.tidyCopied('XSUMX'), contains('XSUMX'), reason: '$tag.tidyCopied');
      expect(t.aiCallFailed('XERRX'), contains('XERRX'), reason: '$tag.aiCallFailed');
      expect(t.previewTitle('XPREX'), contains('XPREX'), reason: '$tag.previewTitle');
      expect(t.appliedPrefix('XAX'), contains('XAX'), reason: '$tag.appliedPrefix');
      expect(t.unknownPrefix('XUX'), contains('XUX'), reason: '$tag.unknownPrefix');
      expect(t.warningPrefix('XWX'), contains('XWX'), reason: '$tag.warningPrefix');
      final ti = t.tableInfo(7, 3, 5);
      expect(ti, contains('7'), reason: '$tag.tableInfo n');
      expect(ti, contains('3'), reason: '$tag.tableInfo cols');
      expect(ti, contains('5'), reason: '$tag.tableInfo rows');
      expect(t.replacedCount(42), contains('42'), reason: '$tag.replacedCount');
      final ds = t.dateShort(2026, 8, 12);
      expect(ds, contains('2026'), reason: '$tag.dateShort year');
      expect(ds, contains('12'), reason: '$tag.dateShort day');
    }
  });

  test('시드 메모의 고장난 표 데모가 모든 언어에서 구조를 유지한다', () {
    for (final t in translations) {
      final tag = t.localeTag;
      // 티커·수치는 번역 불변이어야 한다 (엔진 데모가 언어와 무관하게 동작하도록)
      expect(t.seedBody, contains('AAPL'), reason: '$tag.seedBody AAPL');
      expect(t.seedBody, contains('TSLA|-8.3%|8%|'), reason: '$tag.seedBody 깨진 마지막 행');
      expect(t.seedBody, contains('| MSFT | +21.5%'), reason: '$tag.seedBody 셀 부족 행');
      expect(t.seedBody, contains('|------|------|--------|'), reason: '$tag.seedBody 구분 행');
    }
  });

  test('로케일 해석: 중국어 스크립트/지역, 미지원 언어 폴백', () {
    expect(L10n.forLocale(const Locale('ko')).localeTag, 'ko');
    expect(L10n.forLocale(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans')).localeTag, 'zh-Hans');
    expect(L10n.forLocale(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')).localeTag, 'zh-Hant');
    expect(L10n.forLocale(const Locale('zh', 'TW')).localeTag, 'zh-Hant');
    expect(L10n.forLocale(const Locale('zh', 'HK')).localeTag, 'zh-Hant');
    expect(L10n.forLocale(const Locale('zh', 'CN')).localeTag, 'zh-Hans');
    expect(L10n.forLocale(const Locale('zh')).localeTag, 'zh-Hans');
    expect(L10n.forLocale(const Locale('pt', 'BR')).localeTag, 'pt');
    expect(L10n.forLocale(const Locale('it')).localeTag, 'en', reason: '미지원 언어는 영어 폴백');
    expect(L10n.forLocale(null).localeTag, 'en');
  });

  test('용어집 고정: 핵심 기능명 (사용자 확정 사항 — 임의 변경 금지)', () {
    const expected = {
      'ko': '바꾸기',
      'en': 'Replace',
      'ja': '置換',
      'zh-Hans': '替换',
      'zh-Hant': '取代',
      'es': 'Reemplazar',
      'pt': 'Substituir',
      'de': 'Ersetzen',
      'fr': 'Remplacer',
    };
    for (final t in translations) {
      expect(t.replaceAction, expected[t.localeTag], reason: '${t.localeTag}.replaceAction');
    }
  });
}
