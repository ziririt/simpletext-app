# 심플텍스트(SimpleText) 개발 인수인계서

작성: 2026-08-12 11:40 KST · 작성 주체: 맥 코워크 세션 (2026-08-11~12 밤샘 개발)
소유자: 김성동 (GitHub: ziririt / ziririt@gmail.com)
이 문서는 어떤 Claude 세션(아이폰 코워크, 클라우드 코드 세션, 맥 코워크)이든
이 프로젝트를 즉시 이어받을 수 있도록 쓰였다. 요약 버전은 저장소의 CLAUDE.md 참고.

---

## 1. 제품 정체성 (반드시 유지할 것)

AI 답변(ChatGPT·Claude·Gemini·Grok·Perplexity)을 붙여넣으면 바로 쓸 수 있는
깨끗한 플레인 텍스트로 바꿔주는 앱. 원 기획서는 "Tidynote v2.0"(67개 섹션).

- 일반 메모 앱·노션과 경쟁하지 않는다. 핵심은 정리 엔진과 표 엔진.
- Local First: 정리·표 복구·TSV는 온디바이스. AI는 옵션(BYOK).
- Plain Text First: 리치 텍스트 편집기 금지. 데이터는 항상 String.
- Non-Destructive: 변환은 미리보기→적용, 되돌리기 1회로 복구.
- Fixture Driven: 버그는 재현 fixture를 테스트에 추가한 뒤 고친다.
- UI는 애플 아이폰 메모장 벤치마킹(미니멀·고급). 이모지 사용 금지.
- **UI/UX 독자 설계 금지 (2026-08-12 사용자 확정).** 애플 메모장·CotEditor 같은
  유명 에디터의 관습을 최대한 그대로 따른다. 차별화는 오직 기능(정리·표 엔진)으로 한다.
  새 화면·새 조작 방식을 발명하기 전에 "애플 메모장이나 CotEditor는 이걸 어떻게 하나"를
  먼저 확인할 것. 관습에 없는 UI는 기본적으로 반대 근거가 있는 것으로 본다.

## 2. 자산 위치

| 자산 | 위치 |
|---|---|
| Flutter 앱 저장소 | github.com/ziririt/simpletext-app |
| 웹앱 저장소 | github.com/ziririt/simpletext |
| 웹앱 배포 주소 | https://ziririt.github.io/simpletext/ |
| 맥 로컬 작업본 | ~/development/simpletext_app (git, main 브랜치) |
| Flutter SDK | ~/development/flutter (PATH 등록됨: .zshrc, .zprofile) |
| 맥 설치본 | /Applications/심플텍스트.app |
| 아이폰 설치본 | Ziririt iPhone 16 (무선, 기기ID 00008140-000C11100113001C), 번들ID com.ziririt.simpletext |
| Windows 빌드 | simpletext-app 저장소 Actions → 최신 실행 → Artifacts "simpletext-windows" |

## 3. 개발 환경 상태 (2026-08-12 기준, 전부 준비 완료)

- flutter doctor 통과 (3.44.9 stable, Xcode 26.6, Android SDK 라이선스 승인, CocoaPods)
- Apple 서명: "Apple Development"·"Apple Distribution" 인증서 유효. 팀ID ZK846VZN92
  (iOS 프로젝트에 DEVELOPMENT_TEAM 설정 완료 — flutter run만으로 실기기 설치 가능)
- GitHub: gh CLI가 ziririt로 인증됨(repo 권한) → git push 가능.
  Claude GitHub App은 "모든 저장소 접근"으로 설치되어 있어 클라우드 코드 세션도 접근 가능
- Apple 개발자 계정(유료)·Google Play 계정 보유 → 스토어 제출 자격 완비

## 4. 빌드·설치·배포 절차

맥에서 (새 터미널이면 flutter가 PATH에 있음):

```
cd ~/development/simpletext_app
flutter test                                # 엔진 테스트 55개 — 항상 먼저
flutter analyze --no-fatal-infos            # 경고 0 유지

# 아이폰 설치 (폰 잠금 해제 필수! 잠기면 Install failed)
flutter run --release -d 00008140-000C11100113001C
# 설치 후 프로세스는 q 또는 pkill -f "flutter run"으로 종료해도 앱은 남는다

# 맥 설치
flutter build macos --release
rm -rf "/Applications/심플텍스트.app"
cp -R build/macos/Build/Products/Release/simpletext.app "/Applications/심플텍스트.app"

# Windows: git push하면 GitHub Actions가 자동 빌드 (workflow: .github/workflows/windows_build.yml)
```

