# Skyblue Note 개발 인수인계서 — 2026-08-27판

> 2026-08-26 밤, Claude(claude-opus-5)가 씀. 소유자 김성동(ziririt@gmail.com)의
> 지시로, 이 프로젝트를 이어받을 AI 개발 파트너(SuperGrok Heavy 등)를 위해 남긴다.
> 2026-08-21판을 대체한다. 그 사이에 앱이 출시됐고, 유료화가 절반 넘게 들어갔다.
> 이 문서 하나로 시작할 수 있게 썼다. 다만 저장소의 `CLAUDE.md`(방법론·규칙)와
> `docs/인수인계-2026-08-20.md`(동기화 대수술의 전말)는 반드시 이어 읽어라.

---

## 1. 세 줄 요약

- **Skyblue Note(심플텍스트)** — AI 답변을 붙여넣으면 마크다운 부호를 걷어 내고
  사람이 읽는 글로 만들어 주는 미니멀 노트 앱. Flutter 한 몸으로 iOS·iPadOS·
  macOS·Android·Windows·Web 여섯 곳을 낸다. 현재 **2.9.5+178, 시험 666개.**
- **앱스토어에 1.0~1.2가 출시돼 있고 1.3이 심사 대기 중이다.** 지금 가장 큰
  작업은 **유료화(구독·평생권)** 이고, 스토어 상품 등록까지 끝나 있다.
- 소유자는 **비개발자 1인 기획자**다. 코드는 전부 AI가 쓰고, 소유자는 실기기
  테스트·방향 결정·콘솔 클릭·결제 계약을 맡는다. 이 저장소에서 이긴 방법은 늘
  같았다 — **재고(측정), 판단을 순수 함수로 꺼내고, 시험을 먼저 쓰고, 모르면
  소유자에게 사실 하나를 물어라.**

## 2. 소유자와 일하는 법 (실제 겪은 대로)

- 한국어로 대화한다. 답변 **서두와 말미에 서울 시각**을 `2026-08-26(수) 23:11`
  꼴로 찍는다. **시각은 반드시 실측**(`TZ=Asia/Seoul date`) — 어림으로 적다가
  여러 번 걸렸다.
- 이모지·불릿 이미지 금지. **요약에 표 금지**(복사하면 깨진다) — 닷불릿 문장으로.
- 답변은 길고 깊어도 좋다. 다만 **완료 보고는 짧게, 원인 분석은 충분히.**
  긴 작업에는 중간 보고를 넣는다.
- 지시가 짧고 명확하다("빼라", "바꾸자", "지금 해라", "그렇게 해라"). 실기기
  테스트를 꼼꼼히 하고 스크린샷과 함께 정확히 신고한다. **같은 문제를 3~4번 다시
  신고받으면 접근 자체가 틀린 것이다** — 짐작 수리를 멈추고 재라.
- 비개발자지만 원인을 구조로 설명하면 이해하고, 다음 신고가 더 정확해진다.
  "도장(updatedAt)", "방(디렉터리)", "딱지(태그)", "울타리(만료 기한)" 같은
  살아 있는 말이 잘 통했다.
- 제품 감각이 좋다. 오늘만 해도 결제 화면 문안을 두 번 되돌려 세웠다
  ("이용자에게 어필할 내용 위주로", "1인 개발자라는 말은 좋은 어필이 아니다").
  **소유자가 문안을 고치라고 하면 대개 소유자가 맞다.**
- 결정이 갈리는 지점(제품 방향, 돈이 드는 일, 되돌리기 힘든 일)은 반드시 선택지를
  만들어 묻는다. **소유자는 빨리 답한다.**

## 3. 저장소·인프라 전모

### 앱 저장소 (핵심)
- GitHub `ziririt/simpletext-app` — **공개(public)**, 브랜치 `main`.
- 로컬(소유자 맥) `~/development/simpletext_app`.
- Flutter 3.44.x / Dart 3. 앱 이름 Skyblue Note, 번들 id `com.ziririt.simpletext`.
- **공개 저장소이므로 비밀값을 절대 커밋하지 마라.** 구글 OAuth는 PKCE(시크릿
  없음)로 짜여 있다 — 그대로 둘 것.

