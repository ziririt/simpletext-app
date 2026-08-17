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
// material.dart는 rendering.dart를 다시 내보내지 않는다. InlineAdBlock이
// 뷰포트에 자기 자리를 물으려면 이것이 필요하다(2026-08-17 analyze가 잡음).
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'core/ad_gate.dart';
import 'main.dart' show AppColorsX;
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
    // 2026-08-16 소유자 신고 — 아이패드에서 배너가 검은 띠에 얹혀 흉했다.
    // 원인은 광고가 아니라 우리 배치였다. 아이패드 가로는 1366pt인데 광고는
    // 표준 리더보드 728pt라 양옆 638pt가 남는다. 그 자리를 아무것도 안 칠해
    // 두니 검게 나왔다.
    //
    // 광고를 화면 폭에 억지로 늘리지 않는다 — 늘리면 광고주 소재가 없어
    // 노쇼가 늘고, 늘어난 소재는 더 흉하다. 대신 남는 자리를 앱 색(panel)으로
    // 칠하고 광고를 가운데 놓는다. 폰에서는 광고가 폭을 꽉 채우므로 이
    // 여백이 0이 되어 보이지 않는다 — 한 코드로 둘 다 맞는다.
    final c = context.c;
    return Container(
      width: double.infinity,
      color: c.panel,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(bottom: BorderSide(color: c.glassLine)),
      ),
      child: SizedBox(
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

/// 본문 끝·목록 끝에 놓이는 큰 사각 광고(300×250, 미디엄 렉탱글).
///
/// 2026-08-17 소유자 지시 — "리스트 맨 하단과 편집화면의 본문 맨 아래에
/// 전면 광고를 넣어줘. 스크롤하면 아래 레이어에 나오는 광고처럼 해줘."
///
/// 꼭대기 배너와 성격이 둘 다르다.
///   1) 자리 — 배너는 늘 보이는 곳에 있고 이것은 끝까지 내려가야 나온다.
///      글을 쓰는 동안에는 눈에 들어오지 않는다. 그래서 타자를 방해하지
///      않는다는 소유자 지시와 어긋나지 않는다.
///   2) 움직임 — 화면 밑에서 올라오는 동안 본문보다 조금 늦게 따라온다.
///      아래 레이어에 깔려 있던 것이 드러나는 것처럼 보인다. 지금은
///      48픽셀이다. 더 주면 '광고가 따로 논다'로 보이고, 안 주면 그냥
///      붙어 있는 네모다.
///
/// 광고 단위는 배너와 같은 것을 쓴다. 애드몹의 배너 단위는 크기를 요청할
/// 때 정하므로 사각 광고를 따로 발급받을 필요가 없다.
///
/// '후원' 이름표를 위에 붙인다. 광고를 광고라고 밝히지 않는 것은 속임수이고,
/// 애플·구글 둘 다 그것으로 반려한다.
class InlineAdBlock extends StatefulWidget {
  /// 광고 위에 두는 빈 자리.
  ///
  /// 2026-08-17 소유자 신고 — "목록에서는 너무 목록에 바짝 붙어서 광고가
  /// 나온다. 항목 2개 정도 더 여유를 두고 광고를 나오게 해라."
  ///
  /// 옳다. 목록의 마지막 줄과 광고가 붙어 있으면 광고가 **목록의 다음
  /// 항목처럼** 보인다. 그건 우리가 원하는 것도 아니고 정직하지도 않다.
  /// 목록 한 줄이 대략 60이니 두 줄 자리를 비운다.
  ///
  /// 이 값을 바깥에 따로 두지 않고 광고 위젯이 갖는 이유: 광고가 안 뜨는
  /// 날(광고 없는 날·불러오기 실패·맥/윈도우)에는 이 빈 자리도 같이
  /// 사라져야 한다. 바깥에 두면 아무것도 없는 자리에 여백만 남는다.
  final double gapAbove;

  const InlineAdBlock({super.key, this.gapAbove = 0});

  @override
  State<InlineAdBlock> createState() => _InlineAdBlockState();
}

class _InlineAdBlockState extends State<InlineAdBlock> {
  /// 불러오기 전에 잡아 두는 높이. 실제 높이는 광고가 온 뒤에 물어서
  /// 바꾼다(_adH).
  static const double _fallbackH = 250;

  /// 광고에게 허락하는 최대 높이. 화면 높이의 이만큼까지 준다.
  ///
  /// 2026-08-17 소유자 물음 — "풀 페이지 광고는 없어서 그런가? 광고 단가가
  /// 훨씬 높을 것 같은데."
  ///
  /// 반은 맞다. 전에는 우리가 300×250이라고 **못 박아** 요청하고 있었다.
  /// 그러면 구글은 그 크기의 소재만 보낸다. 인라인 적응형(inline adaptive)은
  /// 크기를 못 박지 않고 "이만큼까지 되니 있는 것 중 제일 좋은 걸 달라"고
  /// 묻는 방식이다. 그러면 300×600(하프페이지) 같은 큰 판이 들어올 수
  /// 있고, 그쪽이 단가가 훨씬 높다.
  ///
  /// 0.8로 두는 이유: 1.0을 주면 화면을 통째로 덮는 소재가 올 수 있는데,
  /// 그건 스크롤 도중에 나타나는 자리에 놓기엔 위험하다. 사용자가 무엇을
  /// 보고 있었는지 잃어버리고, 애플·구글 둘 다 '글과 구별되지 않는 전면
  /// 광고'를 싫어한다. 화면의 8할이면 충분히 크고, 위아래로 우리 화면이
  /// 남아 있어 '광고 안에 갇혔다'는 느낌이 안 든다.
  static const double _maxHFrac = 0.8;

  BannerAd? _ad;
  double _adH = _fallbackH;
  double _adW = 300;
  bool _loaded = false;
  bool _creating = false;
  ScrollPosition? _pos;

  @override
  void initState() {
    super.initState();
    Store.instance.addListener(_refresh);
    AdsService.instance.ready.addListener(_refresh);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = Scrollable.maybeOf(context)?.position;
    if (p != _pos) _pos = p;
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _create(double width, double maxHeight) {
    if (_creating || _ad != null) return;
    _creating = true;
    // 크기를 못 박지 않고 '이만큼까지 되니 제일 좋은 걸 달라'고 묻는다.
    // 300×250만 요청하던 것을 이렇게 바꾸면 300×600(하프페이지)처럼
    // 단가가 높은 판이 들어올 수 있다.
    final size = AdSize.getInlineAdaptiveBannerAdSize(
        width.truncate(), maxHeight.truncate());
    final ad = BannerAd(
      adUnitId: bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loaded) async {
          // 인라인 적응형은 **온 뒤에야 실제 크기를 안다.** 물어보지 않고
          // 요청한 값으로 자리를 잡으면, 작은 소재가 왔을 때 아래가 텅 빈
          // 회색 칸으로 남는다(어제 편집 화면에서 본 그 회색 네모가 이것과
          // 같은 종류의 실수였다).
          AdSize? real;
          try {
            real = await (loaded as BannerAd).getPlatformAdSize();
          } catch (_) {
            real = null;
          }
          if (!mounted) return;
          setState(() {
            if (real != null && real.height > 0) {
              _adH = real.height.toDouble();
              _adW = real.width.toDouble();
            }
            _loaded = true;
          });
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
    ad.load();
  }

  /// 지금 얼마나 늦게 따라와야 하는가.
  ///
  /// 슬롯의 위쪽이 화면 아래 끝에 막 닿았을 때 가장 많이 뒤처지고, 슬롯이
  /// 화면 안에 다 들어오면 0이 된다. 스크롤이 없는 화면이거나 셈에 필요한
  /// 것이 아직 없으면 0이다 — 움직임은 있으면 좋은 것이지 없으면 안 되는
  /// 것이 아니다.
  ///
  /// 2026-08-17 — 뒤처지는 폭을 48픽셀 고정에서 **광고 높이의 절반**으로
  /// 바꿨다. 48은 너무 작아서 소유자 눈에 '그냥 붙어 있는 네모'로 보였다.
  /// 절반이면 광고가 아래 레이어에 깔려 있다가 위 종이가 걷히면서 드러나는
  /// 것처럼 보인다.
  double _shift() {
    final p = _pos;
    if (p == null || !p.hasPixels || !p.hasViewportDimension) return 0;
    try {
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize || !box.attached) return 0;
      final vp = RenderAbstractViewport.maybeOf(box);
      if (vp == null) return 0;
      // 슬롯의 위가 화면 위에 닿는 스크롤 값.
      final reveal = vp.getOffsetToReveal(box, 0.0).offset;
      // 슬롯의 위가 화면 아래 끝에 닿는 스크롤 값.
      final enter = reveal - p.viewportDimension;
      final t = ((p.pixels - enter) / p.viewportDimension).clamp(0.0, 1.0);
      return (1 - t) * _adH * 0.5;
    } catch (_) {
      // 붙어 있지 않은 렌더 객체에 물으면 던진다. 광고 하나 때문에 화면이
      // 죽는 일은 없어야 한다.
      return 0;
    }
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
    final media = MediaQuery.of(context);
    _create(media.size.width, media.size.height * _maxHFrac);
    if (_ad == null || !_loaded) return const SizedBox.shrink();

    final c = context.c;
    final l = L10n.of(context);
    final ad = SizedBox(
      width: _adW,
      height: _adH,
      child: ClipRect(child: AdWidget(ad: _ad!)),
    );
    // 2026-08-17 소유자 신고 — "본문과 광고 사이에 단절된 느낌을 줘. 지금은
    // 본문에 광고가 들어갈 것 같은 오해를 줄 듯."
    //
    // 옳은 지적이고, 이건 취향이 아니라 정직함의 문제다. 광고가 글의 일부로
    // 보이면 그건 광고를 숨긴 것이다. 애플·구글 둘 다 그것으로 반려한다.
    //
    // 그래서 세 가지를 한꺼번에 쓴다. 하나만으로는 약하다.
    //   1) 가로로 꽉 찬 선 — '글은 여기서 끝'
    //   2) 다른 바탕색 — 종이(글 자리)가 아니라 화면 바탕
    //   3) 가운데 놓인 '후원' 이름표 — 무엇이 오는지 말로도 밝힌다
    //
    // 이름표를 왼쪽 구석이 아니라 가운데 둔 것도 이유가 있다. 왼쪽 구석의
    // 작은 글씨는 '본문의 각주'처럼 읽히고, 가운데의 글씨는 '여기서 갈린다'로
    // 읽힌다.
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 이 빈 자리는 광고 판 **밖**이다. 그래야 위쪽 바탕(목록·종이) 색을
        // 그대로 이어받아, 자르는 선이 광고 판의 첫 줄이 된다.
        if (widget.gapAbove > 0) SizedBox(height: widget.gapAbove),
        Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line)),
      ),
      padding: const EdgeInsets.only(top: 14, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.adSponsored,
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                  color: c.sub)),
          const SizedBox(height: 12),
          ClipRect(
            child: SizedBox(
              height: _adH,
              width: double.infinity,
              child: _pos == null
                  ? Center(child: ad)
                  : AnimatedBuilder(
                      animation: _pos!,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _shift()),
                        child: child,
                      ),
                      child: Center(child: ad),
                    ),
            ),
          ),
        ],
      ),
        ),
      ],
    );
  }
}

/// 이 화면에 큰 광고가 뜰 만한가.
///
/// 편집 화면이 '글 끝 빈칸'을 얼마나 둘지 정할 때 쓴다. 광고가 있으면
/// 광고 자체가 굴릴 자리를 주므로 빈칸은 두 줄이면 되고, 없으면 예전대로
/// 화면 절반을 둬야 한다(마지막 줄을 화면 한가운데까지 끌어올릴 자리).
///
/// 확실히 뜬다는 보장은 아니다 — 불러오기가 실패할 수도 있다. 다만 그건
/// 드물고, 틀렸을 때의 값이 '빈칸이 두 줄뿐'이라 크지 않다.
bool inlineAdLikely() =>
    adsSupported &&
    bannerVisible(
        now: DateTime.now(),
        adFreeDate: Store.instance.settings.adFreeDate) &&
    AdsService.instance.ready.value;
