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
import 'main.dart' show Store, PremiumScreen, kPaidTierLive, rootNavKey;

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

/// 네이티브 광고 단위 — **애드몹 콘솔에서 따로 만들어야 한다.**
///
/// 배너 단위로는 네이티브 광고가 안 나온다. 종류가 다른 상품이다.
/// 소유자가 콘솔에서 '네이티브 고급' 단위를 두 개(iOS·안드로이드) 만들어
/// 이 두 상수를 채우기 전까지는 비어 있고, 그동안은 아래 [nativeUnitId]가
/// null을 돌려주어 **예전 배너 사다리로 저절로 되돌아간다.**
/// 빈 문자열인 채로 스토어에 나가도 광고 자리가 비지 않는다는 뜻이다.
const String kNativeUnitIos = 'ca-app-pub-2336764115275414/1760076247';
const String kNativeUnitAndroid = 'ca-app-pub-2336764115275414/9986050629';

/// 시험용 네이티브 단위(구글 공식). 개발 빌드는 언제나 이것으로 돈다.
const String kNativeTestIos = 'ca-app-pub-3940256099942544/3986624511';
const String kNativeTestAndroid = 'ca-app-pub-3940256099942544/2247696110';

/// 지금 쓸 네이티브 단위. 실광고인데 아직 단위를 안 만들었으면 null.
String? get nativeUnitId {
  if (!kRealAds) {
    return Platform.isIOS ? kNativeTestIos : kNativeTestAndroid;
  }
  final id = Platform.isIOS ? kNativeUnitIos : kNativeUnitAndroid;
  return id.isEmpty ? null : id;
}

/// 네이티브 medium 판이 요구하는 칸 높이. 구글 템플릿의 최소가 320이라
/// 그보다 여유를 둔다. 이보다 낮게 주면 템플릿이 잘려 그려진다.
const double kNativeMediumH = 360;

/// 네이티브 small 판(목록 한가운데용). 가로로 눕는 모양이라 낮다.
const double kNativeSmallH = 110;

