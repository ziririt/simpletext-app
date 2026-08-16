/// 스토어 스크린샷 자동 촬영 (11개 로케일).
///
/// 왜 이게 있는가 — 노하우 문서 6절:
///   "현지화된 스크린샷이 없으면 기본 언어의 스크린샷이 그대로 나간다.
///    경고도 없고 오류도 없다. 비한국어 사용자 전원이 한국어 스크린샷을 보고 있었다."
/// 손으로 11개 언어 × 여러 기기를 찍으면 반드시 빠지는 언어가 생긴다. 그래서 자동화한다.
///
/// 실행 (맥에서):
///   tool/screenshots.sh
///
/// 촬영 결과는 store/screenshots/<기기>/<로케일>/NN_이름.png 로 떨어진다.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simpletext/main.dart';

/// 시연용 메모 한 벌.
///
/// 2026-08-17 — 찍어 놓고 열어 보니 **영어·독일어·중국어 화면에 한국어 본문이
/// 그대로 들어가 있었다.** 껍데기(단추·상단바)만 번역되고 메모 내용은 한국어였다.
///
/// 이 파일의 옛 주석은 "언어와 무관한 데이터(티커·수치)를 쓴다"고 적어 두었다.
/// 표는 그 말이 맞았는데, **풀어쓴 메모는 아니었다.** 회사 연혁을 한국어로
/// 써 놓고 그 사실을 스스로 잊고 있었다.
///
/// 스토어 화면에서 이건 그냥 흠이 아니다. 독일 사람이 독일어 스토어에서
/// 한국어가 든 화면을 보면 **이 앱은 내 언어를 지원하지 않는다**고 읽는다.
/// 아홉 언어를 번역해 놓고 그 사실을 화면으로는 증명하지 못하는 셈이다.
class _Demo {
  const _Demo({
    required this.portfolio,
    required this.timeline,
    required this.summary,
    required this.head,
    required this.names,
    required this.wide,
    required this.blurb,
  });

  /// 메모 제목 셋
  final String portfolio;
  final String timeline;
  final String summary;

  /// 표 머리 네 칸 (종목 · 티커 · 수익률 · 비중)
  final List<String> head;

  /// 종목 이름 넷. 티커와 수치는 어느 언어에서나 같다.
  final List<String> names;

  /// 넓은 표를 풀어쓴 메모의 본문
  final String wide;

  /// 셋째 메모의 한 줄
  final String blurb;
}

/// 등폭 글꼴에서 보이는 너비.
///
/// 한글·한자·가나는 한 글자가 **두 칸**을 차지한다. 그래서 표의 칸을 맞출 때
/// 글자 수로 세면 언어마다 어긋난다. 언어별로 공백을 손으로 맞추는 방법도
/// 있지만, 열한 벌을 손으로 맞추면 반드시 하나는 틀린다 — 그래서 센다.
int _cells(String s) {
  var n = 0;
  for (final r in s.runes) {
    final wide = (r >= 0x1100 && r <= 0x115F) ||
        r == 0x2329 ||
        r == 0x232A ||
        (r >= 0x2E80 && r <= 0xA4CF && r != 0x303F) ||
        (r >= 0xAC00 && r <= 0xD7A3) ||
        (r >= 0xF900 && r <= 0xFAFF) ||
        (r >= 0xFE30 && r <= 0xFE6F) ||
        (r >= 0xFF00 && r <= 0xFF60) ||
        (r >= 0xFFE0 && r <= 0xFFE6);
    n += wide ? 2 : 1;
  }
  return n;
}

/// 칸이 맞는 표를 만든다. 첫 칸은 왼쪽에, 나머지는 오른쪽에 붙인다 —
/// 숫자는 끝자리가 세로로 맞아야 눈이 비교할 수 있다.
String _table(List<String> head, List<List<String>> rows) {
  final cols = head.length;
  final width = List<int>.generate(cols, (i) {
    var m = _cells(head[i]);
    for (final r in rows) {
      final x = _cells(r[i]);
      if (x > m) m = x;
    }
    return m;
  });

  String pad(String s, int w, {required bool right}) {
    final gap = ' ' * (w - _cells(s));
    return right ? '$gap$s' : '$s$gap';
  }

  String line(List<String> cells) => [
        for (var i = 0; i < cols; i++) pad(cells[i], width[i], right: i > 0),
      ].join('  ');

  final total = width.fold<int>(0, (a, b) => a + b) + (cols - 1) * 2;
  final buf = StringBuffer()
    ..writeln(line(head))
    // 가로줄도 두 칸짜리 글자라 절반만 찍어야 폭이 맞는다.
    ..writeln('─' * (total ~/ 2));
  for (final r in rows) {
    buf.writeln(line(r));
  }
  return buf.toString().trimRight();
}

