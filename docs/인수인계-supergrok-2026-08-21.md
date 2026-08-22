# Skyblue Note 개발 인수인계서 — 다음 개발 파트너에게

> 2026-08-21, Claude(Fable 5)가 씀. 소유자 김성동(ziririt@gmail.com)의 지시로,
> 이 프로젝트를 이어받을 AI 개발 파트너(SuperGrok Heavy 등)를 위해 남긴다.
> 이 문서 하나로 시작할 수 있게 썼지만, 저장소의 `CLAUDE.md`(방법론·규칙)와
> `docs/인수인계-2026-08-20.md`(동기화 대수술의 전말)를 반드시 이어 읽어라.

---

## 1. 세 줄 요약

- **Skyblue Note(심플텍스트)**: AI 답변을 붙여넣으면 깨끗한 플레인 텍스트로
  정리해 주는 미니멀 노트 앱. Flutter 한 몸으로 iOS·iPadOS·macOS·Android·
  Windows·Web을 낸다. 현재 2.6.5, 시험 622개, 앱스토어 첫 심사 대응 중.
- 소유자는 **비개발자 1인 기획자**다. 코드는 전부 AI가 쓰고, 소유자는
  실기기 테스트·방향 결정·스토어 콘솔 조작을 맡는다.
- 이 저장소에서 이긴 방법은 늘 같았다: **재고(측정), 판단을 순수 함수로
  꺼내고, 시험을 먼저 쓰고, 모르면 소유자에게 사실 하나를 물어라.**

## 2. 소유자와 일하는 법 (지휘 성향 — 실제 겪은 대로)

- 한국어로 대화한다. 답변 서두·말미에 서울 시각을 `2026-08-21(금) 10:41`
  꼴로 찍는다. **시각은 반드시 실측**(`TZ=Asia/Seoul date`) — 어림으로
  적다가 세 번 걸렸다.
- 이모지·불릿 이미지 금지. 요약에 표 금지(복사하면 깨진다) — 닷불릿 문장.
- 지시가 짧고 명확하다("빼라", "바꾸자", "지금 해라"). 실기기 테스트를
  꼼꼼히 하고 스크린샷과 함께 정확하게 신고한다. 같은 문제를 3~4번
  다시 신고받으면 접근 자체가 틀린 것이다 — 짐작 수리를 멈추고 재라.
- 비개발자지만 원인을 구조로 설명하면 이해하고, 다음 신고가 더 정확해진다.
  전문용어를 피하고 "도장(updatedAt)", "방(디렉터리)", "딱지(태그)" 같은
  살아 있는 말로 설명해 온 것이 잘 통했다.
- 제품 감각이 좋다. "일반 이용자의 이용 흐름에서 벗어난다"는 지적으로
  기능 설계가 여러 번 바로잡혔다. UI/UX는 독자 설계하지 않는다는 원칙
  (애플 메모장 등 관습을 따른다)을 소유자가 직접 정했다.
- 완료 보고는 짧게, 원인 분석은 충분히. 긴 작업은 중간 보고를 넣는다.
- 결정이 갈리는 지점(제품 방향, 돈이 드는 일, 되돌리기 힘든 일)은
  반드시 선택지를 만들어 묻는다. 소유자는 빨리 답한다.

## 3. 저장소·인프라 전모

### 앱 저장소 (핵심)
- GitHub: `ziririt/simpletext-app` — **공개(public)** 저장소, 브랜치 `main`.
- 로컬(소유자 맥): `~/development/simpletext_app`.
- Flutter 3.44.x / Dart 3. 앱 이름은 Skyblue Note, 번들 id
  `com.ziririt.simpletext`.
- **공개 저장소이므로 비밀값(클라이언트 시크릿·토큰·비번)을 절대 커밋하지
  마라.** 구글 OAuth는 PKCE(시크릿 없음)로 짜여 있다 — 그대로 둘 것.

### 웹앱 호스팅
- 웹 빌드 산출물은 별도 저장소 `ziririt/ezlong` (로컬 `~/Developer/ezlong`)의
  `skybluenote/web/` 폴더로 rsync된다(`tool/deploy.sh web`).
- ezlong 저장소에 커밋·푸시하면 **Firebase Hosting이 자동 배포**한다.
  주소: https://ezlong.com/skybluenote/web/ (버전 확인:
  `curl -s https://ezlong.com/skybluenote/web/version.json`).
- **주의**: ezlong 로컬 저장소의 git 리모트 URL에 GitHub 토큰이 평문으로
  박혀 있다. `git push` 출력은 반드시
  `| sed -e 's#https://[^ ]*@#https://***@#g'` 로 가려서 다뤄라.
  `git remote -v`를 가공 없이 출력하지 마라.
