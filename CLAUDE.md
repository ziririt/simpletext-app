# 심플텍스트 (SimpleText) — 프로젝트 컨텍스트

> 이 파일은 어떤 Claude 세션(웹/모바일/데스크톱)에서든 프로젝트 맥락을 이어받기 위한 문서다.
> 마지막 갱신: 2026-08-20 23:4x KST (개발 방법론 추가)

## 제품 정의

AI 답변(ChatGPT·Claude·Gemini·Grok 등)을 붙여넣으면 바로 저장·공유·스프레드시트 활용이 가능한
깨끗한 플레인 텍스트로 바꿔주는 미니멀 텍스트 앱. 일반 메모 앱과 경쟁하지 않는다.
핵심 흐름: **복사 → 붙여넣고 정리 → 미리보기 → 적용 → 복사**.
원 기획서: Tidynote v2.0 (67개 섹션). 소유자: 김성동(ziririt@gmail.com).

## 핵심 원칙 (기획서 요약)

1. **Local First** — 정리·표 복구·TSV 변환은 전부 온디바이스. AI는 옵션.
2. **Plain Text First** — 리치 텍스트 편집기 금지. 데이터는 항상 단순 String.
3. **Non-Destructive** — 모든 변환은 미리보기 → 적용, 되돌리기 1회로 복구.
4. **엔진이 제품이다** — Tidy Engine + Table Engine 품질이 최우선. UI는 그 다음.
5. **Fixture Driven** — 실제 AI 답변 fixture가 회귀 테스트 기준. 버그는 fixture부터.

## 저장소 구조

- `ziririt/simpletext-app` — Flutter 앱 (iOS/macOS/Windows 우선, Android는 나중)
  - `lib/core/tidy_engine.dart` — 정리 엔진 (Pure Dart, 플랫폼 API 금지)
  - `lib/core/wizard.dart` — AI 마법사 1층(자연어 규칙 명령 해석기) + NumberGuard
  - `lib/main.dart` — 앱 전체 UI (애플 메모장 스타일)
  - `test/core/tidy_engine_test.dart` — 엔진 테스트 60개 (기획서 Acceptance Test 포함)
  - `.github/workflows/windows_build.yml` — push마다 Windows 빌드 자동 생성(Artifacts)
- `ziririt/simpletext` — 웹앱(단일 index.html, GitHub Pages)
  - 배포 주소: https://ziririt.github.io/simpletext/
  - 같은 엔진의 JS 원본이 인라인으로 포함됨. Dart 엔진과 로직·테스트 동일 유지 필수.

## 검증 명령 — 이것부터 읽을 것

```
tool/verify.sh      # 푸시 전 이 한 줄이면 된다 (CI와 같은 순서)
```

**`flutter analyze`·`flutter test`만으로는 부족하다.** 이 저장소에는 언어 표준 도구가
보지 않는 자기만의 검사기가 `tool/` 안에 따로 있고, CI는 그것들도 본다.

| 검사기 | 무엇을 잡나 |
|---|---|
| `tool/l10n_check.py` | 추상 getter ↔ all 맵 ↔ 9개 언어 파일 불일치, 빈 값 |
| `tool/version_check.py` | pubspec.yaml ↔ lib/version.dart 버전 어긋남 |
| `tool/store_check.py` | 스토어 문구 누락·글자 수 초과·미번역 |
| `tool/screenshot_check.py` | 촬영 후 빠진 언어 (맥에서 촬영 뒤 수동 실행) |

2026-08-14에 세션 두 개가 나란히 같은 실수를 했다. analyze·test가 통과해서
끝난 줄 알고 푸시했는데 `l10n_check.py`가 CI에서 잡았다. **처음 이 저장소에
손대는 세션은 `ls tool/`부터 볼 것.** 그리고 푸시가 끝이 아니라 CI 통과가 끝이다.

## 엔진 파이프라인 (JS/Dart 동일)

