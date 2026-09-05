# HANDOFF — Skyblue Note (simpletext_app)

최종 갱신: 2026-09-05 (KST)
이 문서는 누적 기록이 아니라 **현재 상태 한 장**이다. 다음 담당자는 이 문서 하나만 읽고 바로 이어서 작업할 수 있어야 한다.
갱신할 때는 밑에 덧붙이지 말고 **통째로 덮어쓴다.**

과거 기록이 필요하면 `HANDOVER.md`(2026-08-12판, 제품 철학과 초기 설계), `CLAUDE.md`(요약 컨텍스트),
`docs/인수인계-*.md`(날짜별 스냅숏)를 본다. **현재 상태의 기준은 이 문서다.**

---

## 1. 한 장 요약

- 앱 이름: Skyblue Note (한국어 표기 '스카이블루 노트', 옛 이름 '심플텍스트')
- 정체: AI 답변(ChatGPT·Claude·Gemini·Grok)을 붙여넣으면 바로 쓸 수 있는 깨끗한 플레인 텍스트로 바꿔 주는 앱.
  일반 메모 앱과 경쟁하지 않는다. **정리 엔진(tidy engine)과 표 엔진이 제품이고 UI는 그 다음이다.**
- 프레임워크: Flutter 3.44.x / Dart 3, 단일 코드베이스
- 배포 대상: iOS, iPadOS, macOS, Android, Web. **Windows 앱은 아직 없다 — 어디에도 '윈도'라고 쓰지 말 것.**
- 저장소: `ziririt/simpletext-app` (**PUBLIC**), 기본 브랜치 `main`
- 로컬 경로: `/Users/ziririt/development/simpletext_app`
- 번들 ID: `com.ziririt.simpletext`
- App Store ID: `6802185169`
- 현재 버전: **3.17.0+222** (`pubspec.yaml`, `lib/version.dart`)
- App Store 마케팅 버전: **1.5** (앱 버전과 다른 계통이다. 헷갈리지 말 것)
- 소개 페이지: https://ezlong.com/skybluenote/

자매 프로젝트(별도 저장소, 자주 같이 건드린다)

- **Long Time, Easy Life** — iOS/watchOS 플립시계 앱. `~/Developer/flipzen-weather-app`,
  `ziririt/flipzen-weather-source`, App Store `id6793780938`, Play `com.ezlong.flipzenweather`.
  소개 페이지 https://ezlong.com/longtime/
- **ezlong** — 호스팅 저장소. `~/Developer/ezlong`, `ziririt/ezlong`. push하면 Firebase Hosting 자동 배포.

소유자는 개발자가 아니다. 26년차 웹 기획자이며 코드를 직접 쓰지 않는다.
담당자가 코드·빌드·스토어 제출까지 전부 대행한다. 보고는 한국어, 완료 보고는 짧게, 원인 분석은 깊게.

---

## 2. 작업 환경 — 이것부터 이해할 것

### 2.1 맥 계정이 둘이다 (2026-09-05 확인)

이 맥북에어에는 macOS 로컬 계정이 **`ziririt`와 `aladin` 두 개** 있고, 프로젝트가 갈려 있다.

- `/Users/ziririt/development/` — 소유자 `ziririt`. **simpletext_app이 여기 있다. 읽기·쓰기·git 전부 된다.**
- `/Users/ziririt/Developer/` — 디렉터리와 내용물의 소유자가 **`aladin`**. ezlong, flipzen-weather-app이 여기 있다.
  파일 내용은 읽히지만 `.git/config`가 600/aladin이라 **`ziririt` 계정으로는 git 명령이 전부 실패한다**
  (`unable to access '.git/config': Permission denied`, `detected dubious ownership`).
- `/Users/ziririt/ezlong-live/` — 2026-08-20에 멈춘 **옛 복사본**이다. 최신 아니다. 여기서 작업하지 말 것.

그래서 지금 붙어 있는 세션(계정 `ziririt`)에서는

- Skyblue Note: 커밋·푸시·빌드·스토어 제출까지 **전부 가능**
- ezlong / flipzen: 파일 편집은 되지만 **커밋·푸시 불가.** 웹 배포가 필요하면 소유자에게
  `aladin` 계정에서 Claude 데스크톱 앱을 띄워 달라고 요청한다.

**다른 코워크 세션이 "로컬에 파일이 없다"고 하면 십중팔구 계정이 다르거나 폴더가 연결 안 된 것이다.**
연결돼야 하는 폴더는 `/Users/ziririt/development`, `/Users/ziririt/Developer` 둘이다.