웹앱(simpletext 저장소) 갱신: index.html 단일 파일. 로컬 clone 후 수정→push가 정석.
(참고: 밤샘 세션은 제약 때문에 브라우저+클립보드로 커밋했지만, 일반 세션은 git으로 하면 된다.
 주의: 서비스워커가 있으나 network-first라 배포 후 앱 재실행이면 갱신됨)

## 5. 코드 맵 (simpletext-app)

- lib/core/tidy_engine.dart — 정리+표 엔진. Pure Dart, 플랫폼 API 호출 금지
- lib/core/wizard.dart — AI 마법사 1층(자연어 규칙 해석기) + numberGuard
- lib/l10n/ — 다국어. l10n.dart(추상 L10n + 로케일 해석 + all 맵) + 언어별 9파일.
  UI 문자열은 반드시 여기에만 추가(9개 언어 전부). 검사: tool/l10n_check.py, test/l10n/
- lib/main.dart — 전체 UI: Store(shared_preferences, 스키마 v2 {v,notes,tombstones}),
  HomeScreen(큰제목·그룹리스트·스와이프 고정/삭제), EditorScreen(제목 본문통합·키보드
  액세서리바·완료버튼·출처/태그 숨김토글·마법사/표/바꾸기/복사/되돌리기), PreviewScreen,
  SettingsScreen(정리 규칙 + AI 키/모델 + 자동 바꾸기 규칙)
- test/core/tidy_engine_test.dart — 55개. 기획서 Acceptance Test 01~04 + 사용자 브리핑 fixture
  + 표 정렬 출력 fixture(2026-08-12) 포함
- 웹(simpletext/index.html)은 같은 엔진의 JS 원본 포함. **엔진 수정 시 반드시 양쪽(JS·Dart) 동일
  적용 + 양쪽 테스트 통과**가 제1규칙 (웹 테스트: 저장소엔 없음, 로직 대칭만 유지하면 됨)

## 6. 확정된 제품 결정 (사용자 확정 사항 — 임의 변경 금지)

- 글머리: 하이픈 "-" + 들여쓰기 2칸 → 출력 "  - 항목". 원본 들여쓰기는 무시(누적 금지)
- 소제목 여백: 위 2줄·아래 1줄, 스페이서는 투명문자 ㅤ(U+3164, 카톡에서 안 뭉개짐).
  원본에 이미 있던 여백 줄은 흡수(두 배 금지). 소제목 처리는 제목 규칙과 연동