개행 정규화 → 리터럴 \n 복구 → outer fence 제거 → 코드블록 보호 →
AI 서두 보수적 제거 → escape 복원 → 사용자 치환 규칙 → 출처([n]: URL) 제거 →
대시 나열 분리 → ㅤ소제목 여백(위2/아래1, 기존 여백 흡수) → 블록/인라인 정리 →
표 탐지·복구(mode 기반 열 수, 초과 셀 병합+경고) → 공백 정규화 → TidyReport

표 본문 출력은 **공백 정렬 텍스트**(세로 구분자 없음, 각 열 좌측 정렬, 헤더 아래 가로
구분선 ─). 한글·CJK·전각·이모지를 2칸으로 세는 `dispWidth`로 패딩해 등폭 글꼴에서 열이 맞는다.
파이프 마크다운은 표 도구의 'Markdown 복사'로만 남아 있다(`tableToMarkdown`).

## 사용자 설정 (AppSettings)

강조(기본 작은따옴표, 40자 초과는 제거만) · 구분선(기본 유지) · 제목(기본 텍스트만) ·
글머리(기본 "  - " = 하이픈+들여쓰기 2칸) · 소제목 여백(위2/아래1, ㅤ 투명문자) ·
출처 제거(기본 켬) · 자동 바꾸기 규칙(무제한) · AI 키/모델

## AI 마법사

- 1층: 규칙 명령을 로컬 해석 (여백 줄 수, 들여쓰기 칸 수, 글머리, 강조, 구분선, 출처, A를 B로 바꿔)
- 2층: 자유 편집 — BYOK. 지원: Gemini(2.5 Flash-Lite 기본/Flash), Claude(Haiku/Sonnet),
  ChatGPT(gpt-5-mini/gpt-5-nano), Grok(grok-4.1-fast). 결과는 미리보기 + NumberGuard(숫자 보존 검증) 후 적용.
- 시스템 규칙: 숫자·날짜·고유명사·URL 불변, 추가·삭제 금지, 입력 언어 유지, 본문만 반환.

## 현재 상태 (2026-08-12 오후)

- 웹 v1.7 배포됨 (마법사 포함)
- iPhone(Ziririt iPhone 16)·macOS(/Applications/심플텍스트.app) 설치됨 — 애플 메모장 스타일 UI
- Windows: GitHub Actions 자동 빌드 동작 중
- **i18n 완료 (클라우드 세션, 2026-08-12)**: UI 문자열 126키를 lib/l10n/으로 분리,
  9개 언어(한/영/일/중간체/중번체/스/포/독/프). gen-l10n 미사용 — 손으로 쓴 L10n 클래스 계층
  (키 누락 = 컴파일 오류). 검사: test/l10n/l10n_test.dart + tool/l10n_check.py(CI 연동)
- Flutter CI 신설(.github/workflows/flutter_ci.yml): push마다 analyze + test + l10n 검사
- **표 출력 형식 변경 (2026-08-12)**: 파이프 마크다운 → 공백 정렬 텍스트.
  웹(index.html)에 먼저 넣고 Dart에 동일 적용. AT01·AT03 기대값을 새 형식으로 갱신하고
  재현 fixture 7개 추가(그룹 '표 정렬 출력'). 사용자가 화면 확인 후 확정한 형식이다.
- **글로벌 출시 준비 (2026-08-12)**: 스토어 등록정보 11개 로케일(store/ios/, fastlane 구조)
  + tool/store_check.py CI 연동. 스크린샷 자동 촬영(tool/screenshots.sh, 11개 로케일 × 3장).
  es·pt는 스토어에서만 지역 분리(es-ES/es-MX, pt-BR/pt-PT).
- **표 왕복(round-trip) 보장 (2026-08-12)**: 공백 정렬 표를 다시 표로 인식하는
  detectAlignedBlocks/parseAlignedTable 추가. 메모는 글자만 저장하므로 표 도구는
  매번 본문을 재파싱한다 — 출력 형식을 바꾸면 탐지도 반드시 함께 바꿀 것.
- 이름 논의 중: "Blue AI Editor" 유력 (Blue Note 상표 충돌로 'Blue AI Note'는 보류)

## 다음 할 일 (우선순위)