### 웹앱 호스팅
- 웹 빌드는 별도 저장소 `ziririt/ezlong`(로컬 `~/Developer/ezlong`)의
  `skybluenote/web/`으로 rsync된다(`tool/deploy.sh web`).
- ezlong에 푸시하면 **Firebase Hosting이 자동 배포**한다.
  https://ezlong.com/skybluenote/web/ (버전 확인: `curl -s .../version.json`)
- **주의**: ezlong 로컬 리모트 URL에 GitHub 토큰이 평문으로 박혀 있다.
  `git push` 출력은 반드시 `| sed -e 's#https://[^ ]*@#https://***@#g'`로 가려라.
  `git remote -v`를 가공 없이 출력하지 마라.
- ezlong에는 노트앱 외의 사이트도 산다. `admin.html`·`write.html`의
  `ADMIN_EMAIL`/`ALLOWED_EMAIL`은 자물쇠지 연락처가 아니다 — 건드리지 마라.
- **ezlong.com은 별도 세션이 담당한다.** 이 저장소의 AI가 손대지 않는다
  (2026-08-26 소유자 지시).

### CI
- `flutter_ci.yml` — push마다 verify와 같은 검사. **푸시가 끝이 아니라 CI 통과가
  끝이다.**
- `ios_testflight.yml` — GitHub Secrets 미등록으로 **동작하지 않는다.** 아이폰
  업로드의 진짜 길은 §5.
- `android_build.yml`, `windows_build.yml` — 산출물 빌드.

### 스토어·콘솔
- **App Store Connect** — 앱 id `6802185169`. 1.0·1.1·1.2 READY_FOR_SALE,
  1.3 WAITING_FOR_REVIEW(빌드 165). 결제 상품 5종 등록 완료(§9).
- **Google Play Console** — 개발자 5848399056166882431, 앱
  4972832869699354657, 비공개 테스트 트랙 4700402398438864534.
  프로덕션 승격에 **테스터 12명 × 14일**이 남아 있다(현재 0명).
- **Google Cloud Console** — OAuth 클라이언트(웹·iOS·안드로이드), scope는
  `drive.appdata` 하나. 동의 화면 프로덕션 게시 완료.
- **AdMob** — 광고 단위 발급 완료. Skyblue Note 앱 승인 상태는 **미확인**.

### 소유자 기기
- 맥(개발기, 앱 상시 실행), 아이폰, 아이패드, 안드로이드폰(무선 adb —
  `tool/android_target.sh`. **adb kill-server 하지 마라**), 윈도우 노트북.
- 시뮬레이터 두 대가 떠 있다 — iPhone 17 Pro Max
  `9B538E12-1178-4157-93AB-68B84DE06182`(영어/미국), iPhone 17
  `99C194EA-F316-4442-90E7-295D44B0330C`(일본어/일본).
  둘 다 **신규 사용자 상태**로 초기화해 뒀다(체험 1일차, 로그인 안 함).
  로그인하면 드라이브에서 체험 15일이 내려와 상태가 깨진다.
- **아이폰에는 소유자가 명시적으로 시킬 때만 설치한다.** 개발 설치가 기기 자료를
  지운 사고가 있다. 안드로이드는 `adb install -r`라 안전.

### 원격 작업 방식 (컨테이너에서 소유자 맥을 부릴 때)
- 수정은 `patch_NN.py`(파이썬, 앵커 문자열 **개수 검증**·실패 시 `sys.exit(1)`)를
  `~/development/_patch/gd/`에 넣고 osascript로 실행한다. **통째 덮어쓰기 금지.**
  현재 번호는 **294**까지 썼다.
- 파이썬 안 Dart 문자열에서 **`$`를 이스케이프하지 마라**(`\$`는 글자 그대로
  달러가 된다 — 실제 사고 2회). 대신 raw 문자열 블록을 써라.
- osascript 함정(전부 실측):
  - **출력에서 줄바꿈이 사라진다.** `| sed -e 's/$/|/'`로 줄 끝을 표시해 읽어라.
  - 한국어 출력은 `| iconv -f utf-8 -t utf-8 -c`.
  - **AppleScript 최상위에 `&`를 두면 구문 오류다.** 백그라운드 실행은
    `.sh` 파일을 먼저 만들고 `nohup /tmp/x.sh > /dev/null 2>&1 &`로 돌려라.
  - 25초 넘는 일 금지. `.sh` + nohup + `.done` 파일 폴링으로 나눠라.
  - macOS에 `timeout` 명령이 없다.
