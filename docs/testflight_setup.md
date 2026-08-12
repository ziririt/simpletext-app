# TestFlight 자동 배포 — 처음 한 번만 하는 설정

이걸 끝내면 **맥을 켜지 않아도** 아이폰에 새 버전이 설치된다.
GitHub이 애플 서버로 앱을 올려 주고, 폰에서는 TestFlight 앱으로 받는다.

왜 하는가 — 노하우 문서 5절:
> "무선 개발 설치는 생각보다 자주 실패한다. 오늘만 다섯 번 막혔다.
> 기기 잠금, Wi-Fi 상태, 회사망의 단말 간 차단, Xcode의 '이전 준비 오류'…
> 그래서 TestFlight CI가 로드맵에 있는 건 옳은 판단이다."

준비물: 맥, 애플 개발자 계정(유료 — 이미 있음), 30분 정도.

---

## 전체 그림

GitHub에 **비밀값 6개**를 등록하면 된다. 세 묶음이다.

| 묶음 | 무엇 | 개수 |
|---|---|---|
| A. 애플 API 키 | GitHub이 애플에 로그인하는 열쇠 | 3개 |
| B. 배포 인증서 | 앱에 도장을 찍는 인감 | 2개 |
| C. 프로비저닝 프로파일 | "이 앱을 이 계정으로 낸다"는 허가증 | 1개 |

---

## A. 애플 API 키 만들기 (3개)

1. https://appstoreconnect.apple.com 접속 → 로그인
2. 위쪽 **사용자 및 액세스** 클릭
3. **통합** 탭 → 왼쪽에서 **App Store Connect API** 선택
4. **팀 키** 탭에서 **+** 버튼
5. 이름은 `GitHub Actions`, 액세스 권한은 **App Manager** 선택 → 생성
6. 만들어진 줄에서 확인·저장할 것 **3가지**:

| 화면에 보이는 것 | GitHub에 넣을 이름 |
|---|---|
| 맨 위 **발급자 ID** (Issuer ID, 긴 영숫자) | `APP_STORE_CONNECT_ISSUER_ID` |
| 그 줄의 **키 ID** (짧은 영숫자) | `APP_STORE_CONNECT_KEY_ID` |
| **API 키 다운로드** 로 받은 `.p8` 파일 **내용 전체** | `APP_STORE_CONNECT_P8` |

> `.p8` 파일은 **한 번만** 받을 수 있다. 받아서 안전한 곳에 보관할 것.
> 내용은 맥에서 이렇게 확인한다 (파일 이름은 실제 받은 것으로):
> ```
> cat ~/Downloads/AuthKey_XXXXXXXXXX.p8
> ```
> `-----BEGIN PRIVATE KEY-----` 부터 `-----END PRIVATE KEY-----` 까지 전부 복사한다.

---

## B. 배포 인증서 꺼내기 (2개)

이미 "Apple Distribution" 인증서가 맥에 있다(HANDOVER 3절). 그걸 파일로 꺼낸다.

1. **키체인 접근** 앱 실행 (Spotlight에서 "키체인" 검색)
2. 왼쪽에서 **로그인** → **내 인증서**
3. **Apple Distribution: …** 항목에서 오른쪽 클릭 → **"…" 내보내기**
4. 파일 포맷 **개인 정보 교환(.p12)**, 바탕화면에 `dist.p12`로 저장
5. **암호를 물어보면 아무거나 정하고 반드시 기억할 것** → 이게 `IOS_DIST_CERT_PASSWORD`
6. 터미널에서 base64로 바꾼다. 결과가 클립보드에 복사된다.

```
base64 -i ~/Desktop/dist.p12 | pbcopy
```

| 값 | GitHub에 넣을 이름 |
|---|---|
| 방금 복사된 긴 문자열 | `IOS_DIST_CERT_P12_BASE64` |
| 4번에서 정한 암호 | `IOS_DIST_CERT_PASSWORD` |

> 등록이 끝나면 바탕화면의 `dist.p12`는 지운다. 남겨 두면 그 파일만으로 앱에 도장을 찍을 수 있다.

---

## C. 프로비저닝 프로파일 받기 (1개)

1. https://developer.apple.com/account → **Certificates, Identifiers & Profiles**
2. 왼쪽 **Profiles** → **+** 버튼
3. **App Store Connect** 선택 → 계속
4. App ID는 **com.ziririt.simpletext** 선택 → 계속
5. 인증서는 방금 쓴 **Apple Distribution** 선택 → 계속
6. 이름은 `SimpleText App Store`, 생성 → **Download**
7. 터미널에서 base64로 바꾼다 (받은 파일 이름에 맞춰 수정):

```
base64 -i ~/Downloads/SimpleText_App_Store.mobileprovision | pbcopy
```

| 값 | GitHub에 넣을 이름 |
|---|---|
| 방금 복사된 긴 문자열 | `IOS_PROVISIONING_PROFILE_BASE64` |

---

## GitHub에 등록하기

1. https://github.com/ziririt/simpletext-app 접속
2. **Settings** 탭 → 왼쪽 **Secrets and variables** → **Actions**
3. **New repository secret** 을 눌러 위 6개를 하나씩 등록
   (이름은 표에 적힌 대로 **대문자·밑줄까지 똑같이**)

등록이 끝나면 이름만 보이고 값은 다시 볼 수 없다. 정상이다.

---

## 앱 등록 (App Store Connect)

TestFlight로 올리려면 앱이 먼저 등록돼 있어야 한다.

1. App Store Connect → **앱** → **+** → **신규 앱**
2. 플랫폼 **iOS**, 이름은 정해진 앱 이름, 기본 언어 **한국어**
3. 번들 ID **com.ziririt.simpletext** 선택
4. SKU는 아무 문자열(예: `simpletext-001`)

---

## 실행

1. https://github.com/ziririt/simpletext-app/actions
2. 왼쪽에서 **iOS TestFlight** 선택
3. 오른쪽 **Run workflow** 버튼 → 실행

15~25분쯤 걸린다. 끝나면 App Store Connect의 **TestFlight** 탭에 빌드가 올라온다.
애플이 처리하는 데 몇 분 더 걸리고, 그 뒤 폰의 TestFlight 앱에서 받을 수 있다.

이후로는 버튼 한 번이면 된다. 태그를 올리는 방식(`v1.0.1` 같은)으로도 돈다.

---

## 잘 안 될 때

| 증상 | 원인과 조치 |
|---|---|
| "다음 Secret이 등록되어 있지 않습니다" | 이름 오타. 대소문자·밑줄까지 정확히 맞춘다 |
| 서명 단계에서 실패 | `.p12` 암호가 틀렸거나, 내보낼 때 인증서만 골라 개인 키가 빠진 경우. 키체인에서 인증서 왼쪽 삼각형을 펼쳐 **개인 키까지 함께** 선택해 내보낸다 |
| "No profiles found" | 프로파일의 App ID가 `com.ziririt.simpletext`가 맞는지, 종류가 **App Store Connect**인지 확인 |
| 업로드에서 거부 | 대개 빌드 번호 중복인데, 이 워크플로는 실행 번호를 쓰므로 겹치지 않는다. 그 외에는 애플이 보낸 메일에 이유가 적혀 온다 |

## 참고: 여기서 끝이 아니다

노하우 문서 2절 — **"배포는 푸시가 아니라 라이브 확인에서 끝난다."**
업로드가 성공해도 폰에서 실제로 받아 실행해 보기 전까지는 끝난 게 아니다.