1. ~~다국어(i18n) 준비~~ 완료 — 남은 후속: (a) 엔진 리포트 문구(summary/warnings) 현지화는
   JS·Dart 동시 작업 필요라 보류 중, (b) 마법사 1층 규칙 해석기는 한국어 명령 전용
   (비한국어는 AI 2층으로 처리됨), (c) 스토어 현지화 스크린샷(출시 전 필수 확인)
2. iOS Share Extension (ChatGPT 앱에서 공유 → 심플텍스트) — Xcode 네이티브 작업
3. ~~iOS TestFlight 클라우드 배포(CI) 구성~~ 워크플로 완료 — 소유자의 Secrets 6개 등록 대기
   (docs/testflight_setup.md). 등록 전에는 수동 실행·태그 푸시에만 반응하므로 CI를 붉게 만들지 않는다.
4. 백업 내보내기/가져오기 Flutter 이식 (웹과 같은 JSON 스키마 v2, 병합 규칙: id 기준·updatedAt 최신 승리·tombstone 우선)
5. 클라우드 동기화(iCloud/Google Drive) — 2차
6. ~~Android 빌드~~ APK 자동 빌드 완료(.github/workflows/android_build.yml, 시험 설치용).
   남은 것: 구글 플레이 출시용 키스토어 서명 — 소유자가 키를 만들어 Secret으로 넣는 단계

## 작업 규칙 (모든 세션 공통)

- 엔진 수정 시 반드시 JS(웹)와 Dart(앱) 양쪽에 동일 적용하고 양쪽 테스트를 통과시킬 것
- 엔진에 플랫폼 API 호출 금지 (Pure Dart 유지)
- 모든 변환은 비파괴(미리보기→적용) 원칙 유지
- 새 버그는 재현 fixture를 테스트에 먼저 추가한 뒤 수정
- **작업할 때마다 버전을 올린다 (소유자 요청 2026-08-12).** 올리기만 하면 소용없고
  화면에서 보여야 한다 — 앱은 설정 맨 아래, 웹도 설정 맨 아래에 `ver.0.1.1.1` 형식으로.
  고칠 곳 3군데: pubspec.yaml `version:`, lib/version.dart, 웹 index.html `APP_VERSION`
  (+ 웹은 sw.js 캐시 이름). 어긋나면 tool/version_check.py가 CI에서 잡는다.
  표기: ver.<major>.<minor>.<patch>.<build> — 앞 셋은 pubspec version, 끝은 빌드 번호.
- UI 문자열은 lib/l10n/에만 추가한다 — 하드코딩 금지, 9개 언어 전부 채울 것.
  (구 규칙 "UI 문구는 한국어"는 2026-08-12 i18n 완료로 대체됨 — 한국어 파일이 원문 기준)
- 새 언어 추가 시 손댈 곳: lib/l10n/ + ios·macos Info.plist CFBundleLocalizations +
  test/l10n/l10n_test.dart (tool/l10n_check.py 상단 체크리스트 참고)
- 애플 메모장 수준의 미니멀리즘 유지 (이모지 사용 금지)
- **UI/UX는 독자 설계하지 않는다 (2026-08-12 사용자 확정)** — 애플 메모장·CotEditor 등
  유명 에디터의 관습을 따른다. 차별화는 기능으로만 한다. 관습에 없는 화면·조작을
  추가하기 전에 그 에디터들이 같은 문제를 어떻게 푸는지 먼저 확인할 것.
- 클라우드 세션 주의: 컨테이너에서 pub.dev·storage.googleapis.com 차단 →
  flutter 명령 로컬 실행 불가. 검증은 Flutter CI(푸시 후 Actions 확인)로 한다


## 개발 방법론 — 실측으로 굳힌 규칙 (2026-08-20, Fable 5)

한 세션의 감상이 아니라, 이 저장소에서 실제로 세어 본 결과다. 같은
실수의 반복 횟수까지 인수인계서(docs/인수인계-2026-08-20.md §5·§10)에
있다. 아래 규칙과 어긋나는 방식으로 일하고 싶어지면 그 문서부터 읽어라.

### 1) 재라, 추측하지 마라