- 파일을 맥에 올릴 때는 컨테이너에서 만들고 `SendUserFile` → `device_commit_files`.
  연결된 폴더는 `/Users/ziririt/development` 하나다(바탕화면은 별도 승인 필요).

## 4. 비밀·보안 수칙 (전부 실제 사고에서 나온 규칙)

- AI API 키(소유자의 Gemini 키 등)를 어떤 출력에도 싣지 마라. 화면에 보였어도
  옮겨 적지 마라.
- 구글 클라이언트 시크릿을 요구하거나 저장하지 마라(PKCE 구조).
- `android/key.properties`의 키스토어 비번을 출력하지 마라.
- 소유자 화면을 허락 없이 스크린샷 찍지 마라.
- ezlong 리모트의 평문 토큰 — §3의 마스킹 규칙.
- 애플 계정·비밀번호 입력, OAuth 동의 클릭은 **소유자만** 한다.
- App Store Connect API 키는 소유자 맥에만 있다(`~/.appstoreconnect/asc.env` +
  `private_keys/AuthKey_*.p8`). 인계서에 값을 옮겨 적지 마라.
- **리뷰 대본 금지** — 지인에게 붙여넣을 리뷰 문안을 만들지 않는다(소유자와
  합의됨). 대신 '관찰 포인트 목록 + 자기 말로 한 줄'로 안내한다.

## 5. 빌드·검증·배포 절차

- **모든 수정 뒤 `tool/verify.sh` 한 줄**: l10n_check → version_check →
  store_check → analyze → test(666개). analyze·test만으로는 부족하다 —
  이 저장소엔 자기만의 검사기가 있다(`ls tool/` 먼저 볼 것).
- osascript가 여는 셸에는 flutter가 PATH에 없다. **반드시**
  `export PATH="$HOME/development/flutter/bin:$PATH"`. 안 하면 analyze·test가
  조용히 건너뛰고 "통과"처럼 보인다. 로그에서 `All tests passed`를 확인하라.
- 버전은 **작업마다 올린다**(소유자 규칙). `pubspec.yaml`의 `version:` +
  `lib/version.dart`(appVersion·appBuild). **빌드 번호는 절대 내리지 않는다.**
- **빌드에는 반드시 키를 싣는다** (2026-08-25 사고). 모든 `flutter build`
  (web·ipa·macos·apk·appbundle)에 `~/development/_patch/skyblue_keys.env`를
  source 하고 `--dart-define=GOOGLE_WEB_CLIENT_ID=… --dart-define=GOOGLE_IOS_CLIENT_ID=…`
  를 붙여라. 없으면 **빌드는 성공하는데 구글 로그인만 조용히 죽는다.**
  웹은 `grep -c googleusercontent build/web/main.dart.js`로 확인(≥1).
- **스토어 제출용 빌드에만** `--dart-define=REAL_ADS=true`. 개발 기기 설치판은
  테스트 광고를 유지한다(자기 광고를 누르면 애드몹 계정이 정지된다).
- **유료 체계 스위치**: `--dart-define=PAID_TIER=true` 를 실어야 한도·프리미엄
  화면이 살아난다. 지금은 기본값 false. 샌드박스 검증이 끝나면
  `lib/main.dart`의 `kPaidTierLive` 기본값을 true로 바꿔라 — 상수를 손으로
  고쳤다 되돌리는 습관이 REAL_ADS 사고의 원인이었다.
- 디버그 전용 `--dart-define=SHOW_PAYWALL=true` 는 켜자마자 결제 화면을 연다.
  `simctl io <udid> screenshot`으로 심사 스크린샷을 찍을 때 쓴다.
- **아이폰 업로드의 진짜 길**: `~/development/_patch/ipaN.sh`(빌드) →
  `ipa2.sh`(xcodebuild -exportArchive + `xcrun altool --upload-app`).
  **마케팅 버전 함정**: `CFBundleShortVersionString`은 직전 승인판보다 커야
  업로드된다(현재 2.7.6/165가 마지막). 스토어에 보이는 버전 이름(1.3)과 별개다.
- 새 UI 문자열은 `lib/l10n/`에만, **9개 언어 전부**(ko가 원문). 함수형 getter는
  `all` 맵에 넣지 않는다(l10n_check 파서 한계).