### 2.2 셸이 세 개다. 헷갈리면 하루를 날린다

- `bash` (일반) → 클라우드 컨테이너. 소유자 파일 없음. 문서 작성·계산용.
- `device_bash` → 맥에 붙은 **리눅스 VM**. 저장소가 `~/mnt/development/simpletext_app`로 마운트돼 보인다.
  **macOS 바이너리는 여기서 안 돈다** — `flutter`, `xcrun`, `sips`, Xcode 관련 전부 불가.
  `git`은 일반 명령은 되지만 `.git/config`가 막힌 저장소(ezlong)에서는 실패한다.
  `rm` 불가(권한 없음) — 지울 파일은 `_to_delete/`로 `mv`하거나 osascript로 지운다.
  파일 읽기·쓰기·grep·python3·PIL 정도가 쓸모다.
- `Control_your_Mac osascript` → **진짜 macOS 셸.** flutter 빌드, git 커밋/푸시, 시뮬레이터,
  App Store Connect 스크립트는 전부 여기로 돌린다.

### 2.3 osascript 함정 (여기서 제일 많이 깨졌다)

- `do shell script` 안에서 `&`(백그라운드), 따옴표, `#`, 히어독은 파싱이 깨진다("알 수 없는 토큰").
- **통하는 패턴**
  1. `device_bash`로 `.sh` 스크립트와 커밋 메시지 `_msg.txt`를 저장소에 먼저 쓴다
  2. osascript에서 `chmod +x`를 **다시** 한다 (device_bash의 chmod는 안 넘어온다)
  3. `nohup /절대경로/스크립트.sh > /tmp/x.log 2>&1 & echo started`
  4. `cat /tmp/x.log | tr '\n' '@' | sed 's/@/\n/g'` 로 폴링
- `grep -c`가 0을 반환하면 osascript가 `0 (1)` 오류처럼 보고한다. **성공(경고 0건)이지 실패가 아니다.**
- 맥의 `/usr/bin/python3`에는 `jwt` 모듈이 있고 `/opt/homebrew/bin/python3`에는 없다.
  App Store Connect 스크립트는 **반드시 `/usr/bin/python3`**.
- 시뮬레이터는 이 맥에 **iPhone 17 계열**이 깔려 있다. iPhone 16 Pro는 없다.

---

## 3. 지금까지 완성된 것

### 3.1 유료화(프리미엄) — 코드는 전부 완성. 스토어 제출만 남았다

`lib/core/purchase_gate.dart` — 상품 5종

- `premium.monthly` $2.99 / `premium.yearly` $19.99 — 기본 등급
- `premium.all.monthly` $3.99 / `premium.all.yearly` $29.99 — 모든 기기 등급
- `premium.lifetime` $39.99 — **비소모성(일시불).** ASC id `6805480790`
- 패밀리 `apple` / `google` / `web` / `other`. 유예 창 35일(월간) / 370일(연간).
  `Entitlement.merge`는 권한을 가진 쪽이 이긴다.

`lib/core/usage_gate.dart` — 무료 한도와 체험

- `kTrialActiveDays = 14` — **달력 날짜가 아니라 앱을 실제로 연 날 수**로 센다
- `kFreeTidyPerDay = 3`, `kFreeWizardPerDay = 2`
- UI는 반드시 `canUseNow()`를 통해 묻는다. 상수를 직접 비교하지 말 것

`kPaidTierLive`는 기본값 true — `const bool.fromEnvironment('PAID_TIER', defaultValue: true)`

프리미엄 화면(`_PremiumScreenState`, `lib/main.dart`)은 **마케팅 페이지**로 다시 썼다. 개발자용 설명서가 아니다.

- 그라디언트 히어로 배지 → '프리미엄 혜택' 카드(체크 아이콘 5줄) → 신뢰 카드 → 잠금 해제 헤드라인
  → 가격 카드(**고르기만 하고 결제는 안 한다**) → 하단 붙박이 CTA에 고른 가격이 박혀 나간다
- 등급 토글은 기본/모든 기기 pill
- '구매 복원'은 아이콘 붙은 눈에 띄는 버튼으로 **맨 위**에 있다
- 월 환산 가격은 `lib/core/money.dart`의 순수 함수가 만든다.
  통화 기호 위치와 소수점 유무를 **국가 목록이 아니라 스토어가 준 가격 문자열에서** 판단한다.
  나라 분기를 새로 넣지 말 것

