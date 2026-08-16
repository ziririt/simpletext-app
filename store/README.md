# 스토어 등록정보 (글로벌 출시)

App Store에 올릴 문구와 스크린샷을 언어별로 보관한다.
`fastlane deliver`가 읽는 디렉터리 구조와 같아서, 나중에 자동 업로드를 붙일 때 그대로 쓴다.

## 왜 이렇게까지 하는가

노하우 문서 6절에서 실제로 겪은 사고 두 가지를 여기서 막는다.

1. **번역 파일은 조용히 썩는다.** 파일은 있는데 값이 비어 있거나 원문 그대로인 채
   몇 주가 지나간다. 아무도 모른다. → `tool/store_check.py`가 CI에서 **실패**로 떨어뜨린다.
2. **현지화된 스크린샷이 없으면 기본 언어 스크린샷이 그대로 나간다.**
   경고도 오류도 없다. 애플·구글 양쪽 다 그랬다. → `tool/screenshot_check.py`로 센다.

## 디렉터리

```
store/
  ios/<로케일>/name.txt              앱 이름          (30자)
                subtitle.txt          부제            (30자)
                promotional_text.txt  홍보 문구       (170자)
                keywords.txt          검색 키워드     (100자, 쉼표 구분)
                description.txt       설명            (4000자)
                release_notes.txt     이번 버전 변경점 (4000자)
  screenshots/<기기>/<로케일>/*.png   촬영 결과 (저장소에 커밋하지 않음)
```

## 로케일 11개

| 스토어 로케일 | 앱 언어 | 비고 |
|---|---|---|
| ko | 한국어 | 원문 기준 |
| en-US | 영어 | |
| ja | 일본어 | |
| zh-Hans | 중국어 간체 | |
| zh-Hant | 중국어 번체 | |
| de-DE | 독일어 | |
| fr-FR | 프랑스어 | |
| es-ES | 스페인어(스페인) | móvil, pulsar |
| es-MX | 스페인어(중남미) | celular, presionar |
| pt-BR | 포르투갈어(브라질) | celular, tela, planilha |
| pt-PT | 포르투갈어(포르투갈) | telemóvel, ecrã, folha de cálculo |

앱 UI는 스페인어·포르투갈어를 각각 하나로 쓰지만(사용자 확정 2026-08-12),
**스토어 문구는 지역을 나눈다.** 같은 언어라도 단어가 다르고, 그 나라 사용자는
바로 알아본다(노하우 6절: clima→el tiempo, celular→telemóvel, tela→ecrã).

## 검사

```
python3 tool/store_check.py        # 문구 — CI에서 자동 실행
python3 tool/screenshot_check.py   # 스크린샷 — 촬영 후 맥에서 실행
```

`store_check.py`가 보는 것: 파일 누락, 빈 값, 글자 수 초과, 자리표시자 잔존,
한국어 원문과 동일(미번역), 번역문에 한글이 섞여 있음.

## 스크린샷 촬영 (맥에서)

```
tool/screenshots.sh
python3 tool/screenshot_check.py
```

11개 로케일 × 기기별로 3장씩 자동으로 찍는다(목록 / 정렬된 표 / 풀어쓴 표).
시뮬레이터 이름이 안 맞으면 `xcrun simctl list devices available`로 확인해
`tool/screenshots.sh`의 `DEFAULT_DEVICES`를 고친다.

PNG는 `.gitignore`에 넣어 저장소에 커밋하지 않는다 — 생성 파일을 커밋하기 시작하면
저장소가 부풀고 모든 git 작업이 느려진다(노하우 10절).

## 이름 — 정해졌다

**Skyblue Note.** 열한 개 로케일 모두 같은 이름을 쓴다(2026-08-17 확정).

상표는 번역하지 않는다. Notion도 Bear도 Obsidian도 어느 나라에서나 같은
이름으로 판다. 번역하면 검색이 갈라지고, 사람들이 입으로 옮길 이름이 없어진다.

그래서 `ios/Runner/*.lproj/InfoPlist.strings`로 홈 화면 이름을 언어별로
바꾸려던 계획은 **접었다.** 그 파일들은 Xcode 프로젝트에 등록된 적이 없어
빌드에 들어가지도 않았다 — 지금 상태가 곧 원하는 상태다.

맥 쪽은 자리가 하나 더 있었다. 파인더와 독은 plist의 표시 이름이 아니라
**디스크의 파일 이름**을 보여 주므로, `macos/Runner/Configs/AppInfo.xcconfig`의
`PRODUCT_NAME`이 이름을 정한다. 여기도 Skyblue Note로 맞춰 두었다.

출시 전 확인:
- [x] 앱 이름 확정
- [x] `name.txt` 11개 갱신
- [x] 스크린샷 촬영 + `screenshot_check.py` 통과 (11개 언어 × 2기기 = 66장)
- [ ] 상표 출원 (소유자)
- [ ] 개인정보 처리방침 URL (App Store Connect 필수)
- [ ] 연령 등급, 카테고리(생산성) 설정
- [ ] 인앱 구입 상품 3개 등록 + StoreKit 연결

## 시연용 메모도 번역되어야 한다

스크린샷 대본(`integration_test/screenshots_test.dart`)에는 로케일마다
**시연용 메모 한 벌**이 들어 있다. 2026-08-17에 겪은 일이라 적어 둔다.

껍데기(단추·상단바)만 번역되고 메모 내용이 한국어인 채로 열한 언어를 다
찍었다. 검사는 통과했다 — 파일이 다 있었으니까. 눈으로 열어 보고서야 알았다.

독일 사람이 독일 스토어에서 한국어가 든 화면을 보면 **이 앱은 내 언어를
지원하지 않는다**고 읽는다. 아홉 언어를 번역해 놓고 그 사실을 화면으로는
증명하지 못하는 셈이다.

표는 언어마다 글자 폭이 다르다. 한글·한자·가나는 등폭 글꼴에서 두 칸을
차지한다. 손으로 공백을 맞추면 열한 벌 중 하나는 반드시 어긋나므로
**폭을 세어서 표를 만든다**(`_cells`, `_table`).