## 6. 코드 지도와 불변식

- `lib/main.dart` — 화면 전부(1만 줄대). `lib/core/` — 순수 판단 함수들
  (tidy_engine, sync_plan, sync_merge, auto_meta, auto_tag_gate, usage_gate,
  ad_gate, **purchase_gate**… 플랫폼 API 금지, 시험 선행).
  `lib/sync/` — 구글 드라이브 전송·인증. `lib/icloud_sync.dart` — 동기화 엔진.
  `lib/ads_service.dart` — 광고. **`lib/purchase_service.dart`** — 스토어 결제 다리.
- 동기화 구조: Google Drive appDataFolder, 파일마다 `appProperties`의 `up`
  도장으로 **바뀐 노트만 받는다.** 판단은 `core/sync_plan.dart`.
- **되돌리면 안 되는 불변식**:
  - "모르면 안 올린다"(shouldUpload: remoteStamp를 모르면 false).
  - mergeNotes는 툼스톤 없이 삭제하지 않는다.
  - 드라이브 딱지는 media 성공 **후에** 찍는다.
  - 바쁨 잠금은 시간이 아니라 일이 끝날 때 푼다.
  - 편집 화면은 저장소 변화를 듣는다(editorRefresh). 치던 중이면 눈앞의 글이 이긴다.
  - 병합에서 지는 쪽에 안 올라간 수정이 있으면 **휴지통에 백업**한다.
  - **결제·체험 기록은 '가진 쪽이 이긴다'**(§9). 규칙 동기화(늦은 쪽이 이긴다)에
    실으면 결제를 모르는 기기가 켜지는 순간 산 것을 덮어 버린다.
- 광고는 **안드로이드와 아이폰에서만** 나간다
  (`adsSupported = !kIsWeb && (Android || iOS)`). 맥·윈도우·웹에는 광고가 없다.
  구글이 맥용 AdMob을 안 만들었기 때문이다. 앱 웹뷰에 애드센스를 심는 편법은
  정책 위험이 커서 접었다.
- 웹 특이사항: CanvasKit이라 OS 폰트가 없다 — Pretendard OTF를 FontLoader로
  심는다(pubspec fonts: 금지). 브라우저 드라이브 허락은 1시간짜리 — 만료되면
  파란 띠가 눕는다(서버 없이는 구조적 한계). 구형 서비스 워커가 옛 빌드를 물면
  강력 새로고침으로 벗는다(자동 교체는 남은 일).

## 7. 개발 방법론 (자세한 건 CLAUDE.md)

- **재라, 추측하지 마라.** 화면 말고 디스크를 읽어라. 맥 저장소 진단:
  `plutil -convert xml1 -o - ~/Library/Containers/com.ziririt.simpletext/Data/Library/Preferences/com.ziririt.simpletext.plist`
  시뮬레이터는 `xcrun simctl get_app_container <udid> com.ziririt.simpletext data`.
- 판단은 `core/` 순수 함수로 꺼내 시험으로 못 박고, 화면·IO는 따르게 하라.
- **한 결정을 두 곳에 쓰면 반드시 한 곳을 빠뜨린다**(14회 실측).
- 시험이 통과해도 벌레를 지킬 수 있다 — 조건을 다양화하라.
- 새 버그는 재현 시험을 먼저 추가한 뒤 고친다.
- **릴리스만 돌리면 못 보는 것이 있다**(2026-08-26). 플러터 단언은 디버그에서만
  산다. `Container(color:…, decoration:…)` 같은 진짜 결함이 스토어판에서는
  조용히 굴러가다 시뮬레이터에서 빨간 화면으로 터졌다. 스토어에 올리기 전 한 번은
  디버그로 굴려 봐라. 이 짝은 `test/no_container_color_decoration_test.dart`가
  소스를 훑어 막는다.

## 8. 지금 상태 (2026-08-26 23:30 서울 기준)