진입 경로 세 개

1. 설정 화면 — '동기화' 그룹 **바로 아래** `_PremiumBanner`
   (그라디언트 카드, 흰 글씨, 46px 반투명 배지, 셰브런). 맨 아래 아니다
2. 광고 배너 닫기 → `lib/ads_service.dart`의 후원 시트.
   유료 빌드에서는 프리미엄 버튼이 1순위, '광고 보고 후원하기'는 그 아래 OutlinedButton
3. 무료 한도 소진 직전 — `_nudgeIfLast({required bool wizard})`가 남은 횟수 1일 때
   '프리미엄 보기' 액션이 달린 SnackBar를 띄운다

### 3.2 온보딩

- `OnboardingScreen` — 4페이지 PageView, 애니메이션 점 인디케이터, 건너뛰기,
  마지막 장에 '프리미엄 살펴보기'
- `Settings.onboardShown` — **기기 로컬 값**이고 동기화 대상이 아니다. toJson/fromJson에 들어 있다
- **ATT 충돌 주의.** iOS 추적 동의 프롬프트는 실행 약 1초 뒤 `AdsService.boot()`에서
  MobileAds 초기화보다 **먼저** 떠야 한다. 순서를 바꾸면 App Review에서 반려된다.
  그래서 온보딩은 `AdsService.instance.ready`(`ValueNotifier<bool>`)를 기다리고,
  최대 6초까지만 기다린 뒤 뜬다(`_showOnboard()`).
  이 대기 로직을 없애면 온보딩이 ATT 팝업에 가려진다 — 실제 시뮬레이터 스크린샷으로 확인된 사고다

### 3.3 정리 엔진 — 제목 두 단계

`lib/core/tidy_engine.dart`의 `_headingOut(..., {int level = 2})`

- 중간제목 → `##`(제목2), 소제목 → `###`(제목3)
- 소제목 위 2줄 / 아래 1줄 공백. 중간제목과 소제목이 나란히 오면 사이는 1줄
- `emitHeading` 안에 지역 함수 `looksHeading()`이 있고, 바로 위가 제목이면 위 여백을 1줄로 줄인다
- **테스트 함정**: `aiOpts()`는 `stripHeadings: true`다. 테스트에서 이걸 false로 덮으면
  `hm == 'keep'` 분기로 빠져 `_headingOut`을 아예 안 탄다. 규칙이 안 도는데 통과한 것처럼 보인다.
  반드시 `aiOpts().copyWith(headingBig: true, headingPad: true)` 형태로 쓸 것

### 3.4 문서 제목 입력

- 제목란에 포커스가 가면 자동 생성 제목이 지워진다(`_clearAutoTitleOnFocus()`).
  `_save()`는 `!_titleFocus.hasFocus`로 가드
- 제목란이 입력란처럼 보이도록 위에 작은 회색 라벨(`l.titleFieldLabel`)
  + OutlineInputBorder + filled TextField

### 3.5 설정 화면 배치

- 편집기 드로어의 '버전 기록'은 `정리방식 고르기 / 정리 미리보기 / 정리 전후보기` **바로 아래**
- 프리미엄 배너는 '동기화' 그룹 바로 아래

### 3.6 웹 (ezlong 저장소 — 이 계정에서는 커밋 불가, §2.1 참조)

- `/skybluenote/` — `#features` 앞에 `<section id="sync">` 추가.
  애플만 쓰면 iCloud, 안드로이드·웹까지 쓰면 구글 로그인, 둘 다 공짜라는 점이 핵심 소구.
  내비에 '동기화' 추가, FAQ에 동기화 문항 추가
- `/longtime/` — Long Time 소개 페이지 신설. 다크/라이트 토큰 + 골드 액센트 `--gold:#C9A227`.
  스크린샷은 세로가 늘어나지 않도록 높이를 고정해 뒀다

  ```css
  .duo .shot img{
    width:min(232px,56vw); height:min(38vh,352px);
    object-fit:cover; object-position:top center;
  }
  ```

  9:19.5 스크린샷을 폭만 지정하면 2.16배로 늘어난다. **이 높이 고정을 지우지 말 것**
- 루트 `index.html`, `ez-footer.js`, `sitemap.xml`의 앱 링크가 `/app/`에서
  `/longtime/`, `/skybluenote/`로 옮겨져 있다

---

## 4. 하다 만 것 — 정확한 현재 상태

### 4.1 App Store 1.5 심사 제출 (**막혀 있다. 최우선.**)

