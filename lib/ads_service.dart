/// 광고 — 최상단 배너 + '광고 닫기'로만 열리는 후원(전면) 광고.
///
/// 정책 계보: Long Time, Easy Life의 확정 정책(광고 정책·디자인 이관 노트,
/// 2026-08-16)을 뼈대로 하되, 소유자가 이 앱에서 명시한 차이 두 가지:
///   1) 작은 배너는 앱 시작 시점부터 화면 맨 꼭대기에 상시 노출
///      (Long Time의 14일 게이트·10분 하한·13분 리듬은 쓰지 않는다)
///   2) 전면(후원) 광고는 시간이 됐다고 기습하지 않는다 — 배너의
///      '광고 닫기' 버튼을 눌렀을 때만, 사전 안내 시트를 거쳐 나온다.
///      타이핑 방해·놀람 금지가 소유자 지시다.
/// 공통 규칙: 전면 광고를 본 날은 배너까지 전부 사라진다(하루 광고 없음).
/// 판정은 core/ad_gate.dart(순수 함수, 테스트로 고정).
///
/// ATT 순서 — Long Time의 심사 거절(2026-07-29)에서 배운 것:
/// iOS 추적 허용 팝업은 첫 실행 약 1초 뒤, MobileAds 초기화보다 먼저.
/// 게이트 뒤로 미루면 "ATT를 쓰는데 권한 요청을 찾을 수 없다"로 반려된다.
///
/// ── 개발용/실전용 광고 구분 — 반드시 읽을 것 ──────────────────────
/// 개발 중에는 구글 공식 테스트 광고만 나간다. 실전 ID는 스토어 제출
/// 빌드에서만: flutter build ipa --dart-define=REAL_ADS=true
/// 개발 기기에서 실광고를 띄우고 누르면 무효 트래픽으로 계정이 정지될
/// 수 있다. 절대 REAL_ADS로 일상 테스트하지 말 것.
///
/// 애드몹은 iOS·안드로이드 전용(맥·윈도우 SDK 없음) — 데스크톱에서는
/// 이 파일의 위젯이 자리조차 차지하지 않는다.
import 'dart:async';
import 'dart:io' show Platform;

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/ad_gate.dart';
import 'l10n/l10n.dart';
import 'main.dart' show Store, PremiumScreen;

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

  /// SDK 초기화가 끝났는가. 배너 위젯이 이걸 기다렸다가 로드한다.
  final ValueNotifier<bool> ready = ValueNotifier(false);
  bool _booting = false;
  bool _adBusy = false;

  Future<void> boot() async {
    if (!adsSupported || _booting) return;
    _booting = true;
    if (Platform.isIOS) {
      // SDK 초기화 전에 ATT 먼저 — 순서를 바꾸면 심사 반려 사유가 된다.
      await Future<void>.delayed(const Duration(seconds: 1));
      try {
        await AppTrackingTransparency.requestTrackingAuthorization();
      } catch (_) {
        // 팝업 실패(설정에서 전역 차단 등)해도 광고는 비개인화로 계속 간다.
      }
    }
    await MobileAds.instance.initialize();
    ready.value = true;
  }

  /// 후원(전면) 광고 한 편. 끝까지 보고 닫으면 true — 그날은 광고 없음.
  Future<bool> showInterstitial() async {
    if (!adsSupported || _adBusy) return false;
    _adBusy = true;
    final done = Completer<bool>();
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) async {
              ad.dispose();
              final store = Store.instance;
              store.settings.adFreeDate = dateKey(DateTime.now());
              // persistSettings의 notifyListeners가 떠 있는 배너를 접는다.
              await store.persistSettings();
              if (!done.isCompleted) done.complete(true);
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              if (!done.isCompleted) done.complete(false);
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (_) {
          if (!done.isCompleted) done.complete(false);
        },
      ),
    );
    final ok = await done.future;
    _adBusy = false;
    return ok;
  }
}

/// 화면 맨 꼭대기의 배너.
///
/// - 광고를 붙일 수 없는 판(맥·윈도우·웹)과 광고 없는 날에는 자리조차
///   차지하지 않는다. 로드 전에도 자리를 안 만든다(회색 빈칸 금지).
/// - 오른쪽 위 X(광고 닫기)를 누르면 곧바로 지워지는 게 아니라 후원
///   안내 시트가 열린다 — "전면 한 편 보면 오늘 하루 배너 없음".
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
    Store.instance.addListener(_refresh);
    AdsService.instance.ready.addListener(_refresh);
  }

  void _refresh() {
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

  void _openSponsorSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: false,
      builder: (_) => const SponsorSheet(),
    );
  }

  @override
  void dispose() {
    Store.instance.removeListener(_refresh);
    AdsService.instance.ready.removeListener(_refresh);
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
    if (!AdsService.instance.ready.value) return const SizedBox.shrink();
    _create(MediaQuery.of(context).size.width);
    if (_ad == null || !_loaded) return const SizedBox.shrink();
    final l = L10n.of(context);
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: Stack(
        children: [
          // Long Time 실측 사고(2026-07-31): 크리에이티브가 프레임 밖까지
          // 그려진 적이 있다 — 반드시 잘라낸다.
          Positioned.fill(child: ClipRect(child: AdWidget(ad: _ad!))),
          Positioned(
            top: 2,
            right: 2,
            child: Tooltip(
              message: l.adClose,
              child: Material(
                color: Colors.black38,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _openSponsorSheet,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 후원 안내 시트 — 전면 광고 직전의 사전 고지 화면.
///
/// 문구 작법(Long Time 확정): "무료입니다"류 금지, 무엇에 돈이 드는지를
/// 말하고, 보상은 눈에 그려지게. 이 앱은 서버가 없으므로 '다음 업데이트'
/// 프레이밍을 쓴다.
class SponsorSheet extends StatefulWidget {
  const SponsorSheet({super.key});
  @override
  State<SponsorSheet> createState() => _SponsorSheetState();
}

class _SponsorSheetState extends State<SponsorSheet> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _watch() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    final ok = await AdsService.instance.showInterstitial();
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
        // 긴 번역(es/pt)이 한국어보다 20~30% 길어 잘린 사고가 있었다 —
        // 처음부터 스크롤로 감싼다.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(0x22E91E63),
                  child: Icon(Icons.favorite, size: 32, color: Color(0xFFE91E63)),
                ),
              ),
              const SizedBox(height: 14),
              Text(l.sponsorTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              // context.c(AppC 확장)는 main.dart 라이브러리 안 것이라 여기서는
              // 테마 파생 색을 쓴다 — 라이트/다크 모두 알아서 맞는 값들이다.
              Text(l.sponsorBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, height: 1.5)),
              if (_failed) ...[
                const SizedBox(height: 8),
                Text(l.sponsorFailed,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13.5, color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _busy ? null : _watch,
                child: Text(_busy ? l.sponsorLoading : l.sponsorWatch,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.sponsorSkip),
              ),
              // 결제 유도(소유자 요청) — 광고가 싫으면 프리미엄이 답이다.
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const PremiumScreen()));
                },
                child: Text(l.sponsorGoPremium,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