- ezlong에는 노트앱 외의 사이트(게시판 등)도 산다. `admin.html`·
  `write.html` 등의 `ADMIN_EMAIL`/`ALLOWED_EMAIL`은 자물쇠지 연락처가
  아니다 — 건드리지 마라.

### CI (GitHub Actions, 앱 저장소)
- `flutter_ci.yml` — push마다 verify와 같은 검사. **푸시가 끝이 아니라
  CI 통과가 끝이다.**
- `ios_testflight.yml` — 손으로 실행(workflow_dispatch)하거나 `v*` 태그를
  푸시할 때만 돈다. 애플 서버로 빌드를 올려 TestFlight에 꽂는다.
  빌드 번호는 CI 실행 번호로 덮어쓴다. 필요한 GitHub Secrets 6개와
  만드는 법은 `docs/testflight_setup.md`.
- `android_build.yml`, `windows_build.yml` — 산출물 빌드.

### 스토어·콘솔
- App Store Connect: 앱 Skyblue Note 1.0, 2026-08-21 첫 심사 **거절**
  (지침 5 중국/ChatGPT 메타데이터, 지침 3.1.1 API 키 언락). 대응은
  §8 참조. 콘솔 조작(이용 가능성, 빌드 선택, 재제출, 리졸루션 센터
  회신)은 소유자가 클릭한다.
- Google Play Console: 등록 진행 중. 스토어 문구는 `store/` 폴더에서
  관리하고 `tool/store_check.py`가 검사한다.
- Google Cloud Console: OAuth 클라이언트(웹·iOS·안드로이드), scope는
  `drive.appdata` 하나(비민감 — CASA 불요). OAuth 동의 화면은 프로덕션
  게시 완료(테스트 모드였다면 리프레시 토큰이 7일 만에 죽는다 — 이미
  겪고 고쳤다).

### 소유자 기기
- 맥(개발기, 앱 상시 실행), 아이폰, 아이패드(오래 잠들어 1.9.2),
  안드로이드폰(무선 adb — IP가 바뀌면 mDNS `_adb-tls-connect._tcp`로
  찾는다. `tool/android_target.sh`. **adb kill-server 하지 마라** —
  경쟁 서버와 충돌한 전력), 윈도우 노트북(가끔).
- **아이폰에는 소유자가 명시적으로 시킬 때만 설치한다.** 개발 설치가
  기기 자료를 지운 사고가 있다. 안드로이드는 `adb install -r`라 안전.

### 원격 작업 방식 (AI가 컨테이너에서 소유자 맥을 부릴 때)
- 수정은 `patch_NN.py`(파이썬, 앵커 문자열 개수 검증·실패 시 exit 1)를
  `/Users/ziririt/development/_patch/gd/`에 넣고 osascript로 실행한다.
  통째 덮어쓰기 금지.
- 파이썬 안 Dart 문자열에서 **`$`를 이스케이프하지 마라**(`\$`는 글자
  그대로 달러가 된다 — 실제 사고 2회).
- osascript로 긴 일 금지: `.sh` + `nohup … &` + 로그 폴링. 한국어 출력은
  `| iconv -f utf-8 -t utf-8 -c`. 30초 넘는 sleep은 끊길 수 있다.
- `run_web.sh`와 `run_deploy_nophone.sh`를 동시에 돌리지 마라(flutter 충돌).

## 4. 비밀·보안 수칙 (전부 실제 사고 또는 실제 위험에서 나온 규칙)

- AI API 키(소유자의 Gemini 키 등)를 어떤 출력에도 싣지 마라. 화면에
  보였어도 옮겨 적지 마라.
- 구글 클라이언트 시크릿을 요구하거나 저장하지 마라(PKCE 구조).
- `android/key.properties`의 키스토어 비번을 출력하지 마라.
- 소유자 화면을 허락 없이 스크린샷 찍지 마라.
- ezlong 리모트의 평문 토큰 — §3의 마스킹 규칙.
- 애플 계정·비밀번호 입력은 소유자만 한다. OAuth 동의 클릭도 소유자가.

## 5. 빌드·검증·배포 절차

- **모든 수정 뒤 `tool/verify.sh` 한 줄**: l10n_check → version_check →
  store_check → analyze → test(622개). analyze·test만으로는 부족하다 —
  이 저장소엔 자기만의 검사기가 있다(`ls tool/` 먼저 볼 것).
- 버전은 **작업마다 올린다**(소유자 규칙). 고칠 곳: `pubspec.yaml`
  `version:` + `lib/version.dart`(appVersion·appBuild). 빌드 번호는
  절대 내리지 않는다. 웹·앱은 같은 번호를 쓴다.
- 배포: 맥+안드로이드 `bash _patch/gd/run_deploy_nophone.sh`(폰 없으면
  맥만), 웹 `run_web.sh` 후 ezlong 커밋·푸시, 아이폰은 TestFlight CI
  (`v*` 태그 푸시) 또는 소유자 지시 시 케이블/무선 설치.