const _tickers = ['AAPL', 'MSFT', 'NVDA', 'TSLA'];
const _returns = ['+14.2%', '+21.5%', '+48.9%', '-8.3%'];
const _weights = ['12%', '18%', '22%', '8%'];

const _latinNames = ['Apple', 'Microsoft', 'NVIDIA', 'Tesla'];

/// 로케일별 시연 내용.
const _demos = <String, _Demo>{
  'ko': _Demo(
    portfolio: '포트폴리오',
    timeline: '타임라인',
    summary: '조사 요약',
    head: ['종목', '티커', '수익률', '비중'],
    names: ['애플', '마이크로소프트', '엔비디아', '테슬라'],
    wide: '''2021년 4월
  - 확인된 움직임 : 세계 책의 날에 작가 일러스트 기반 디지털 굿즈를 배포
  - 해석 : 굿즈를 독서 경험에 연결한 초기 사례

2023년 3~4월
  - 확인된 움직임 : 사명을 바꾸고 보유 IP의 영상화를 추진
  - 해석 : IP 사업 확장 전략을 공개한 단계''',
    blurb: '붙여넣으면 깨끗한 글이 됩니다.',
  ),
  'en-US': _Demo(
    portfolio: 'Portfolio',
    timeline: 'Timeline',
    summary: 'Research summary',
    head: ['Holding', 'Ticker', 'Return', 'Weight'],
    names: _latinNames,
    wide: '''April 2021
  - Observed : Illustrated digital goods released for World Book Day
  - Reading : An early attempt to tie merchandise to the reading experience

March-April 2023
  - Observed : Renamed, and its own titles moved toward screen adaptation
  - Reading : The point where the licensing strategy went public''',
    blurb: 'Paste an answer and it becomes clean text.',
  ),
  'ja': _Demo(
    portfolio: 'ポートフォリオ',
    timeline: 'タイムライン',
    summary: '調査メモ',
    head: ['銘柄', 'ティッカー', '騰落率', '比率'],
    names: ['アップル', 'マイクロソフト', 'エヌビディア', 'テスラ'],
    wide: '''2021年4月
  - 確認された動き : 世界本の日に作家イラストのデジタルグッズを配布
  - 読み解き : グッズを読書体験に結びつけた初期の例

2023年3〜4月
  - 確認された動き : 社名を変更し、自社作品の映像化を推進
  - 読み解き : 版権事業の拡大戦略を公にした段階''',
    blurb: '貼り付けるだけできれいな文章になります。',
  ),
  'zh-Hans': _Demo(
    portfolio: '投资组合',
    timeline: '时间线',
    summary: '研究摘要',
    head: ['标的', '代码', '涨跌', '占比'],
    names: ['苹果', '微软', '英伟达', '特斯拉'],
    wide: '''2021年4月
  - 已确认的动作 : 世界读书日发布作家插画数字周边
  - 解读 : 把周边与阅读体验连起来的早期尝试

2023年3—4月
  - 已确认的动作 : 更名，并推动自有作品影视化
  - 解读 : 公开版权业务扩张策略的节点''',
    blurb: '粘贴进来，就变成干净的文字。',
  ),
  'zh-Hant': _Demo(
    portfolio: '投資組合',
    timeline: '時間軸',
    summary: '研究摘要',
    head: ['標的', '代號', '漲跌', '佔比'],
    names: ['蘋果', '微軟', '輝達', '特斯拉'],
    wide: '''2021年4月
  - 已確認的動作 : 世界閱讀日推出作家插畫數位周邊
  - 解讀 : 把周邊與閱讀體驗連起來的早期嘗試

2023年3—4月
  - 已確認的動作 : 更名，並推動自有作品影視化
  - 解讀 : 公開版權業務擴張策略的節點''',
    blurb: '貼上來，就變成乾淨的文字。',
  ),
  'de-DE': _Demo(
    portfolio: 'Portfolio',
    timeline: 'Zeitleiste',
    summary: 'Rechercheübersicht',
    head: ['Titel', 'Kürzel', 'Rendite', 'Anteil'],
    names: _latinNames,
    wide: '''April 2021
  - Beobachtet : Zum Welttag des Buches erscheinen illustrierte digitale Artikel
  - Lesart : Ein früher Versuch, Merchandise an das Lesen zu koppeln

März-April 2023
  - Beobachtet : Umbenennung, und eigene Stoffe gehen Richtung Verfilmung
  - Lesart : Der Moment, in dem die Lizenzstrategie öffentlich wurde''',
    blurb: 'Einfügen, und daraus wird sauberer Text.',
  ),
  'fr-FR': _Demo(
    portfolio: 'Portefeuille',
    timeline: 'Chronologie',
    summary: 'Synthèse de recherche',
    head: ['Titre', 'Symbole', 'Rendement', 'Poids'],
    names: _latinNames,
    wide: '''Avril 2021
  - Fait observé : des objets numériques illustrés pour la Journée du livre
  - Lecture : une première tentative de lier les produits dérivés à la lecture

Mars-avril 2023
  - Fait observé : changement de nom, et adaptation à l’écran des œuvres maison
  - Lecture : le moment où la stratégie de licences devient publique''',
    blurb: 'Collez : le texte devient propre.',
  ),
  'es-ES': _Demo(
    portfolio: 'Cartera',
    timeline: 'Cronología',
    summary: 'Resumen de investigación',
    head: ['Valor', 'Símbolo', 'Rentab.', 'Peso'],
    names: _latinNames,
    wide: '''Abril de 2021
  - Hecho observado : artículos digitales ilustrados por el Día del Libro
  - Lectura : un primer intento de unir el merchandising con la lectura

Marzo-abril de 2023
  - Hecho observado : cambio de nombre y adaptación audiovisual de sus obras
  - Lectura : el momento en que la estrategia de licencias se hace pública''',
    blurb: 'Pega y queda un texto limpio.',
  ),
  'es-MX': _Demo(
    portfolio: 'Cartera',
    timeline: 'Cronología',
    summary: 'Resumen de investigación',
    head: ['Valor', 'Símbolo', 'Rendim.', 'Peso'],
    names: _latinNames,
    wide: '''Abril de 2021
  - Hecho observado : artículos digitales ilustrados por el Día del Libro
  - Lectura : un primer intento de unir el merchandising con la lectura

Marzo-abril de 2023
  - Hecho observado : cambio de nombre y adaptación audiovisual de sus obras
  - Lectura : el momento en que la estrategia de licencias se hace pública''',
    blurb: 'Pega y queda un texto limpio.',
  ),
  'pt-BR': _Demo(
    portfolio: 'Carteira',
    timeline: 'Linha do tempo',
    summary: 'Resumo da pesquisa',
    head: ['Ativo', 'Ticker', 'Retorno', 'Peso'],
    names: _latinNames,
    wide: '''Abril de 2021
  - Fato observado : artigos digitais ilustrados para o Dia do Livro
  - Leitura : uma primeira tentativa de ligar os produtos à experiência de ler

Março-abril de 2023
  - Fato observado : mudança de nome e adaptação audiovisual das próprias obras
  - Leitura : o momento em que a estratégia de licenças se torna pública''',
    blurb: 'Cole e vira um texto limpo.',
  ),
  'pt-PT': _Demo(
    portfolio: 'Carteira',
    timeline: 'Linha do tempo',
    summary: 'Resumo da pesquisa',
    head: ['Ativo', 'Ticker', 'Retorno', 'Peso'],
    names: _latinNames,
    wide: '''Abril de 2021
  - Facto observado : artigos digitais ilustrados para o Dia do Livro
  - Leitura : uma primeira tentativa de ligar os produtos à experiência de ler

Março-abril de 2023
  - Facto observado : mudança de nome e adaptação audiovisual das próprias obras
  - Leitura : o momento em que a estratégia de licenças se torna pública''',
    blurb: 'Cole e fica um texto limpo.',
  ),
};