짐작으로 고친 것은 반복해서 틀렸고(소프트키 4번, 동기화 3번), 재고
고친 것은 전부 한 번에 맞았다(돋보기 좌표 실측, ColorScheme 덤프,
동기화 도장 타임라인). 구체적으로:

- **화면 말고 디스크를 읽어라.** "반영이 안 된다"는 신고 셋이 하룻밤에
  왔는데 셋 다 원인이 달랐고, 셋 다 화면이 아니라 저장소를 읽어서
  갈랐다. 맥 진단 명령:
  `plutil -convert xml1 -o - ~/Library/Containers/com.ziririt.simpletext/Data/Library/Preferences/com.ziririt.simpletext.plist`
- **도장(updatedAt·createdAt)으로 타임라인을 복원하라.** 2.2초 차이가
  사건 전체를 설명한 적이 있다(§10 신고 2).
- **추리가 갈리면 사실 하나를 물어라.** "정확히 무엇을 고쳤나" 한
  질문이 그럴듯한 오답 추리를 죽였다(§10 신고 1).

### 2) 판단은 순수 함수로 꺼내 시험으로 못 박고, 화면·IO는 그걸 따른다

이 저장소의 버그 수리는 대부분 이 꼴로 끝났다: core/에 순수 결정
함수(입력→결정, 플랫폼 API 금지) + 시험 선행, 그 다음 화면·전송
코드가 그 함수를 부른다. 실례: sync_plan.dart(pickFetch·shouldUpload·
editorRefresh), sync_merge.dart, auto_meta.dart, auto_tag_gate.dart.
새 동작을 넣을 때 "이 판단을 담을 함수는 어디인가"부터 정하라.

### 3) 한 결정을 두 곳에 쓰면 반드시 한 곳을 빠뜨린다

이 실수만 14번쯤 셌다. 고정 토글이 세 군데라면 함수 하나로 모아라
(_setPinned 사례). 문서·주석·UI 문구도 마찬가지다 — 사실이 바뀌면
문구도 바뀌어야 하고, 안 바뀌는 문구는 거짓말이 된다.

### 4) 시험이 통과해도 벌레를 지킬 수 있다

방 하나짜리 캐시 시험은 "방을 안 가리는 청소"를 통과시켰다(§9 둘째
범인). 시험을 쓸 때는 조건을 다양화하라: 방 두 개, 값 없음, 시각
동률, 깨진 JSON. 그리고 상수는 그 시점 조건의 산물이다 — 25초
타임아웃은 노트 몇 개일 때의 값이었고, 늘어나자 사이클을 중간에
죽였다.

### 5) 동기화 불변식 — 되돌리지 마라

- **모르면 안 올린다** (shouldUpload: remoteStamp를 모르면 false).
  되돌리면 남이 방금 고친 것을 이쪽의 옛것으로 덮는다.
- mergeNotes는 툼스톤 없이 삭제하지 않는다. 손대지 마라.
- 드라이브 딱지(appProperties.up)는 **media 성공 후에** 찍는다.
  순서를 바꾸면 "낡은 딱지는 스스로 낫지만 새 딱지는 거짓말한다".
- 바쁨 잠금은 시간이 아니라 **일이 끝날 때** 푼다. timeout은
  기다림만 끊지 일을 끊지 않는다.
- 편집 화면은 저장소 변화를 듣는다(editorRefresh). 치던 중이면
  눈앞의 글이 이긴다 — 보면서 만지는 글을 소리 없이 갈아치우지 않는다.

### 6) 원격(맥) 패치 작업 방식 — 클라우드 세션용

- 수정은 patch_NN.py로: 앵커 문자열의 **개수를 검증**하고 안 맞으면
  exit 1. 통째 덮어쓰기 금지.
- 파이썬 안의 Dart 문자열에서 **`$`를 이스케이프하지 마라** — `\$`는
  글자 그대로 달러가 되어 URL과 앵커를 조용히 망가뜨린다(실제 사고).
- osascript로 긴 작업 금지: `.sh` + `nohup … &` + 로그 폴링. 한국어
  출력은 `| iconv -f utf-8 -t utf-8 -c`. sleep 30초 이상은 끊길 수 있다.