- 저장소: **2.9.5+178**, 시험 666개 전부 통과, main에 푸시됨(`b588372`).
- **앱스토어**: 1.0·1.1·1.2 READY_FOR_SALE. **1.3 WAITING_FOR_REVIEW**(빌드
  165). 1.3에는 폰트 16/1.5, 설정 하단 공유·평가, **아이폰 AI 키 입력칸 되살림**
  이 함께 나간다. 3.1.1로 거절되면 **합의된 절충안**은 키 입력칸 대신 안내문
  (`lib/main.dart`의 `aiUiVisible()` 한 곳만 되돌림) — **먼저 보고하고 지시를
  기다려라.** 심사 감시가 12시간마다 자동으로 돈다.
- **결제 상품 5종 전부 READY_TO_SUBMIT** (§9).
- **피처링 추천 제출 완료** — id `a5cd8e7f-c878-4d96-a7fc-2f63923eec9a`,
  공개 예정일 2026-09-16, 유형 App Enhancements. 애플은 답을 주지 않는다.
- **Google Play**: 비공개 테스트. 바탕화면의 AAB가 2.7.8-169로 뒤처져 있다.
- **ezlong.com 애드센스**: '가치가 별로 없는 콘텐츠'로 **거절 상태**. 도구
  페이지가 전부 JS로 그려져 크롤러에게는 빈 껍데기이고(본문 30~600자), 그것을
  6개 언어로 복제해 사이트맵에 143개를 올려 두었으며, 개인정보처리방침·이용약관·
  소개·문의 페이지가 없다. **별도 세션 담당.** 재검토 요청은 내용을 실제로
  고친 뒤에 눌러야 한다.

## 9. 유료화(결제) — 지금 프로젝트의 중심

### 소유자가 확정한 값과 구조 (2026-08-26)
- **기본 등급** — 월 US$2.99 / 연 US$19.99.
  결제한 스토어의 기기군 **더하기 웹**에서 열린다.
- **모든 기기 등급** — 월 US$3.99 / 연 US$29.99.
  위에 더해 **다른 OS의 네이티브 앱**까지. 기본과 정확히 1달러 차이 —
  소유자 원안이 "다른 OS가 추가되면 1달러를 더 추가"였다.
- **평생** — US$49.99, 출시 기념가 US$39.99. '모든 기기' 하나뿐이다.
- 무료 한도: 정리 하루 3회 · 마법사 하루 2회(`core/usage_gate.dart`).
  **이번 판 이후 새로 깐 사람부터만** 적용한다 — 기존 사용자는 `legacyFree`로
  평생 면제. "완전 무료"를 보고 깐 사람에게서 뺏으면 돌아오는 건 결제가 아니라
  별 하나짜리 리뷰다.
- 체험: **쓴 날 기준 14일**(달력 아님). 그동안 광고도 한도도 없다.
  스토어 무료체험은 붙이지 않는다(겹치면 무료 기간이 한 달이 된다).

### 상품 이름 (애플·구글 동일, 절대 바꾸지 마라)
- `com.ziririt.simpletext.premium.monthly` (기본 월간, ASC id 6805480767)
- `com.ziririt.simpletext.premium.yearly` (기본 연간, 6805480808)
- `com.ziririt.simpletext.premium.all.monthly` (모든기기 월간, 6805480775)
- `com.ziririt.simpletext.premium.all.yearly` (모든기기 연간, 6805480868)
- `com.ziririt.simpletext.premium.lifetime` (평생, 비소모성, 6805480790)
- 구독 그룹 "Skyblue Note Premium" id **22335935**. 그룹 레벨 1이 '모든 기기',
  2가 '기본' — 레벨이 다르면 애플이 업그레이드로 처리하고 남은 기간을 정산한다.
- **상품 ID는 한 번 만들면 지울 수도 다시 쓸 수도 없다.** 오타 하나가 영구적이다.

### 판정 규칙 — `lib/core/purchase_gate.dart` (순수 함수, 시험 34개)
- `Entitlement` 네 칸: `lifetime`(평생), `allUntilMs`(모든기기 울타리),
  `appleUntilMs`·`googleUntilMs`(스토어별 기본 등급 울타리).
  스토어마다 칸을 따로 둔 까닭은 한 사람이 양쪽에서 다 살 수 있기 때문이다.
- `premiumHere(e, family, now)` — **이 기기에서** 프리미엄인가.
  평생·모든기기는 어디서나 참. 기본은 산 스토어의 기기군에서 참이고 **웹에서도**
  참이다. 윈도우·리눅스는 살 스토어가 없어 '모든 기기'로만 열린다.