/// 시연용 메모를 저장 형식으로 만든다.
String _demoNotes(_Demo d) {
  final narrow = _table(d.head, [
    for (var i = 0; i < 4; i++)
      [d.names[i], _tickers[i], _returns[i], _weights[i]],
  ]);

  const t = 1786000000000;
  final notes = [
    {
      'id': 'shot-1',
      'title': d.portfolio,
      'body': narrow,
      'originalBody': narrow,
      'pinned': true,
      'source': 'ChatGPT',
      'tags': <String>[],
      'createdAt': t,
      'updatedAt': t,
      'history': <String>[],
      'lastReport': '',
    },
    {
      'id': 'shot-2',
      'title': d.timeline,
      'body': d.wide,
      'originalBody': d.wide,
      'pinned': false,
      'source': 'Claude',
      'tags': <String>[],
      'createdAt': t - 86400000,
      'updatedAt': t - 86400000,
      'history': <String>[],
      'lastReport': '',
    },
    {
      'id': 'shot-3',
      'title': d.summary,
      'body': d.blurb,
      'originalBody': '',
      'pinned': false,
      'source': 'Gemini',
      'tags': <String>[],
      'createdAt': t - 172800000,
      'updatedAt': t - 172800000,
      'history': <String>[],
      'lastReport': '',
    },
  ];
  return jsonEncode({'v': 2, 'notes': notes, 'tombstones': <dynamic>[]});
}