여기까지 됐다

- 빌드 222 업로드 완료, 상태 VALID
- 버전 1.5 생성 완료. `appStoreVersions` id `418dc745-ec6b-479e-988e-6e8366350ffd`
  (로그에는 숫자 id `890683371`도 나온다)
- 11개 로케일 릴리스 노트 입력 완료 (`store/ios/*/release_notes.txt`)
- 빌드 222 연결 완료
- **앱 상태 `READY_FOR_REVIEW` — 아직 안 냈다** (2026-09-05 `tool/review_status.py`로 확인)
- 인앱결제 5종 전부 `READY_TO_SUBMIT`
- 심사 제출함 `e1d4caa3-60c1-4e51-9f98-8e92a639aa86`가 열려 있고 항목 1개(버전)를 물고 있다.
  상태 READY_FOR_REVIEW, `submitted=None`

막힌 지점 — 409 두 개

1. `STATE_ERROR.FIRST_NON_CONSUMABLE_MUST_BE_SUBMITTED_ON_VERSION`
   "The first Non-Consumable In-App Purchase for this app must be submitted for review
   at the same time that you submit an app version."
   → 첫 비소모성 상품 `premium.lifetime`(ASC id `6805480790`)을
   **버전 1.5에 붙여서 같이** 내야 한다. 따로 못 낸다
2. 버전 항목을 다시 넣으면 `STATE_ERROR.ENTITY_STATE_INVALID` on `appStoreVersions id 890683371`.
   `associatedErrors`가 잘려서 원인 불명

시도해 본 것

- `reviewSubmissionItems`에 `inAppPurchaseV2` 관계로 붙이기 → 409 `ENTITY_ERROR.RELATIONSHIP.UNKNOWN`.
  그 리소스에 그런 관계가 없다
- 전용 엔드포인트 `/v1/inAppPurchaseSubmissions`, `/v1/subscriptionSubmissions`로 전환 → 위 1번 에러

**가장 확실한 우회로**: API로 계속 싸우지 말고, 소유자에게 App Store Connect의 1.5 버전 페이지에서
인앱결제 5종 체크박스를 직접 켜 달라고 부탁한 뒤 제출한다.
웹 UI 조작은 담당자가 대신 할 수 없다(§6 보안).

### 4.2 Google Play

- 비공개 테스터 1명 추가 요청이 들어와 있다. 안내문은 이미 써서 전달했고,
  **Play Console 테스터 목록에 실제로 넣는 일이 남았다.**
  브라우저 조작 권한이 읽기 전용이라 담당자가 클릭할 수 없다.
  소유자가 직접 넣거나 Play Developer API 경로를 찾아야 한다
- 프로덕션 승격 조건: 테스터 12명 × 연속 14일. **현재 0명.**
  이게 채워지기 전에는 안드로이드 정식 출시 불가

### 4.3 홍보글 마무리

- 미국주식 카페용 홍보글은 4차 수정까지 끝났다(저장소 밖, 대화 산출물)
- 안드로이드 테스터가 몇 명 더 필요한지 실제 숫자를 채워야 한다
- Gmail 주소를 DM으로 모으는 대신 Play 옵트인 URL을 쓰는 편이 낫다 — 제안만 해 둔 상태

### 4.4 제안만 하고 승인 안 난 것 (하지 말 것. 물어보고 할 것)

- 업데이트 후 뜨는 '새로워진 점' 다이얼로그 (버전별 릴리스 노트 기반)
- 설정에 '안내 다시 보기' 행 — 온보딩 재실행

---

## 5. 다음 사람이 할 일 — 순서대로

1. **환경 확인.** `mcp__remote-devices__get_device_info`로 연결 폴더가
   `/Users/ziririt/development`, `/Users/ziririt/Developer` 둘 다인지 본다.
   ezlong 작업이 필요하면 §2.1을 먼저 읽는다
2. **저장소 상태 확인.** `git status`, `git log --oneline -20`
3. **1.5 심사 제출 마무리** — §4.1대로.
   API로 `premium.lifetime`을 버전에 붙일 길이 있으면 붙이고
   `reviewSubmissions/e1d4caa3-60c1-4e51-9f98-8e92a639aa86`을 `submitted: true`로 PATCH.
   길이 없으면 소유자에게 App Store Connect 화면에서 인앱결제 5종을 켜 달라고 정확히 요청한 뒤 제출