- 굵은 강조: 기본 작은따옴표 '강조'. 40자 초과 문장 전체 강조는 마커만 제거
- 구분선(---): 기본 유지 / 제목(#): 기본 텍스트만 / 출처([n]: URL 블록+본문 [n]): 기본 제거
- 대시 나열("– a – b – c"): 줄 목록으로 분리, 라벨(예: "테슬라 – …")은 라벨 줄로 유지
- 기능명: 치환 아님 "바꾸기(Replace)", 저장 규칙은 "자동 바꾸기 규칙". 실행 버튼 "모두 바꾸기"
- AI 마법사: 1층(규칙 명령, 무료 로컬) + 2층(자유 편집, BYOK). 시스템 규칙: 숫자·날짜·고유명사·
  URL 불변, 무단 추가·삭제 금지, 결과 본문만. 적용 전 미리보기+NumberGuard
- AI 모델: Gemini 2.5 Flash-Lite(기본)/Flash, Claude Haiku/Sonnet, GPT-5 Mini/Nano, Grok 4.1 Fast.
  키는 기기에만 저장. 이유: Flash-Lite가 비용 최저+무료티어, DeepSeek류는 프라이버시로 기본 배제
- 플랫폼 우선순위: 아이폰 → 맥 → 윈도우 → (나중) 안드로이드
- 이름: 미확정. "Blue AI Editor" 유력 ("Blue AI Note"는 Blue Note Records·BLUENOTE AI 상표
  인접으로 보류. Mint/Pearl/Cherry/Swan/Tidynote 등은 사용자가 기각). 상표는 사용자가 직접 출원 예정

## 7. 진행 상태 (완료된 것)

- 웹앱 v1.7 배포 (전 기능 + 마법사 + PWA 홈화면 설치)
- Flutter 앱: 엔진 이식(테스트 37개 전부 통과), 애플 메모장 스타일 UI, 마법사(1·2층, 4사),
  바꾸기, 표 도구, 키보드 액세서리 바 — 아이폰·맥 설치 완료
- Windows CI 자동 빌드 동작
- CLAUDE.md(요약 컨텍스트) 저장소에 존재
- **표 출력 형식 변경 — 2026-08-12 클라우드 세션.** 표 본문 출력이 파이프 마크다운에서
  공백 정렬 텍스트로 바뀌었다(세로 구분자 없음, 각 열 좌측 정렬, 헤더 아래 가로 구분선 ─).
  한글·CJK·전각·이모지를 2칸으로 세는 dispWidth로 패딩한다. 웹 index.html에 먼저 적용 후
  Dart 동일 적용. AT01·AT03 기대값을 새 형식으로 갱신, 재현 fixture 7개 추가.
  파이프 마크다운은 표 도구 'Markdown 복사'(tableToMarkdown)로만 남아 있다.
- **다국어(i18n) — 2026-08-12 클라우드 세션에서 완료.** UI 문자열 126키 분리, 9개 언어
  (한/영/일/중간체/중번체/스/포/독/프 — 사용자 확정: 중국어만 간·번체 분리, es·pt는 단일).
  구조: lib/l10n/의 손으로 쓴 L10n 클래스 계층(gen-l10n 미사용 — 키 누락이 컴파일 오류로 잡힘).
  기능명 용어집은 test/l10n/l10n_test.dart에 고정(바꾸기=Replace·置換·替换·取代·Reemplazar·
  Substituir·Ersetzen·Remplacer). 검사 도구 tool/l10n_check.py(빈 값·all맵 누락·미번역 의심).
  시드 메모·프리셋 이름도 현지화(프리셋은 Preset.id를 UI층에서 매핑, 엔진 무수정).
- **Flutter CI 신설**(.github/workflows/flutter_ci.yml): 모든 push/PR에서
  l10n 검사 + flutter analyze + flutter test. 클라우드 세션의 공식 검증 루프.

## 8. 로드맵 (다음 할 일 순서)

1. ~~**다국어(i18n)**~~ 완료 (7절 참고). 남은 후속 3건:
   (a) 엔진 리포트 문구(summary/warnings — '변경 사항 없음' 등) 현지화: JS·Dart 동시 작업
   필요(5절 제1규칙)라 별도 항목으로 보류. 리포트를 구조화(코드+파라미터)해서 UI층에서
   번역하는 방식 권장.
   (b) 마법사 1층(규칙 해석기)은 한국어 명령 전용 — 비한국어 사용자는 AI 2층으로 우회 가능.
   (c) 스토어 등록정보 현지화 스크린샷 — 노하우 문서 6절: 없으면 기본 언어 것이 그대로 나간다.
2. **iOS Share Extension**: ChatGPT 앱 공유 → 심플텍스트 (기획서 45절 모바일 킬러 기능. Xcode 네이티브)
3. ~~**TestFlight CI**~~ 워크플로 작성 완료(.github/workflows/ios_testflight.yml).
   **남은 것은 소유자만 할 수 있는 일** — GitHub Secrets 6개 등록(애플 API 키·배포 인증서·
   프로비저닝 프로파일). 클릭 순서는 docs/testflight_setup.md에 적어 뒀다.
   등록 전까지 이 워크플로는 자동으로 돌지 않는다(수동 실행·태그 푸시에만 반응).
4. **백업 내보내기/가져오기 Flutter 이식**: 웹과 동일 JSON 스키마 v2. 병합 규칙 = id 기준,
   updatedAt 최신 승리, tombstone(삭제 기록) 우선·부활 금지 — 이것이 향후 동기화 알고리즘
5. **클라우드 동기화**(iCloud Documents / Google Drive appDataFolder) — 위 병합 규칙 재사용
6. 데스크톱 글로벌 단축키·메뉴바(기획서 46~47절), 수익화(RevenueCat, 기획서 32~34절)
7. 안드로이드 — APK 자동 빌드는 완료(시험 설치용, 개발 서명).
   플레이 출시용 키스토어 서명은 소유자가 키를 만든 뒤 붙이면 된다.

## 9. 알려진 함정 (시간 아끼는 지식)

- **클라우드 세션 컨테이너는 pub.dev와 storage.googleapis.com이 막혀 있다** (2026-08-12 확인).
  Flutter SDK 설치도 pub get도 안 된다. 코드는 쓸 수 있으니, 검증은 푸시 → Flutter CI
  (Actions) 결과 확인으로 한다. GitHub 읽기는 되고, 푸시는 저장소가 세션 소스로
  연결됐을 때만 된다(안 되면 git bundle을 만들어 사용자에게 전달 → 맥에서 push).
- pubspec.lock은 flutter_localizations 추가(2026-08-12) 후 갱신이 필요할 수 있다 —
  맥에서 flutter pub get 후 lock 변경이 있으면 함께 커밋할 것.
- 아이폰 설치는 폰이 잠겨 있으면 "Install failed" — 잠금 해제 후 재시도하면 됨
- flutter analyze는 warning도 실패 처리 — 미사용 코드 남기지 말 것
- macOS 앱에서 외부 API 호출하려면 Release.entitlements에 com.apple.security.network.client 필요(적용됨)
- 웹앱 사용자에게 구버전이 보이면: PWA 완전 종료 후 재실행(네트워크 우선이라 그러면 갱신됨)
- 표 안 파이프(\|), 코드블록 보호, 서두 오탐 방지(확신도 낮으면 보존) 등은 테스트가 지키고 있음 —
  테스트를 깨뜨리는 "개선"은 하지 말 것
- 표 정렬은 문자 수가 아니라 **표시폭**으로 패딩해야 한다. '마이크로소프트'(7자·14칸)와
  '애플'(2자·4칸)을 문자 수로 맞추면 등폭 글꼴에서 열이 어긋난다. dispWidth를 쓸 것.
  (테스트 '한글 폭 2칸 계산으로 열 시작 위치가 모든 줄에서 같다'가 이걸 지킨다)
- 표 출력 형식은 사용자가 화면을 보고 확정한 것이다(2026-08-12). 파이프 마크다운으로
  되돌리지 말 것 — AT01·AT03 기대값도 그 형식에 맞춰 갱신되어 있다.
- **엔진이 만든 형식은 엔진이 되읽을 수 있어야 한다.** 2026-08-12에 표 출력만 공백 정렬로
  바꾸고 탐지(detectTableBlocks)를 안 고쳐서, "정리" 직후 표 도구가 표를 못 찾아
  '스프레드시트용 복사'가 끊긴 채로 웹에 배포됐다. 메모는 글자만 저장되고 표 구조는
  저장되지 않는다 — 표는 매번 본문을 다시 파싱해서 찾는다. 그래서 출력 형식을 바꾸면
  반드시 탐지·파싱도 같이 바꾸고, "원본 → 정리 → 되읽기 TSV 일치" 테스트를 걸 것.
  (테스트 '정리한 표를 다시 표로 읽어낸다'가 이걸 지킨다)
- 기획서 62절: 노션 경쟁 기능(폴더·협업·웹클리퍼·PDF 등) 추가 금지

## 10. 코워크/코드 세션 시작 지시문 예시

아이폰 코워크 새 작업("내 맥에서 실행" 선택) 또는 클라우드 코드 세션에서:

- "~/development/simpletext_app의 HANDOVER.md와 CLAUDE.md를 읽고 로드맵 1번(i18n)을 진행해.
  끝나면 flutter test 통과 확인하고 커밋·푸시해."
- "simpletext-app 저장소에서 로드맵 3번 TestFlight CI를 구성해줘."
- (맥에서 실행 시) "빌드해서 아이폰에 설치까지 해줘. 폰은 잠금 해제해 둘게."

작업 완료 시 이 문서의 7·8절과 CLAUDE.md의 '현재 상태'를 갱신해서 커밋할 것.
