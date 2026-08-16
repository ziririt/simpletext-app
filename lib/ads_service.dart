/// 광고 — 애드몹 배너(최상단) + 하루 한 번 전면 광고.
///
/// 소유자 확정 규칙(2026-08-16):
///   - 무료 이용자는 화면 최상단에 배너가 붙는다
///   - 앱 사용 5분이 지나면 전면 광고가 하루 한 번 나온다
///   - 그 전면 광고를 본 날은 배너까지 전부 사라진다 (그날 하루 광고 없음)
/// 판정 규칙은 core/ad_gate.dart(순수 함수, 테스트 6개로 고정)에 있다.
///
/// ── 개발용/실전용 광고 구분 — 반드시 읽을 것 ──────────────────────
/// 개발 중에는 구글 공식 테스트 광고만 나간다. 실제 광고 ID는 스토어 제출
/// 빌드에서만 켠다:
///     flutter build ipa --dart-define=REAL_ADS=true
/// 개발 기기에서 실제 광고를 자꾸 띄우고 누르면 무효 트래픽으로
/// 애드몹 계정이 정지될 수 있다. 절대 REAL_ADS로 일상 테스트하지 말 것.
///
/// 애드몹은 iOS·안드로이드만 지원한다(맥·윈도우 SDK 없음 — 2026-08-16
/// 문서 재확인). 그래서 데스크톱에서 이 파일의 위젯은 자리조차 차지하지
/// 않는다. 앱 ID는 Info.plist / AndroidManifest.xml에 실제 값이 박혀
/// 있어야 한다(그건 테스트/실전 공통).
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/ad_gate.dart';
import 'main.dart' show Store;

const bool kRealAds = bool.fromEnvironment('REAL_ADS');

bool get adsSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

/// 발급 기록: ~/development/_agent/admob_ids.md (2026-08-16 크롬으로 직접 발급)
String get bannerUnitId => Platform.isIOS
    ? (kRealAds
        ? 'ca-app-pub-2336764115275414/1938836960'
        : 'ca-app-pub-3940256099942544/2934735716')
    : (kRealAds
        ? 'ca-app-pub-2336764115275414/2139765486'
        : 'ca-app-pub-3940256099942544/6300978111');

String get interstitialUnitId => Platform.isIOS
    ? (kRealAds
        ? 'ca-app-pub-2336764115275414/3636679980'
        : 'ca-app-pub-3940256099942544/4411468910')
    : (kRealAds
        ? 'ca-app-pub-2336764115275414/5020441662'
        : 'ca-app-pub-3940256099942544/1033173712');

class AdsService {
  AdsService._();
  static final AdsService instance = AdsService._();

  final Stopwatch _use = Stopwatch();
  bool _busy = false;
  Timer? _timer;

  void boot() {
    if (!adsSupported) return;
    MobileAds.instance.initialize();
    _use.start();
    // 30초마다 "이제 전면 광고 나갈 때가 됐나"만 본다. 판정은 ad_gate가 한다.
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => _tick());
  }

  void _tick() {
    final store = Store.instance;
    if (!store.loaded || _busy) return;
    if (!interstitialDue(
      now: DateTime.now(),
      adFreeDate: store.settings.adFreeDate,
      usedSeconds: _use.elapsed.inSeconds,
    )) {
      return;
    }
    _busy = true;
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) async {
              ad.dispose();
              // 끝까지 봤다 — 오늘 하루는 광고 없음. persistSettings가
              // notifyListeners를 불러서 떠 있는 배너도 그 자리에서 사라진다.
              final store = Store.instance;
              store.settings.adFreeDate = dateKey(DateTime.now());
              await store.persistSettings();
              _busy = false;
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _busy = false; // 다음 틱에 재시도
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (_) => _busy = false, // 오프라인 등 — 다음 틱에 재시도
      ),
    );
  }
}

/// 화면 최상단 배너.
///
/// 자리 규칙: 광고를 붙일 수 없는 판(맥·윈도우·웹), 광고 없는 날에는
/// 아무 자리도 차지하지 않는다(SizedBox.shrink). 로드가 끝나기 전에도
/// 자리를 만들지 않는다 — 회색 빈칸이 먼저 뜨는 것이 제일 싸구려로 보인다.
class TopBannerBar extends StatefulWidget {
  const TopBannerBar({super.key});
  @override
  State<TopBannerBar> createState() => _TopBannerBarState();
}

class _TopBannerBarState extends State<TopBannerBar> {
  BannerAd? _ad;
  bool _loaded = false;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    // 전면 광고를 보고 나면 설정(adFreeDate)이 바뀐다 — 그 알림을 받아
    // 배너를 즉시 접는다.
    Store.instance.addListener(_onStore);
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  Future<void> _create(double width) async {
    if (_creating || _ad != null) return;
    _creating = true;
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        width.truncate());
    if (size == null || !mounted) {
      _creating = false;
      return;
    }
    final ad = BannerAd(
      adUnitId: bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
              _creating = false; // 다음 rebuild 때 재시도
            });
          }
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  @override
  void dispose() {
    Store.instance.removeListener(_onStore);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!adsSupported) return const SizedBox.shrink();
    final s = Store.instance.settings;
    if (!bannerVisible(now: DateTime.now(), adFreeDate: s.adFreeDate)) {
      return const SizedBox.shrink();
    }
    _create(MediaQuery.of(context).size.width);
    if (_ad == null || !_loaded) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
