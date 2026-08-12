# 심플텍스트 (SimpleText) — 프로젝트 컨텍스트

> 이 파일은 어떤 Claude 세션(웹/모바일/데스크톱)에서든 프로젝트 맥락을 이어받기 위한 문서다.
> 마지막 갱신: 2026-08-12 07:25 KST

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
  - `test/core/tidy_engine_test.dart` — 엔진 테스트 37개 (기획서 Acceptance Test 포함)
  - `.github/workflows/windows_build.yml` — push마다 Windows 빌드 자동 생성(Artifacts)
- `ziririt/simpletext` — 웹앱(단일 index.html, GitHub Pages)
  - 배포 주소: https://ziririt.github.io/simpletext/
  - 같은 엔진의 JS 원본이 인라인으로 포함됨. Dart 엔진과 로직·테스트 동일 유지 필수.

## 검증 명령

```
flutter test        # 엔진 37개 테스트 — 전부 통과해야 함
flutter analyze     # 경고 0 유지 (info 수준은 허용)
```

## 엔진 파이프라인 (JS/Dart 동일)

개행 정규화 → 리터럴 \n 복구 → outer fence 제거 → 코드블록 보호 →
AI 서두 보수적 제거 → escape 복원 → 사용자 치환 규칙 → 출처([n]: URL) 제거 →
대시 나열 분리 → ㅤ소제목 여백(위2/아래1, 기존 여백 흡수) → 블록/인라인 정리 →
표 탐지·복구(mode 기반 열 수, 초과 셀 병합+경고) → 공백 정규화 → TidyReport

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
- 이름 논의 중: "Blue AI Editor" 유력 (Blue Note 상표 충돌로 'Blue AI Note'는 보류)

## 다음 할 일 (우선순위)

1. ~~다국어(i18n) 준비~~ 완료 — 남은 후속: (a) 엔진 리포트 문구(summary/warnings) 현지화는
   JS·Dart 동시 작업 필요라 보류 중, (b) 마법사 1층 규칙 해석기는 한국어 명령 전용
   (비한국어는 AI 2층으로 처리됨), (c) 스토어 현지화 스크린샷(출시 전 필수 확인)
2. iOS Share Extension (ChatGPT 앱에서 공유 → 심플텍스트) — Xcode 네이티브 작업
3. iOS TestFlight 클라우드 배포(CI) 구성
4. 백업 내보내기/가져오기 Flutter 이식 (웹과 같은 JSON 스키마 v2, 병합 규칙: id 기준·updatedAt 최신 승리·tombstone 우선)
5. 클라우드 동기화(iCloud/Google Drive) — 2차
6. Android 빌드 — 나중

## 작업 규칙 (모든 세션 공통)

- 엔진 수정 시 반드시 JS(웹)와 Dart(앱) 양쪽에 동일 적용하고 양쪽 테스트를 통과시킬 것
- 엔진에 플랫폼 API 호출 금지 (Pure Dart 유지)
- 모든 변환은 비파괴(미리보기→적용) 원칙 유지
- 새 버그는 재현 fixture를 테스트에 먼저 추가한 뒤 수정
- UI 문자열은 lib/l10n/에만 추가한다 — 하드코딩 금지, 9개 언어 전부 채울 것.
  (구 규칙 "UI 문구는 한국어"는 2026-08-12 i18n 완료로 대체됨 — 한국어 파일이 원문 기준)
- 새 언어 추가 시 손댈 곳: lib/l10n/ + ios·macos Info.plist CFBundleLocalizations +
  test/l10n/l10n_test.dart (tool/l10n_check.py 상단 체크리스트 참고)
- 애플 메모장 수준의 미니멀리즘 유지 (이모지 사용 금지)
- 클라우드 세션 주의: 컨테이너에서 pub.dev·storage.googleapis.com 차단 →
  flutter 명령 로컬 실행 불가. 검증은 Flutter CI(푸시 후 Actions 확인)로 한다