- 새 UI 문자열은 `lib/l10n/`에만, **9개 언어 전부**(ko가 원문). 함수형
  getter는 `all` 맵에 넣지 않는다(l10n_check 파서 한계).

## 6. 코드 지도와 동기화 불변식

- `lib/main.dart` — 화면 전부(1만 줄대). `lib/core/` — 순수 판단 함수들
  (tidy_engine, sync_plan, sync_merge, auto_meta, auto_tag_gate …
  플랫폼 API 금지, 시험 선행). `lib/sync/` — 구글 드라이브 전송
  (gdrive_transport)·인증(drive_auth). `lib/icloud_sync.dart` — 동기화
  엔진(양쪽 창고 공용).
- 동기화 구조: Google Drive appDataFolder, 파일마다 `appProperties`에
  `up`(고친 시각 도장)을 붙여 **바뀐 노트만 받는다**. 판단은
  `core/sync_plan.dart`(pickFetch·shouldUpload·editorRefresh·syncBanner).
- **되돌리면 안 되는 불변식**:
  - "모르면 안 올린다"(shouldUpload: remoteStamp를 모르면 false).
  - mergeNotes는 툼스톤 없이 삭제하지 않는다.
  - 드라이브 딱지는 media 성공 **후에** 찍는다.
  - 바쁨 잠금은 시간이 아니라 일이 끝날 때 푼다. timeout은 기다림만 끊는다.
  - 편집 화면은 저장소 변화를 듣는다(editorRefresh). 치던 중이면 눈앞의
    글이 이긴다.
  - 병합에서 지는 쪽에 아직 안 올라간 수정이 있으면 **휴지통에 백업**
    (mergeNotes backups + `syncedUpTo`). 글이 소리 없이 사라지면 안 된다.
- 웹 특이사항: CanvasKit이라 OS 폰트가 없다 — Pretendard OTF를
  `web/fonts/`에서 FontLoader로 심는다(pubspec fonts: 금지 — 모바일이
  3MB 는다). 브라우저 드라이브 허락은 1시간짜리 — 만료되면 목록 위
  파란 띠가 눕고 한 번 누르면 다시 켜진다(서버 없이는 구조적 한계).
  구형 서비스 워커가 옛 빌드를 물면 강력 새로고침으로 벗는다(자동
  교체는 남은 일).

## 7. 개발 방법론 (자세한 건 CLAUDE.md '개발 방법론' 장)

- 재라, 추측하지 마라. 화면 말고 디스크를 읽어라. 맥 저장소 진단:
  `plutil -convert xml1 -o - ~/Library/Containers/com.ziririt.simpletext/Data/Library/Preferences/com.ziririt.simpletext.plist`
- 판단은 core/ 순수 함수로 꺼내 시험으로 못 박고, 화면·IO는 따르게 하라.
- 한 결정을 두 곳에 쓰면 반드시 한 곳을 빠뜨린다(14회 실측).
- 시험이 통과해도 벌레를 지킬 수 있다 — 조건을 다양화하라. 상수는 그
  시점 조건의 산물이다(25초 타임아웃 사고).
- 새 버그는 재현 fixture/시험을 먼저 추가한 뒤 고친다.

## 8. 현재 상태와 남은 일 (2026-08-21 오전 기준)

- 판: 맥·웹 2.6.5 예정(직전 2.6.4까지 배포됨), 아이폰 2.6.0(TestFlight
  빌드 42가 심사판), 안드로이드 2.6.0(폰이 무선에 잡히면 최신 넣기),
  아이패드 1.9.2.
- **앱스토어 거절 대응(진행 중)**: 소유자 결정 — 중국 본토 제외(ASC
  이용 가능성에서 소유자가 해제) + 아이폰·아이패드에서 API 키 UI 숨김
  (2.6.5, `aiUiVisible()` — 설정 AI 구역·태그 AI 단추·키 안내문).
  다음: `v2.6.5` 태그 푸시로 TestFlight 새 빌드 → 소유자가 ASC에서
  새 빌드 선택 + 심사 메모에 "API 키 입력 UI를 iOS에서 제거했다" 갱신
  + 리졸루션 센터 회신 + 재제출.
- 남은 일: 심사 통과 후 스토어 문구 갱신('메모'→'노트', 동기화 문구,
  Play 문구) · 잠들기 전 마지막 업로드 마저 보내기(iOS
  beginBackgroundTask) · _save 헛저장 도장 방지(태그 등 메타 변경과
  구분해 신중히) · 서비스 워커 자동 교체 · 웹 겉면(html lang,
  og:image — 에셋은 ezlong/og/에 있음) · 크롬 확장(우클릭+단축키 방식,
  DOM 주입 금지) · '전체 복사' 빨간 줄 뜻(소유자 답 대기) · 로드맵:
  유료화(IAP), MSIX, 잠긴 노트 첨부 규칙, 잠금 화면 위젯.