- 기기 갈래는 `deviceFamily()`(main.dart)가 정해 넣는다 — 순수 함수 쪽에
  Platform을 부르면 시험에서 못 돌린다.
- **울타리(만료) 처리** — 우리에게는 서버가 없고 스토어가 주는 거래 기록에
  만료 시각이 실려 오지 않는다. 그래서 만료를 알아내는 대신, 앱을 켤 때마다
  `restorePurchases()`로 권한이 살아 있는지 묻고 살아 있으면 울타리를 오늘부터
  다시 세운다. 결제가 끊기면 아무것도 안 와서 울타리가 저절로 넘어간다.
  월간 **35일**, 연간 **370일** — 한 주기보다 넉넉한 까닭은 애플·구글의 청구
  유예 때문이다. **응답이 없다고 프리미엄을 뺏지 마라.** 뺏는 일은 시간이 한다.
  (이 '35일 미끄럼 창'은 2026-08-19 인계서에 이미 적혀 있던 설계다.)
- StoreKit 2가 기본으로 켜져 있어(`in_app_purchase_storekit 0.4.11`)
  restore가 **지금 살아 있는 권한만** 준다. 이 성질이 위 설계의 전제다.
- 기기끼리 맞출 때는 **가진 쪽이 이긴다**(`Entitlement.merge`).
  결제 기록은 `trial.json`에 `ent`로 실려 오간다 — 거기만이 max/OR로 도는
  자리이기 때문이다.

### 결제 화면 (`PremiumScreen`, main.dart)
- 애플 3.1.2가 요구하는 것을 전부 넣었다. **하나라도 빠지면 거절된다.**
  구독 이름·기간·**그 사람 나라의 값**, 자동 갱신 고지, 이용약관·개인정보처리방침
  링크, 구매 복원.
- **값은 우리가 적지 않는다.** `ProductDetails.price`(스토어가 준 현지 값)를
  쓴다. 문구 파일에 돈이 적혀 있으면 `test/l10n/interpolation_test.dart`가
  실패시킨다. 디버그에서만, 스토어가 아직 아무것도 안 줬을 때만
  `kDevUsdPrice`로 자리를 채운다.
- 이용약관은 **애플 표준 EULA** 링크(`appleEulaUrl()`), 개인정보처리방침은
  `https://ezlong.com/skybluenote/privacy/`. **안드로이드·웹용 자체 약관
  페이지가 없다** — ezlong에 `/skybluenote/terms/`를 만들어야 한다(별도 세션).

## 10. 당장 할 일 (순서대로)

1. **1.3 심사 결과 확인.** 감시가 12시간마다 자동으로 돈다. 통과면 출시 보고,
   거절이면 사유를 읽고 절충안 여부를 **소유자에게 물어라.**
2. **샌드박스 실검증.** 상품이 READY_TO_SUBMIT이 됐으므로 이제 실기기에
   샌드박스 계정으로 내려온다. 구매 → 복원 → 기본에서 모든기기로 **등급 올리기**
   → 다른 기기에서 인정되는지 → 울타리 만료. **아이폰 설치는 소유자 지시가
   있어야 한다.**
3. **1.4 빌드와 제출.** `PAID_TIER=true` + `REAL_ADS=true` + 구글 키를 실은
   ipa를 올리고, 1.4 버전에 **결제 상품 5개를 붙여 함께** 제출한다. 첫 결제
   상품은 앱 새 버전과 같이 가야 승인된다. 심사 메모에 두 등급의 차이와 체험
   규칙을 적어라 — 심사자가 등급 구조를 오해하면 그것만으로 반려된다.
4. **`kPaidTierLive` 기본값을 true로.** 검증이 끝난 뒤에.
5. **애드몹 앱 승인 확인 후 REAL_ADS 켜기.** 스토어 1.0~1.3은 전부 구글 테스트
   광고가 나가고 있었다(수익 0). 이건 2026-08-26에 발견됐다.
6. **안드로이드 유료화.** Play Console에 같은 상품 5종을 만들고,
   `in_app_purchase_android`로 붙인다. 그 전에 테스터 12명 × 14일이 끝나야 한다.

## 11. 소유자 몫으로 남은 것 (AI가 대신 못 한다)