4. **제출 후 상태 확인** — `/usr/bin/python3 tool/review_status.py`
5. **Play 비공개 테스터 추가** — 소유자에게 클릭을 요청하거나 API 경로 확보
6. **테스터 12명 모집 지원** — 홍보글의 남은 인원 숫자 채우기, Play 옵트인 URL 전환 제안
7. 승인 나면 §4.4의 옵션 항목을 소유자에게 물어보고 진행

---

## 6. 조심할 점 / 건드리면 안 되는 것

### 보안 — 예외 없음

- **ezlong 원격 URL에 GitHub 토큰이 평문으로 들어 있다.** `git remote -v`를 그대로 출력하지 말 것.
  push 출력은 항상 마스킹한다: `git push ... 2>&1 | sed -e 's#https://[^ ]*@#https://***@#g'`
- AI API 키 전체를 요청·출력·입력하지 않는다
- 구글 클라이언트 시크릿을 요구하거나 저장하지 않는다. 저장소가 공개라 PKCE를 쓴다
- `android/key.properties`의 키스토어 비밀번호를 출력하지 않는다.
  업로드 키스토어와 자격증명 txt는 **어디로도 복사하지 않는다**
- 스크립트 내용을 출력할 때 `-p` / `--password` / `apiKey` 값은 지운다
- Apple ID와 비밀번호 입력은 소유자만 한다
- ASC/OAuth 자격증명은 소유자 기기에서만 다룬다
- `admin.html` / `write.html`의 `ADMIN_EMAIL`, `ALLOWED_EMAIL`은 접근 제한 장치지 연락처가 아니다
- 소유자 화면을 허락 없이 캡처하지 않는다
- 맥 컴퓨터-유즈로 조작하는 크롬은 **읽기 전용 등급**이다.
  AppleScript·System Events·셸 등 어떤 방법으로도 클릭이나 키 입력을 우회 주입하지 않는다.
  (크롬 확장 기반 도구는 이 제한과 별개다)
- 소유자의 금융·계좌·세금 데이터를 대신 입력하지 않는다
- App Store 리뷰를 대신 써 주지 않는다
- iPhone 배포는 "물어보지 말고 넣어도 된다"로 지침이 바뀌어 있다. 매번 확인 요청하지 말 것

### 공개 저장소 위생

- `ziririt/simpletext-app`은 **PUBLIC**이다. 개인 신상·개인 사정을 새로 써 넣지 않는다
- ezlong 저장소에는 `scripts/check-privacy.py`라는 **배포 차단 가드**가 있다.
  개인 호칭, '유저 지시', '실책', '인정한다', '보수적', '놓쳤', '이 시스템은' 같은 말이 들어가면 배포가 막힌다.
  절대경로 `/icons/`, `/splash/` 참조에는 `?v=`가 붙어 있어야 한다

### 한국어 UI 규칙 (소유자가 직접 교정한 것)

- '판' 금지. 사람들은 **'버전'**이라고 한다. 예: '이 판으로' → '이 버전 복원하기'
- **'혼자 만드는 앱입니다' 류의 문장을 어디에도 쓰지 않는다.** 신뢰를 떨어뜨린다
- 이 노트 앱이 LLM을 쓰다가 나왔다는 서술을 대외 문안에 쓰지 않는다
- 프리미엄 화면은 **마케팅 문서**다. 기능 설명서처럼 쓰지 않는다
- 문장은 서술어 없이 명사로 끝맺되, 뜻이 안 통할 만큼 짧으면 안 된다. 소제목 + 닷불릿으로 구조화
- 대비를 낮추지 않는다. 흰 바탕 검은 글씨(다크모드는 반대). 폰트는 기본 크기 이상
- '윈도'라는 말을 쓰지 않는다(앱이 없다)
- 가격 카드는 고르기만, 결제는 하단 CTA 하나로
- 이모지·불릿 이미지 문자 사용 금지

### UI 설계 원칙 (2026-08-12 소유자 확정, 지금도 유효)

- **UI/UX 독자 설계 금지.** 애플 메모장·CotEditor 같은 유명 에디터의 관습을 그대로 따른다.
  차별화는 오직 기능(정리·표 엔진)으로 한다.
  새 화면을 발명하기 전에 "애플 메모장은 이걸 어떻게 하나"를 먼저 확인한다

### 기술적으로 깨지기 쉬운 곳

- **l10n**: 로케일 파일 9개(ko, en, ja, zh_hans, zh_hant, es, fr, de, pt).
  추상 `String get X;`를 추가하면 **`all` 맵과 9개 파일 전부**에 넣어야 한다.
  **파라미터가 있는 메서드는 `all` 맵 제외.** 현재 키 522개