/// 맨 위 띠에서 네이티브를 먼저 부를지.
///
/// 2026-09-09 저녁 — 네이티브로 바꾼 판에서 광고가 아예 안 떴다. 시계를
/// 달아 배너로 내려가게 고쳤지만(_natTimer), **네이티브 자체가 끝내 안
/// 채워지는 상황**도 있을 수 있다. 그때는 이 줄만 false 로 바꾸면 예전처럼
/// 배너만 쓴다. 되돌리는 길을 한 줄로 남겨 두는 것이 실험의 예의다.
const bool kTopNative = true;

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

  /// 지금 맨 위 배너가 화면을 먹고 있는가.
  ///
  /// 배너가 네비게이터 위로 올라가면서(main.dart의 MaterialApp builder)
  /// 상태표시줄 여백의 임자가 둘이 됐다 — 배너가 있으면 배너가, 없으면
  /// 아래 화면이 가져야 한다. 임자를 안 정하면 여백이 두 번 붙거나
  /// 글자가 노치 밑으로 들어간다. 그 판정을 여기 하나에 모은다.
  final ValueNotifier<bool> bannerVisible = ValueNotifier(false);

  /// 배너를 걷어야 하는 화면이 몇 장 떠 있는가(AdFreeScope).
  final ValueNotifier<int> adFree = ValueNotifier(0);
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
    // 광고 등급 상한 (2026-09-09 소유자 신고).
    //
    // "이런 저질 광고 배너를 내가 거를 수 있나? 특정 업체 배너는 저 모양이다.
    //  극혐이다." — 속옷·성인용품 같은 소재가 배너에 떴다.
    //
    // 처음엔 G(전체 관람가)로 묶었다. 그런데 그날 저녁 소유자가 다시 말했다 —
    // "광고가 거의 안 뜬다", "2~3분 후에 갑자기 나온다", "어떤 노트는 바로
    // 뜨기도 한다". G는 사실상 어린이 대상 재고만 남기는 등급이라, 채울
    // 소재가 없어서 자리가 비어 있었던 것이다.
    //
    // 그래서 PG로 한 칸 올린다. PG도 성인·선정성 소재는 걸러 준다. 소유자가
    // 본 그 그림들은 등급이 아니라 **민감한 카테고리**로 막는 것이 정확하고,
    // 그건 이미 애드몹 웹 콘솔에서 막아 두었다(HANDOFF.md 참고) —
    //   차단 관리 → 민감한 카테고리 / 광고주 URL / 광고 심사 센터
    //
    // 교훈 한 줄: **거르는 손잡이는 등급이 아니라 카테고리다.** 등급을 낮추면
    // 걸러지는 게 아니라 그냥 광고가 없어진다.
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(maxAdContentRating: MaxAdContentRating.pg),
    );
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
  /// 네이티브 광고를 **먼저** 물어본다. 이것이 뜨면 배너는 안 묻는다.
  ///
  /// 2026-09-09 소유자 신고 — 글자가 한 자도 없는 사진 한 장짜리 광고가
  /// 맨 위에 떴다. "광고 배너 카피도 없고 무슨 내용인지도 모르는데.
  /// 이건 클릭도 못 받고 내 앱의 퀄리티도 떨어뜨린다."
  ///
  /// **까닭은 우리가 이상한 크기를 주문했기 때문이다.** 광고주가 만들어
  /// 두는 글자 있는 소재(제목·설명·단추)는 표준 칸(320x50, 320x100,
  /// 300x250)에 맞춰 그려져 있다. 우리가 100pt 짜리 인라인 어댑티브 같은
  /// 낯선 칸을 부르면, 그 칸에 맞는 글자 소재가 없어서 **그림 한 장을
  /// 늘려 채운** 것이 온다. 칸을 키울수록 더 그렇다.
  ///
  /// 네이티브는 이 문제를 비켜 간다. 구글이 완성된 그림을 주는 것이 아니라
  /// **조각(제목·설명·아이콘·단추 글자)** 을 주고, 그리는 것은 우리다.
  /// 그래서 카피가 늘 있고, 색과 모서리도 우리 것이다.
  ///
  /// 대신 채워지는 비율은 배너보다 낮다. 그래서 실패하면 배너 사다리로
  /// 되돌아간다 — 다만 그때는 **표준 크기부터** 부른다(아래 _sizeFor).
  NativeAd? _native;
  bool _nativeOn = false;
  bool _nativeTried = false;

  /// 네이티브를 기다리는 시계.
  ///
  /// 2026-09-09 저녁 소유자 신고 — "지금은 아예 아무런 배너 광고가 안
  /// 나온다." 내가 낸 구멍이었다. 네이티브를 먼저 부르고 **실패했을 때만**
  /// 배너로 내려가게 만들었는데, 광고판은 성공도 실패도 안 돌려줄 수 있다.
  /// 그러면 영영 빈칸이다.
  ///
  /// > **답을 기다리는 코드에는 반드시 시계를 달아라.** '실패하면 B로
  /// > 간다'는 'A가 실패한다'를 전제로 하는데, 남의 서버는 실패조차 안
  /// > 해 줄 수 있다.
  Timer? _natTimer;

  BannerAd? _ad;
  bool _loaded = false;
  bool _creating = false;
  // 로드 뒤 광고판이 실제로 준 크기. 인라인 어댑티브라 요청과 다를 수 있어,
  // 자리는 이 값으로 잡는다.
  AdSize? _shownSize;

  /// 몇 번째 주문인가. 실패할 때마다 하나 오른다.
  ///
  /// 2026-09-09 소유자 신고 — "편집페이지 상단의 광고가 아예 안 뜨거나
  /// 20초 후에 뜨거나 한다", "2~3분 후에 갑자기 나온다. 깜짝 놀랐다",
  /// "어떤 노트는 바로 뜨기도 한다. 들쑥날쑥 왜 이러지?"
  ///
  /// 두 가지가 겹쳐 있었다.
  ///   1) 주문이 실패해도 **다시 주문할 사람이 없었다.** 재시도가 build 안에
  ///      들어 있어서, 누군가 화면을 다시 그려 줄 때까지 빈칸이었다. 저장이나
  ///      동기화가 우연히 화면을 흔들면 그제서야 광고가 튀어나온다 — 2~3분
  ///      뒤에 나타나는 것이 이것이다.
  ///   2) 요청한 크기가 흔하지 않았다. 100pt 인라인 어댑티브는 채울 소재가
  ///      적다. 여기에 등급 G까지 걸어 두어 남는 재고가 거의 없었다.
  ///
  /// 그래서 **사다리를 만든다.** 실패하면 점점 흔한 크기로 내려가고, 시간을
  /// 두고 스스로 다시 주문한다. 빈칸으로 버티지 않는다.
  int _tries = 0;
  Timer? _retry;

  /// 지금 이 자리가 화면을 먹고 있는가. 껍데기(main.dart의 MaterialApp
  /// builder)가 이걸 보고 상태표시줄 여백을 누가 가질지 정한다.
  static void _tell(bool on) {
    final n = AdsService.instance.bannerVisible;
    if (n.value == on) return;
    // build 중에는 다른 위젯의 상태를 바꾸면 안 된다 — 한 프레임 미룬다.
    WidgetsBinding.instance.addPostFrameCallback((_) => n.value = on);
  }

  @override
  void initState() {
    super.initState();
    Store.instance.addListener(_refresh);
    AdsService.instance.ready.addListener(_refresh);
    AdsService.instance.adFree.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  /// 몇 번째 시도에 어떤 크기를 주문할지.
  ///
  /// 0) 우리가 바라는 큰 자리(인라인 어댑티브, 최대 100pt)
  /// 1) 판마다 표준인 앵커드 어댑티브(폰에서 50pt 남짓) — 재고가 제일 많다
  /// 2) 320x50 고정 배너 — 세상에서 제일 흔한 자리. 여기서도 안 나오면
  ///    그건 우리 잘못이 아니다.
  /// 그다음은 다시 0으로 돈다. 한 번 실패했다고 작은 자리에 영영 갇히면
  /// 큰 자리가 다시 생겨도 못 받는다.
  Future<AdSize?> _sizeFor(int step, int w) async {
    // 2026-09-09 — 차례를 뒤집었다. 예전엔 큰 칸부터 불렀는데, 낯선 칸에는
    // 글자 있는 소재가 없어서 **그림 한 장짜리 광고**가 왔다(위 _native
    // 주석). 글자 없는 큰 광고보다 글자 있는 작은 광고가 낫다.
    if (step == 0) {
      return AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(w);
    }
    if (step == 1) return AdSize.banner;
    // 마지막 자리. 2026-09-06 소유자 지시로 만든 큰 칸인데, 여기까지
    // 내려왔다는 것은 표준 칸 둘이 다 비었다는 뜻이다. 빈칸보다는 낫다.
    // 이건 **최대치**이지 실제 높이가 아니다.
    const double kMaxBannerHeight = 100;
    final anchored =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(w);
    if (anchored == null) return null;
    final tall = anchored.height * 1.2;
    // 둘 중 **큰 것**을 쓴다. 작은 쪽을 고르면 아무것도 안 달라진다 —
    // 처음에 그렇게 썼다가 바로 알아챘다.
    final want = tall > kMaxBannerHeight ? tall : kMaxBannerHeight;
    return AdSize.getInlineAdaptiveBannerAdSize(w, want.round());
  }

  void _later() {
    _retry?.cancel();
    // 2, 5, 10, 20, 30, 60초. 실패가 쌓일수록 뜸해진다 — 네트워크가 죽은
    // 기기에서 1초마다 주문하면 배터리만 먹는다.
    const secs = [2, 5, 10, 20, 30, 60];
    final i = _tries < secs.length ? _tries : secs.length - 1;
    _retry = Timer(Duration(seconds: secs[i]), () {
      if (!mounted) return;
      _create(MediaQuery.of(context).size.width);
    });
  }

  Future<void> _create(double width) async {
    if (_creating || _ad != null || !mounted) return;
    if (!AdsService.instance.ready.value) return;
    _creating = true;
    _retry?.cancel();
    final w = width.truncate();
    final size = await _sizeFor(_tries % 3, w);
    if (size == null || !mounted) {
      _creating = false;
      _tries++;
      if (mounted) _later();
      return;
    }
    final ad = BannerAd(
      adUnitId: bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loaded) async {
          final shown = await (loaded as BannerAd).getPlatformAdSize();
          if (!mounted) return;
          setState(() {
            _loaded = true;
            _tries = 0;
            if (shown != null) _shownSize = shown;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          if (!mounted) return;
          _tries++;
          setState(() {
            _ad = null;
            _loaded = false;
            _creating = false;
          });
          _later();
        },
      ),
    );
    _ad = ad;
    await ad.load();
  }

  /// 네이티브 광고를 한 번 물어본다.
  ///
  /// 구글이 완성된 그림을 주는 것이 아니라 조각(제목·설명·아이콘·단추
  /// 글자)을 주고, 그리는 것은 우리다. 그래서 **카피가 늘 있다.** 색을
  /// 우리 팔레트로 넘기는 까닭도 같다 — 기성 템플릿은 기본이 흰 바탕이라
  /// 다크 모드에서 그 자리만 눈이 부시다. 광고라도 앱의 밤에는 밤이어야 한다.
  ///
  /// 실패하면 다시 묻지 않고 배너로 내려간다.
  void _createNative() {
    if (_nativeTried || _native != null) return;
    _nativeTried = true;
    final unit = kTopNative ? nativeUnitId : null;
    if (unit == null) {
      _create(MediaQuery.of(context).size.width);
      return;
    }
    final c = context.c;
    final ink = Theme.of(context).colorScheme.onSurface;
    final ad = NativeAd(
      adUnitId: unit,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        // small 은 아이콘 + 제목 + 광고주 + 단추다. 맨 위 띠에 딱 맞는다.
        templateType: TemplateType.small,
        mainBackgroundColor: c.panel,
        // 맨 위 띠는 화면 가장자리에 붙어 있다. 모서리를 둥글리면 그 틈에
        // 다른 색이 비쳐 '떠 있는 카드'가 된다 — 여기서는 0 이 맞다.
        cornerRadius: 0,
        primaryTextStyle: NativeTemplateTextStyle(textColor: ink, size: 14),
        secondaryTextStyle: NativeTemplateTextStyle(textColor: c.sub, size: 12),
        tertiaryTextStyle: NativeTemplateTextStyle(textColor: c.sub, size: 11),
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: c.accent,
          size: 14,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          _natTimer?.cancel();
          if (!mounted) return;
          setState(() => _nativeOn = true);
        },
        onAdFailedToLoad: (ad, err) {
          _natTimer?.cancel();
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _native = null;
            _nativeOn = false;
          });
          // 되돌아갈 자리를 연다 — 표준 크기 배너부터 부른다.
          _create(MediaQuery.of(context).size.width);
        },
      ),
    );
    _native = ad;
    // 2.5초. 채워질 광고는 대개 1초 안에 온다. 그보다 오래 걸리는 것은
    // 기다려 봐야 안 오는 것이고, 그동안 사람은 빈 띠를 본다. 짧게 잡는
    // 편이 낫다 — 늦게 뜨는 좋은 광고보다 제때 뜨는 보통 광고가 낫다.
    _natTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted || _nativeOn) return;
      final gone = _native;
      _native = null;
      gone?.dispose();
      _create(MediaQuery.of(context).size.width);
    });
    ad.load();
  }

  /// 무엇을 부를지 고른다. 네이티브가 먼저다.
  void _ensure() {
    if (_nativeOn) return;
    if (!_nativeTried) {
      _createNative();
      return;
    }
    _create(MediaQuery.of(context).size.width);
  }

  void _openSponsorSheet() {
    // 배너는 네비게이터보다 위에 산다. 그래서 자기 context에는 Navigator가
    // 없다 — 뿌리 네비게이터를 이름표로 빌려 온다(main.dart의 rootNavKey).
    final ctx = rootNavKey.currentContext;
    if (ctx == null) return;
    showModalBottomSheet<void>(
      context: ctx,
      showDragHandle: true,
      isScrollControlled: false,
      builder: (_) => const SponsorSheet(),
    );
  }

  @override
  void dispose() {
    _retry?.cancel();
    _natTimer?.cancel();
    _native?.dispose();
    _native = null;
    Store.instance.removeListener(_refresh);
    AdsService.instance.ready.removeListener(_refresh);
    AdsService.instance.adFree.removeListener(_refresh);
    _ad?.dispose();
    _ad = null;
    super.dispose();
  }

  Widget _gone() {
    _tell(false);
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    if (!adsSupported) return _gone();
    final s = Store.instance.settings;
    if (!adsOn(
      now: DateTime.now(),
      adFreeDate: s.adFreeDate,
      trialDays: s.trialDays,
      premium: s.premium,
    )) {
      return _gone();
    }
    // 결제 화면·첫인사 화면 위에는 광고를 얹지 않는다(AdFreeScope).
    if (AdsService.instance.adFree.value > 0) return _gone();
    if (!AdsService.instance.ready.value) return _gone();
    _ensure();
    final native = _nativeOn ? _native : null;
    if (native == null && (_ad == null || !_loaded)) return _gone();
    _tell(true);
    final l = L10n.of(context);
    // 2026-08-16 소유자 신고 — 아이패드에서 배너가 검은 띠에 얹혀 흉했다.
    // 원인은 광고가 아니라 우리 배치였다. 아이패드 가로는 1366pt인데 광고는
    // 표준 리더보드 728pt라 양옆 638pt가 남는다. 그 자리를 아무것도 안 칠해
    // 두니 검게 나왔다. 남는 자리를 앱 색(panel)으로 칠하고 가운데 놓는다.
    final c = context.c;
    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      // 색은 decoration 안에서만 정한다 — Container에 color:와 decoration:을
      // 함께 주면 플러터가 단언으로 막는다(container.dart:277). 릴리스 빌드는
      // 단언을 지우고 지나가므로 스토어판에서는 안 보였고, 시뮬레이터(디버그)
      // 에서 광고 띠가 처음 뜨는 순간 빨간 화면으로 드러났다.
      // (2026-08-26 소유자 신고 — "갑자기 이런 빨간 페이지가 떴다")
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(bottom: BorderSide(color: c.glassLine)),
      ),
      // 상태표시줄 여백은 이제 이 자리가 가진다. 배너가 네비게이터 위로
      // 올라갔기 때문에(main.dart의 MaterialApp builder), 아래 화면들은
      // 위쪽 여백을 넘겨받지 않는다.
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          width: native != null
              ? double.infinity
              : (_shownSize ?? _ad!.size).width.toDouble(),
          height: native != null
              ? kNativeSmallH
              : (_shownSize ?? _ad!.size).height.toDouble(),
          child: Stack(
            children: [
              // Long Time 실측 사고(2026-07-31): 크리에이티브가 프레임 밖까지
              // 그려진 적이 있다 — 반드시 잘라낸다.
              Positioned.fill(
                child: ClipRect(child: AdWidget(ad: native ?? _ad!)),
              ),
              Positioned(
                top: 2,
                right: 2,
                // Tooltip 은 Overlay 를 찾는다. 배너는 네비게이터 위라
                // 위에 Overlay 가 없어서, 길게 눌렀을 때 터진다. 눈에 보이는
                // 것은 그대로 두고 이름만 화면 낭독기에 넘긴다.
                child: Semantics(
                  label: l.adClose,
                  button: true,
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
      ),
    );
  }
}