- 소유자의 Gemini API 키가 스크린샷에 노출된 적 있다 — 재발급 권고
  상태(소유자 몫).

## 9. 새 파트너가 소유자에게 처음 요청할 것

- 소유자 맥에 대한 원격 실행 통로(이 문서의 patch 방식을 쓰려면).
- GitHub 접근(공개 저장소라 읽기는 자유; 푸시 권한은 소유자가 부여).
- 실기기 테스트 협조(아이폰 설치는 소유자 지시 시에만이라는 규칙 유지).
- 비밀값은 절대 채팅으로 받지 말 것 — 콘솔에서 소유자가 직접 넣게 안내.

이 앱은 소유자가 기기 네 대를 오가며 밤늦게까지 테스트해 준 덕에
여기까지 왔다. 측정하고, 물어보고, 시험을 먼저 써라. 그러면 이 저장소는
너에게도 잘 응답할 것이다.


## 10. 덧붙임 (2026-08-23) — 출시 이후 상태와 새 노하우

### 지금 상태
- **앱스토어 1.0(빌드 154) 출시 완료(8/22).** 후속 1.1(빌드 157, 내부
  번호 2.7.0)이 심사 대기 중 — 11개 언어 스토어 문구 갱신판('노트' 용어,
  전 기기 동기화 안내, iOS API 키 단락 삭제, 한국어 검색어 스카이블루·
  블루스카이). 심사 감시는 send_later 12시간 간격으로 돌고 있다.
- 스토어 문구 원본은 `store/ios/`(11개 로케일 × 6개 파일)이고
  `tool/store_check.py`가 지킨다. **원본은 저장소, 콘솔은 사본** —
  콘솔에서 직접 고치지 말고 저장소를 고쳐 API로 밀어라.
- Google Play는 비공개 테스트 단계. 프로덕션 승격에는 **테스터 12명 ×
  14일** 요건이 남아 있다(현재 참여 0명).

### 아이폰 배포의 진짜 길 (CI 아님)
- `ios_testflight.yml`은 GitHub Secrets 미등록으로 **동작하지 않는다.**
  실제 업로드는 소유자 맥의 `~/development/_patch/ipa2.sh` —
  App Store Connect API 키(`~/.appstoreconnect/asc.env` + AuthKey .p8,
  기기에만 있음)로 xcodebuild 아카이브 내보내기 + altool 업로드.
  `ipa4.sh`가 빌드 이름/번호를 지정해 부르는 래퍼다.
- **마케팅 버전 함정**: CFBundleShortVersionString은 이전 승인판(2.6.5)
  보다 커야 업로드된다. 스토어에 보이는 버전 이름(1.0, 1.1)과 별개다.
  다음 빌드는 2.7.0보다 큰 번호로.

### App Store Connect API 자동화 (버튼 없이 심사 제출까지)
- `_patch/asc_11.py` — 버전 생성 → 로케일 문구 반영 → 빌드 처리 대기·
  연결 → reviewSubmissions 제출. `asc_fill.py` — 새 로케일의 필수 필드
  (keywords·supportUrl 등)를 1.0에서 베껴 채우고 제출 마무리.
  `asc_kw.py` — 키워드만 수정.
- 밟은 함정들: reviewSubmissionItems의 관계 이름은 `appStoreVersion`
  (appStoreVersionForReview 아님) · API로 새로 만든 로케일은 description
  만으론 제출 불가(keywords·URL 필수 — 이전 버전에서 복사) · JWT는
  pyjwt+cryptography(맥에 설치돼 있음) · 제출 상태 409의 associatedErrors
  안에 진짜 원인이 있다.

### 소유자와의 합의 사항 (지켜라)
- **리뷰 대본 금지**: 지인에게 붙여넣을 리뷰 문안을 만들어 주지 않는다.
  대신 '관찰 포인트 목록 + 자기 말로 한 줄' 방식으로 안내한다(애플
  리뷰 조작 정책·유사 문구 클러스터 감지 때문). 소유자도 수긍했다.
- 홍보 글은 "제가 만들었습니다"를 밝히는 담백한 톤. 소유자는 개조식
  (소제목 + 닷블릿, 명사형 종결, 짧지만 디테일)을 선호한다.
- 판매자 정보 공개 이슈: Play 개발자 프로필에 자택 주소(동·호수 포함)와
  사업자번호 435-07-02464가 공개되는 구조. 근본 해결은 사업자 주소를
  비상주 사무실로 이전(홈택스 정정 → 양쪽 스토어 갱신) — 소유자 몫으로
  안내해 둔 상태.