- `git push` 출력은 반드시 `sed -e 's#https://[^ ]*@#https://***@#g'`로
  마스킹(ezlong 리모트에 토큰이 평문으로 있다). API 키·클라이언트
  시크릿·keystore 비번은 어떤 출력에도 싣지 않는다.
- 아이폰에는 소유자가 명시적으로 시킬 때만 설치한다(개발 설치가
  기기 자료를 지운 사고 있음). 안드로이드는 `adb install -r`라 안전.

### 7) 소유자와 일하기

- 소유자는 비개발자다. 보고는 화면에 보이는 말로 하되, 원인은
  얼버무리지 말고 구조로 설명하라 — 이해하고 나면 더 정확한 신고가
  돌아온다(오늘 신고 셋이 전부 재현 가능한 수준으로 정확했다).
- 소유자에게 보여주는 시각은 **반드시 실측**(`TZ=Asia/Seoul date`).
  어림으로 적다가 두 번 걸렸고, 세 번째도 걸렸다.
- 같은 문제를 3번 이상 다시 신고받으면 접근 자체가 틀린 것이다.
  짐작 수리를 멈추고 1)로 돌아가라.

### 8) 문서도 코드처럼 다룬다 (2026-08-24 소유자 지시)

- CLAUDE.md·인수인계서·스토어 문구 같은 프로젝트 문서를 고칠 때도
  코드와 같은 규칙을 지킨다: 앵커 개수를 검증하는 patch_NN.py로 고치고,
  덧붙임에는 날짜를 적고, 고친 뒤 커밋·푸시까지가 한 작업이다.
- 원본은 저장소다. 콘솔·채팅에만 있는 문구는 원본이 아니다 — 저장소를
  고쳐서 API·배포로 밀어낸다(스토어 문구가 그 예).
- 문서에도 비밀값은 적지 않는다. 위치만 가리킨다.

## 빌드는 반드시 키를 싣는다 (2026-08-25 사고)

- **어떤 판이든** flutter build (web·ipa·macos·apk·appbundle) 는
  `~/development/_patch/skyblue_keys.env` 를 source 해서
  `--dart-define=GOOGLE_WEB_CLIENT_ID=... --dart-define=GOOGLE_IOS_CLIENT_ID=...`
  를 붙여 짓는다. tool/deploy.sh 의 DEFINES 블록이 원형이다.
- 키 없이 지으면 **빌드는 성공하고 구글 로그인만 조용히 죽는다.**
  DriveAuth.supported 가 거짓이 되어 설정에서 동기화 메뉴가 통째로
  사라지거나, 켜져 있던 기기는 토큰이 만료되는 순간부터 조용히 멎는다.
- 실제 사고: 8/24~25 맨손 빌드(web74·mac74/75/76·ipa5/ipa6)가 웹·맥·
  아이폰에 동시 배포되어 "다 성공이라는데 안 맞는" 하루짜리 수사가
  됐고, 스토어 1.2와 심사 중이던 1.3(164)까지 오염 — 165로 교체 재제출.
- 검증법: 웹은 grep -c googleusercontent build/web/main.dart.js 가 1 이상.
  애플 AOT 바이너리는 문자열 검색이 안 통하므로(압축) **기능으로 확인**
  — 시크릿 창/새 기기에서 설정에 '구글 드라이브'가 보이면 실린 것이다.

## 광고 스위치 — REAL_ADS (2026-08-26 발견)

- 광고 단위는 `--dart-define=REAL_ADS=true` 를 실어야 진짜(AdMob)로
  바뀐다(lib/ads_service.dart). 여태 **어느 판도 이 스위치를 안 실었다** —
  스토어 1.0~1.3까지 전부 구글 테스트 광고가 나가고 있었고 수익은 0이다.
- 규칙: **스토어 제출용 빌드(ipa·appbundle)에만** REAL_ADS=true 를 싣는다.
  개발자 기기 설치판은 테스트 광고를 유지한다 — 자기 광고를 스스로
  누르면 애드몹 계정이 정지된다.
- 켜기 전에 애드몹 콘솔에서 앱 승인 상태를 먼저 확인한다.