- Dart 소스에 이스케이프된 `\n` 문자열을 그대로 쓰지 않는다
- 버전은 **두 군데**를 같이 올린다: `pubspec.yaml`의 `version:`, `lib/version.dart`의 `appVersion`·`appBuild`.
  어긋나면 `tool/version_check.py`가 CI에서 잡는다.
  **`appBuild`는 절대 내리지 않는다** — iOS는 빌드 번호가 오를 때만 `NSUbiquitousContainers`를 다시 읽는다
- ATT 순서 (§3.2). 건드리면 반려된다
- `tidy_engine` 테스트의 `stripHeadings` 함정 (§3.3)
- `asc.api()`는 json이 아니라 **튜플 `(status, json)`**을 반환한다. `.get()` 부르면 죽는다

---

## 7. 실행 방법

전부 **osascript(진짜 macOS 셸)** 로 돌린다. device_bash에서는 안 돈다.

```
tool/deploy.sh web        # 웹 빌드/배포
tool/deploy.sh mac
tool/deploy.sh android
tool/deploy.sh iphone

tool/appstore_ios.sh      # App Store용 iOS 빌드
                          # --dart-define=REAL_ADS=true 와
                          # ~/development/_patch/skyblue_keys.env 의 구글 클라이언트 id를 자동으로 붙인다

tool/screenshots.sh       # 스토어 스크린샷 촬영
tool/android_target.sh    # 안드로이드 타깃 확인

/usr/bin/python3 tool/submit_next.py            # 버전 준비
/usr/bin/python3 tool/submit_next.py --submit   # 심사 제출
/usr/bin/python3 tool/review_status.py          # 심사 상태 확인
```

스토어 스크립트는 반드시 `/usr/bin/python3`. 홈브루 파이썬에는 `jwt` 모듈이 없다.

---

## 8. 테스트 방법

```
tool/verify.sh
```

`l10n_check` → `version_check` → `store_check` → `analyze` → `test` 순으로 돈다.
**"전부 통과. 푸시해도 됩니다."** 가 나와야 푸시한다.

- `warning •` 하나만 있어도 analyze 단계에서 실패한다. `info •`는 통과
- 현재 테스트 920개
- `flutter analyze`·`flutter test`만으로는 부족하다. 이 저장소에는 언어 표준 도구가 보지 않는
  자기만의 검사기가 `tool/` 안에 따로 있고 CI도 그걸 본다.
  **처음 이 저장소에 손대는 세션은 `ls tool/`부터 볼 것.** 푸시가 끝이 아니라 CI 통과가 끝이다

| 검사기 | 무엇을 잡나 |
|---|---|
| `tool/l10n_check.py` | 추상 getter ↔ all 맵 ↔ 9개 언어 파일 불일치, 빈 값 |
| `tool/version_check.py` | pubspec.yaml ↔ lib/version.dart 버전 어긋남 |
| `tool/store_check.py` | 스토어 문구 누락·글자 수 초과·미번역 |
| `tool/screenshot_check.py` | 촬영 후 빠진 언어 (맥에서 촬영 뒤 수동 실행) |

- 새 기능에는 순수 함수를 분리해 단위 테스트를 붙이는 방식을 쓴다.
  예: `lib/core/money.dart` ↔ `test/core/money_test.dart`(9개),
  `test/core/tidy_engine_test.dart`의 제목 두 단계 그룹(5개)
- 버그는 재현 fixture를 테스트에 추가한 뒤 고친다(Fixture Driven)
- UI 변경은 시뮬레이터 실제 스크린샷으로 눈으로 확인한다. ATT·온보딩 충돌은 그렇게 잡았다

---

## 9. 커밋 규칙

- 커밋 메시지는 한국어 한 줄. 버전이 오르면 `3.17.0 — 무엇을 고쳤는지` 꼴
- osascript로 커밋할 때는 메시지를 `_msg.txt` 파일로 먼저 쓰고 `git commit -F _msg.txt`
  (따옴표 파싱 회피). 커밋 뒤 `_msg.txt`는 지운다
- 푸시 전 `tool/verify.sh` 통과 필수
- 푸시 출력은 토큰 마스킹 필수
- 밑줄로 시작하는 임시 스크립트(`_iap.py`, `_st.sh` 등)는 커밋하지 않는다. 다 쓰면 지운다