/// 앱이 지원하는 9개 언어 → 스토어 로케일 11개.
/// 스페인어·포르투갈어는 지역별로 스토어 항목이 갈리므로 화면도 따로 찍는다
/// (문구 자체는 각각 es/pt 하나를 쓰지만, 스토어에 올릴 파일은 분리되어야 한다).
const _locales = <String, Locale>{
  'ko': Locale('ko'),
  'en-US': Locale('en'),
  'ja': Locale('ja'),
  'zh-Hans': Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  'zh-Hant': Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  'de-DE': Locale('de'),
  'fr-FR': Locale('fr'),
  'es-ES': Locale('es'),
  'es-MX': Locale('es'),
  'pt-BR': Locale('pt'),
  'pt-PT': Locale('pt'),
};

/// 뒤로 간다.
///
/// 2026-08-17 — 여기서 열한 언어가 전부 멈췄다. tester.pageBack()은 쿠퍼티노식
/// 뒤로 가기 단추를 먼저 찾고, 없으면 **툴팁이 'Back'인 것**을 찾는다. 우리는
/// 머티리얼 상단바를 쓰고 툴팁은 번역돼 있다(한국어에서는 '뒤로'). 영어를
/// 찾는 함수가 그걸 찾을 리 없다.
///
/// 2026-08-17 (두 번째) — 아이패드에서 또 멈췄다. 이번엔 이유가 다르다.
/// **넓은 화면에는 뒤로 가기 단추가 아예 없다.** 분할 보기라서 왼쪽 목록이
/// 사라지지 않기 때문이다. 목록이 그대로인데 '목록으로 돌아가기'가 있을 리
/// 없다. 앱이 맞고 대본이 아이폰만 생각하고 쓰여 있었다.
///
/// 없으면 아무것도 안 한다. 이미 목록이 보이니까 그걸로 충분하다.
Future<void> back(WidgetTester tester) async {
  final b = find.byType(BackButton);
  if (b.evaluate().isEmpty) return;
  await tester.tap(b.first);
  await tester.pumpAndSettle();
}

/// 메모를 연다.
///
/// 분할 보기에서는 같은 제목이 두 군데 있다 — 왼쪽 목록의 줄, 그리고
/// 오른쪽에 열린 글의 제목칸. 그냥 누르면 '둘 중 어느 것이냐'로 멈춘다.
/// 목록이 먼저 그려지므로 첫 번째가 목록의 줄이다.
Future<void> openNote(WidgetTester tester, String title) async {
  await tester.tap(find.text(title).first);
  await tester.pumpAndSettle();
}

/// 한 장 찍는다.
///
/// 2026-08-17 — 아이폰의 둘째·셋째 장이 **화면이 미끄러지는 도중**에
/// 찍혀 있었다. 왼쪽에 목록이 반쯤, 오른쪽에 글이 반쯤. 스토어에 올리면
/// 앱이 고장 난 것처럼 보인다. 아이패드는 분할 보기라 전환이 없어서 멀쩡했다.
///
/// 원인이 둘 겹쳐 있었다.
///
/// 하나 — `pumpAndSettle(const Duration(seconds: 1))`의 그 1초는 기다리는
/// 시간이 아니다. **몇 초 간격으로 화면을 굴릴 것인가**를 정하는 값이고,
/// 기다리는 한도는 따로 있다(기본 10분). 이름만 보고 '1초 기다린다'로
/// 읽으면 틀린다.
///
/// 둘 — 그리고 이게 진짜다. pumpAndSettle이 보장하는 것은 '위젯이 다
/// 정착했다'까지다. 그런데 **사진을 찍는 일은 플랫폼 쪽에서 따로 일어난다.**
/// 그려진 것이 화면에 실제로 올라오기까지는 진짜 시간이 걸리고, 시험용
/// 시계를 아무리 돌려도 그 시간은 안 지나간다.
///
/// 그래서 진짜 시계로 기다리는 한 박자를 넣었다.
Future<void> shoot(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(milliseconds: 900));
  await tester.pumpAndSettle();
  await binding.takeScreenshot(name);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final entry in _locales.entries) {
    final tag = entry.key;
    final demo = _demos[tag]!;
    testWidgets('screenshots $tag', (tester) async {
      SharedPreferences.setMockInitialValues(
          {'simpletext.notes.v2': _demoNotes(demo)});

      await tester.pumpWidget(SimpleTextApp(locale: entry.value));
      await tester.pumpAndSettle();

      // 1) 목록 화면
      await shoot(tester, binding, '$tag/01_list');

      // 2) 표가 든 메모 (정렬된 좁은 표)
      await openNote(tester, demo.portfolio);
      await shoot(tester, binding, '$tag/02_table');

      // 3) 넓은 표를 풀어쓴 메모
      await back(tester);
      await openNote(tester, demo.timeline);
      await shoot(tester, binding, '$tag/03_records');

      await back(tester);
    });
  }
}