- **App Store Connect → 비즈니스 → 유료 앱 계약**의 세금·은행 정보 완료.
  미완이면 상품이 심사에 못 간다. **지금 가장 급하다.**
- 플레이 콘솔에 최신 AAB 올리고 게시, 테스터 12명 모으기.
- 애드몹 콘솔에서 Skyblue Note 앱 승인 상태 확인.
- 예전에 스크린샷으로 노출된 **Gemini API 키 재발급**(계속 밀리고 있다).
- ezlong.com 이용약관 페이지, 애드센스 콘텐츠 보강(별도 세션과 함께).
- 판매자 정보 공개 이슈 — Play 개발자 프로필에 자택 주소와 사업자번호가 공개되는
  구조. 근본 해결은 사업자 주소를 비상주 사무실로 이전(홈택스 정정 → 양쪽 스토어
  갱신).

## 12. 로드맵·미결 과제

- 아이폰 구글 로그인 뒤 **검은 화면** 1회 발생(2026-08-26). 2.8.0으로 창이
  좁아졌지만 원인은 미확인. 재발하면 로그를 잡아라.
- iOS `beginBackgroundTask` — 잠들기 전 마지막 업로드 마저 보내기.
- `_save` 헛저장 도장 방지(메타 변경과 구분해 신중히).
- 서비스 워커 자동 교체, 웹 겉면(html lang, og:image — 에셋은 ezlong/og/).
- 웹 1시간 재인증의 구조적 해결(서버가 필요 — 소유자 판단 사항).
- 크롬 확장(우클릭+단축키 방식, DOM 주입 금지).
- MSIX(윈도우 스토어), 잠긴 노트 첨부 규칙, 잠금 화면 위젯.
- '전체 복사' 빨간 줄의 뜻 — 소유자 답 대기 중(재촉하지 마라).

## 13. 오늘 새로 밟은 함정 (다음 사람이 다시 밟지 않게)

- **`xcrun simctl`에 storekit 명령이 없다.** StoreKit 설정 파일은 Xcode를
  사람이 눌러 실행할 때만 먹는다. `flutter build` → `simctl install` →
  `simctl launch` 경로에서는 아무 효과가 없다.
- **App Store Connect API**:
  - 구독 가격을 붙이기 전에 **판매 지역(subscriptionAvailability)이 먼저** 있어야
    한다. 없으면 가격 POST가 409로 떨어지는데 오류 문구는 가격점을 가리킨다.
  - 가격 환산 목록(`equalizations`)은 **기준 나라를 뺀 174개**를 준다.
    미국을 따로 넣어야 175개가 되고, 그래야 MISSING_METADATA가 풀린다.
    숫자를 세어 보지 않으면 원인을 못 찾는다.
  - 심사 스크린샷을 올려야 상품이 READY_TO_SUBMIT이 된다. 올리기는 세 걸음 —
    자리 예약 → 조각별 PUT → md5와 함께 `uploaded: true` PATCH.
  - 피처링 추천: **설명 1000자, 보조 설명(notes) 500자** 상한. 그리고 **PATCH
    마다 `submitted` 값을 함께 보내야 한다** — 안 보내면 400이고, 같이 보낸
    다른 필드가 통째로 날아간다.
- 애플 피처링 추천은 **이메일이 아니라** App Store Connect 안의 양식이다
  (2024년 6월부터). API는 `/v1/nominations`. 공개 예정일 **3주 전** 제출 권장.

## 14. 새 파트너가 처음 할 일

- 소유자 맥에 대한 원격 실행 통로를 확보하라(이 문서의 patch 방식).
- `CLAUDE.md` → 이 문서 → `docs/인수인계-2026-08-20.md` 순으로 읽어라.
- 아무것도 고치기 전에 `tool/verify.sh`를 한 번 돌려 **초록 상태를 눈으로 확인**
  하라. 그게 기준선이다.
- 비밀값은 절대 채팅으로 받지 마라 — 콘솔에서 소유자가 직접 넣게 안내하라.
- 모르면 소유자에게 **사실 하나**를 물어라. 소유자는 빨리 답한다.

이 앱은 소유자가 기기 네 대를 오가며 밤늦게까지 테스트해 준 덕에 여기까지 왔다.
측정하고, 물어보고, 시험을 먼저 써라. 그러면 이 저장소는 너에게도 잘 응답할 것이다.