/// 이 화면이 떠 있는 동안에는 배너를 걷는다.
///
/// 결제 화면과 첫인사 화면이 그렇다. "광고를 없애 드립니다"라고 말하는
/// 화면 맨 위에 광고가 붙어 있으면 그건 농담이 된다.
///
/// 배너가 네비게이터 위로 올라간 뒤로는 화면 쪽에서 "여긴 빼 달라"고
/// 말할 방법이 이것뿐이다 — 감출 화면이 스스로 손을 든다.
class AdFreeScope extends StatefulWidget {
  const AdFreeScope({super.key, required this.child});
  final Widget child;
  @override
  State<AdFreeScope> createState() => _AdFreeScopeState();
}

class _AdFreeScopeState extends State<AdFreeScope> {
  @override
  void initState() {
    super.initState();
    final n = AdsService.instance.adFree;
    n.value = n.value + 1;
  }

  @override
  void dispose() {
    final n = AdsService.instance.adFree;
    n.value = n.value - 1;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
                  child: Icon(
                    Icons.favorite,
                    size: 32,
                    color: Color(0xFFE91E63),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l.sponsorTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              // context.c(AppC 확장)는 main.dart 라이브러리 안 것이라 여기서는
              // 테마 파생 색을 쓴다 — 라이트/다크 모두 알아서 맞는 값들이다.
              Text(
                l.sponsorBody,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
              if (_failed) ...[
                const SizedBox(height: 8),
                Text(
                  l.sponsorFailed,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // ── 여기가 배너의 X를 누른 사람이 서 있는 자리다 ──────────
              //
              // 2026-09-02 소유자 지시로 순서를 뒤집었다. 전에는 '광고 한 편
              // 보기'가 큰 단추였고 프리미엄은 맨 아래 글자 단추였다. 그런데
              // 이 사람은 방금 **광고를 끄겠다고** X를 누른 사람이다. 그
              // 순간에 제일 먼저 보여야 할 답은 '오늘 하루만 없애기'가 아니라
              // '영영 없애기'다.
              //
              // 광고 한 편 보기를 없애지는 않는다. 지갑을 열 생각이 없는
              // 사람에게도 길은 있어야 하고, 그 길이 곧 이 앱의 수입이다.
              // 자리를 아래로 내리고 테두리 단추로 바꿔 두는 것으로 족하다.
              if (kPaidTierLive) ...[
                FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AdFreeScope(child: PremiumScreen()),
                      ),
                    );
                  },
                  child: Text(
                    l.sponsorGoPremium,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.sponsorPremiumNote,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _busy ? null : _watch,
                  child: Text(
                    _busy ? l.sponsorLoading : l.sponsorWatch,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ] else
                // 결제가 꺼진 판(웹·윈도우, 또는 PAID_TIER=false 빌드)에서는
                // 예전 그대로 광고 한 편 보기가 유일한 답이자 큰 단추다.
                FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _busy ? null : _watch,
                  child: Text(
                    _busy ? l.sponsorLoading : l.sponsorWatch,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.sponsorSkip),
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

  /// 가로형으로 놓을 것인가.
  ///
  /// 2026-08-18 소유자 지시 — "메모 목록 중간에 오는 광고 ... 세로로 너무
  /// 긴 배너는 안되겠다. 목록을 잘라먹는 느낌이라서."
  ///
  /// 자리가 다르면 크기도 달라야 한다는 것을 뒤늦게 알았다.
  ///
  ///   목록 **한가운데** — 아래에 목록이 더 있다. 큰 네모가 끼면 화면이
  ///     통째로 광고가 되어 '여기서 목록이 끝났나' 싶어진다. 가로 띠는
  ///     아래에 이어지는 줄이 같이 보이므로 '더 있다'가 눈에 남는다.
  ///   목록 **맨 끝**과 편집 화면 끝 — 아래에 아무것도 없다. 자를 것이
  ///     없으니 큰 것이 맞다(단가도 높다).
  ///
  /// 그래서 크기를 하나로 정하지 않고 자리가 고르게 한다.
  final bool wide;

  const InlineAdBlock({super.key, this.gapAbove = 0, this.wide = false});

  @override
  State<InlineAdBlock> createState() => _InlineAdBlockState();
}

class _InlineAdBlockState extends State<InlineAdBlock> {
  /// 요청할 크기의 차례 — **큰 것부터**.
  ///
  /// 2026-08-17 소유자 신고 — "내가 말한 페이지 풀사이즈 광고가 아니라
  /// 오히려 작은 배너가 중간에 나온다."
  ///
  /// 앞 판에서 인라인 적응형(크기를 안 박고 '이만큼까지 되니 알아서 좋은
  /// 걸 달라')으로 바꿨는데, 돌아온 것은 **더 작은** 띠 배너였다.
  ///
  /// 까닭: 적응형은 '최대'를 말할 뿐 '최소'를 말하지 않는다. 구글은 그
  /// 안에서 자기가 팔기 좋은 것을 고르고, 그건 대개 제일 흔한 작은 띠다.
  /// 우리가 원하는 것은 '되도록 크게'인데 요청은 '이보다 작게'였으니
  /// 정확히 반대를 말한 셈이다.
  ///
  /// 그래서 되돌린다. 크기를 **박되, 큰 것부터 차례로** 묻는다.
  ///   300×600  하프페이지. 단가가 제일 높고 화면을 크게 쓴다
  ///   300×250  미디엄 렉탱글. 채워지는 비율(fill rate)이 제일 높다
  /// 하나가 실패하면 다음 것으로 내려간다. 마지막까지 실패하면 아무것도
  /// 안 그린다 — 빈 회색 네모를 남기지 않는다.
  ///
  /// 작은 화면에서는 600을 아예 안 묻는다. 화면보다 큰 광고는 스크롤
  /// 도중에 나타나면 사람이 무엇을 보고 있었는지 잃어버린다.
  /// 2026-08-27 — **하프페이지(300×600)를 뺐다.**
  ///
  /// 소유자 신고: "가로 폭이 좁은 세로형 배너가 나오네? 이건 내가 원하는 게
  /// 아니다." 맞다. 300×600은 큰 것이지 넓은 것이 아니다. 폭 440 화면에서
  /// 양옆에 70씩 남고 세로로만 600이 뻗는다. 게다가 구글이 그 자리에
  /// 160×600 같은 더 좁은 소재를 채워 넣어 더 앙상해 보였다.
  ///
  /// '풀사이즈'를 높이로 읽은 것이 잘못이었다. 이제 큰 자리는 네이티브
  /// 광고가 맡고(폭을 꽉 채운다), 이 사다리는 네이티브가 실패했을 때만
  /// 쓰는 **되돌아갈 자리**다. 되돌아가더라도 세로로 긴 것은 안 쓴다.
  static const List<AdSize> _big = [AdSize.mediumRectangle];
  static const List<AdSize> _small = [AdSize.mediumRectangle];

  /// 가로형 차례. 큰 것부터라는 규칙은 여기서도 같다.
  ///
  ///   320×100  라지 배너. 가로형 중에서는 존재감이 있는 쪽이다
  ///   320×50   보통 배너. **세상에서 가장 많이 채워지는 크기다** —
  ///            여기까지 내려오면 거의 반드시 무언가 온다
  ///
  /// 인라인 적응형을 안 쓴다. 2026-08-17에 한 번 써 봤고, 적응형은
  /// '최대'만 말하고 '최소'를 말하지 않아 구글이 늘 제일 작은 것을
  /// 골라 줬다. 크기를 박는 편이 예측이 된다.
  static const List<AdSize> _wide = [AdSize.largeBanner, AdSize.banner];

  /// 300×600을 물을 만한 화면 높이(논리 픽셀). 이보다 낮으면 안 묻는다.
  static const double _tallEnough = 760;

  /// 네이티브 광고. 이것이 뜨면 배너는 아예 묻지 않는다.
  NativeAd? _native;
  bool _nativeLoaded = false;
  bool _nativeTried = false;

  BannerAd? _ad;
  double _adH = 250;
  double _adW = 300;
  int _step = 0;
  bool _loaded = false;
  bool _creating = false;
  ScrollPosition? _pos;

  /// 광고가 들어앉는 칸. 자리를 재려면 이 칸의 렌더 객체가 필요하다.
  /// 위젯 전체(빈자리 + 이름표 + 칸)를 재면 이름표 높이만큼 어긋난다.
  final GlobalKey _slotKey = GlobalKey();

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

  void _openSponsorSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: false,
      builder: (_) => const SponsorSheet(),
    );
  }

  List<AdSize> _ladder(double screenHeight) =>
      widget.wide ? _wide : (screenHeight >= _tallEnough ? _big : _small);

  /// 네이티브 광고를 한 번 물어본다. 실패하면 다시 묻지 않고 배너로 내려간다.
  ///
  /// 색을 우리 팔레트로 넘기는 까닭: 구글 기성 템플릿은 기본이 흰 바탕이라
  /// 다크 모드에서 그 자리만 눈이 부신다. 광고라도 앱의 밤에는 밤이어야 한다.
  void _createNative(BuildContext context) {
    if (_nativeTried || _native != null) return;
    _nativeTried = true;
    final unit = nativeUnitId;
    if (unit == null) return; // 아직 단위를 안 만들었다 — 배너로 간다
    final c = context.c;
    final ink = Theme.of(context).colorScheme.onSurface;
    final medium = !widget.wide;
    final ad = NativeAd(
      adUnitId: unit,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: medium ? TemplateType.medium : TemplateType.small,
        mainBackgroundColor: c.panel,
        cornerRadius: 12,
        primaryTextStyle: NativeTemplateTextStyle(textColor: ink, size: 15),
        secondaryTextStyle: NativeTemplateTextStyle(textColor: c.sub, size: 13),
        tertiaryTextStyle: NativeTemplateTextStyle(textColor: c.sub, size: 12),
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: c.accent,
          size: 15,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          setState(() {
            _nativeLoaded = true;
            _adH = medium ? kNativeMediumH : kNativeSmallH;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          if (!mounted) return;
          // 되돌아갈 자리를 연다. _native 를 비우면 build 가 배너를 묻는다.
          setState(() {
            _native = null;
            _nativeLoaded = false;
          });
        },
      ),
    );
    _native = ad;
    ad.load();
  }

  void _create(double screenHeight) {
    if (_creating || _ad != null) return;
    final sizes = _ladder(screenHeight);
    // 다 물어봤는데 아무도 안 줬다. 더 조르지 않는다.
    if (_step >= sizes.length) return;
    final size = sizes[_step];
    _creating = true;
    final ad = BannerAd(
      adUnitId: bannerUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!mounted) return;
          // 크기를 박아 요청했으니 온 것도 그 크기다. 따로 물어볼 필요가
          // 없고, 물어보는 사이 자리가 흔들릴 일도 없다.
          setState(() {
            _adW = size.width.toDouble();
            _adH = size.height.toDouble();
            _loaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          if (mounted) {
            setState(() {
              _ad = null;
              _loaded = false;
              _creating = false;
              // 한 칸 내려가서 다음 rebuild 때 더 작은 것을 묻는다.
              _step += 1;
            });
          }
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  /// 광고 칸의 높이 — **한 페이지**가 되게.
  ///
  /// 2026-08-17 소유자 신고 — "왜 이렇게 중간에 빈 여백 간격이 넓지? 이러면
  /// 스크롤하기 전에 여백 간격만 보고 스크롤 안 해서 광고 효과가 없을 듯."
  ///
  /// 앞 판에서 낸 사고다. 광고를 화면에 붙잡아 두려고 칸을 광고보다 훨씬
  /// 높게 잡았는데(광고 키의 1.9배), **굴릴 거리가 없는 자리**에서는 광고가
  /// 칸 맨 아래로 밀려 내려가 위쪽이 통째로 빈다. 편집 화면 맨 끝이 정확히
  /// 그 자리라, 화면 한 판이 빈 하늘색 상자가 됐다.
  ///
  /// 이제 칸은 **화면 한 판을 넘지 않는다.** 넘으면 그것은 이미 페이지가
  /// 아니라 빈 벌판이다.
  double _slotH(double viewportH) {
    // 가로형은 붙잡아 둘 것이 없다. 칸이 곧 광고다.
    //
    // 아래 1.35배와 '보이는 만큼의 한가운데'는 큰 네모를 화면에 잠깐
    // 멎게 하려고 만든 장치인데, 가로 띠에 그걸 쓰면 띠 위아래로 빈
    // 자리만 생긴다 — 목록을 자르지 않으려고 가로형으로 바꾸는 판에
    // 여백으로 다시 자르는 꼴이다.
    if (widget.wide) return _adH;
    final want = _adH * 1.35;
    return want > viewportH ? viewportH : want;
  }

  /// 칸 안에서 광고를 얼마나 내려 그릴 것인가.
  ///
  /// 셈의 요령은 하나다 — **지금 화면에 보이는 만큼의 한가운데**에 광고를
  /// 둔다.
  ///
  ///   칸이 화면을 꽉 채우는 동안  보이는 부분 = 화면 전체 → 광고가 화면
  ///                               한가운데에 **멎어 있다.** 목록은 흐르는데
  ///                               광고만 가만히 있으니 아래 층에 깔린
  ///                               페이지처럼 보인다.
  ///   칸이 들어오거나 나가는 동안  보이는 부분이 좁아지고, 광고도 그
  ///                               한가운데를 따라간다. 그래서 **어느
  ///                               순간에도 빈 여백이 생기지 않는다.**
  ///
  /// 앞 판은 '화면 한가운데에 붙잡아 두기'만 했다. 그러면 굴릴 거리가 없는
  /// 자리에서 광고가 칸 밖으로 밀려 빈 자리가 남는다. '보이는 만큼의
  /// 한가운데'로 바꾸면 그 경우가 저절로 없어진다.
  double _shift(double slotH) {
    // 칸이 광고와 같은 크기면 옮길 데가 없다. 렌더 객체를 물어볼 일도 없다.
    if (slotH <= _adH) return 0;
    final mid = (slotH - _adH) / 2;
    final p = _pos;
    if (p == null || !p.hasPixels || !p.hasViewportDimension) return mid;
    try {
      final box = _slotKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize || !box.attached) return mid;
      final vp = RenderAbstractViewport.maybeOf(box);
      if (vp == null) return mid;
      // 칸의 위가 화면 위에 닿는 스크롤 값 → 지금 칸 위쪽의 화면 안 위치.
      final reveal = vp.getOffsetToReveal(box, 0.0).offset;
      final slotTop = reveal - p.pixels;
      // 칸 좌표에서 '보이는 구간'.
      final visTop = slotTop < 0 ? -slotTop : 0.0;
      final visBot = (p.viewportDimension - slotTop).clamp(0.0, slotH);
      if (visBot <= visTop) return mid;
      final center = (visTop + visBot) / 2;
      return (center - _adH / 2).clamp(0.0, slotH - _adH);
    } catch (_) {
      // 붙어 있지 않은 렌더 객체에 물으면 던진다. 광고 하나 때문에 화면이
      // 죽는 일은 없어야 한다.
      return mid;
    }
  }

  @override
  void dispose() {
    Store.instance.removeListener(_refresh);
    AdsService.instance.ready.removeListener(_refresh);
    _ad?.dispose();
    _native?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!adsSupported) return const SizedBox.shrink();
    final s = Store.instance.settings;
    if (!adsOn(
      now: DateTime.now(),
      adFreeDate: s.adFreeDate,
      trialDays: s.trialDays,
      premium: s.premium,
    )) {
      return const SizedBox.shrink();
    }
    if (!AdsService.instance.ready.value) return const SizedBox.shrink();
    // 네이티브를 먼저 묻는다. 물어보는 중(_native != null)에는 배너를 켜지
    // 않는다 — 둘이 같이 뜨면 자리가 두 번 흔들린다.
    _createNative(context);
    if (_native == null) _create(MediaQuery.of(context).size.height);
    final showNative = _nativeLoaded && _native != null;
    if (!showNative && (_ad == null || !_loaded)) {
      return const SizedBox.shrink();
    }

    final c = context.c;
    final l = L10n.of(context);
    final slotH = _slotH(MediaQuery.of(context).size.height);
    // 2026-08-17 소유자 지시 — "모든 배너에는 다 x 닫기를 보여주고, '닫기'를
    // 하면 전면 광고 및 후원, 프리미엄 안내해줘."
    //
    // 꼭대기 배너에는 있었는데 이 큰 광고에는 없었다. 같은 광고인데 하나는
    // 끌 수 있고 하나는 못 끄면, 사람은 못 끄는 쪽을 '지울 수 없는 것'으로
    // 여긴다. 그건 광고를 더 미워하게 만들 뿐이다.
    //
    // 누른다고 그냥 사라지지는 않는다. 후원 안내가 열리고, 거기서 전면 광고
    // 한 편을 보면 **그날 하루 광고가 전부 사라진다.** 끄고 싶은 마음과 우리가
    // 받아야 할 몫을 맞바꾸는 자리다.
    // 네이티브는 **폭을 꽉 채운다.** 그게 이 판을 만든 이유다.
    // 배너로 되돌아갔을 때만 박힌 폭(_adW)을 쓴다.
    final ad = SizedBox(
      width: showNative ? double.infinity : _adW,
      height: _adH,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRect(child: AdWidget(ad: showNative ? _native! : _ad!)),
          ),
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
              Text(
                l.adSponsored,
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                  color: c.sub,
                ),
              ),
              const SizedBox(height: 12),
              ClipRect(
                child: SizedBox(
                  key: _slotKey,
                  height: slotH,
                  width: double.infinity,
                  child: _pos == null
                      ? Center(child: ad)
                      : AnimatedBuilder(
                          animation: _pos!,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(0, _shift(slotH)),
                            child: child,
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ad,
                          ),
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
    adsOn(
      now: DateTime.now(),
      adFreeDate: Store.instance.settings.adFreeDate,
      trialDays: Store.instance.settings.trialDays,
      premium: Store.instance.settings.premium,
    ) &&
    AdsService.instance.ready.value;
