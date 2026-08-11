/// 심플텍스트 — AI 마법사 1층: 자연어 규칙 명령 해석기 (Pure Dart)
/// 웹 프로토타입 parseWizard와 동일 규칙. 설정 변경과 본문 치환을 수행한다.
library wizard;

import 'tidy_engine.dart';

class WizardOutcome {
  final List<String> applied; // 적용된 규칙 설명
  final List<String> unknown; // 해석 불가 문장 (2층 AI 대상)
  final String body; // 치환이 있었으면 변경된 본문
  final bool bodyChanged;
  const WizardOutcome({
    required this.applied,
    required this.unknown,
    required this.body,
    required this.bodyChanged,
  });
}

/// settings 객체를 직접 수정한다. 호출 측에서 persist 필요.
WizardOutcome applyWizard({
  required String command,
  required dynamic settings, // AppSettings (main.dart) — 동적 접근
  required String body,
}) {
  final applied = <String>[];
  final unknown = <String>[];
  var newBody = body;
  var bodyChanged = false;

  final text = command.trim();
  if (text.isEmpty) {
    return WizardOutcome(applied: applied, unknown: unknown, body: body, bodyChanged: false);
  }
  final headingCtx = RegExp('소제목|제목|헤딩|heading', caseSensitive: false).hasMatch(text);
  final clauses = text
      .split(RegExp(r'[\n.。]+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  for (final clause in clauses) {
    var matched = false;
    RegExpMatch? m;

    // 1) 소제목 위/아래 여백 줄 수
    if (headingCtx || RegExp('여백|공백|빈\\s*줄').hasMatch(clause)) {
      m = RegExp('(?:위|앞).*?([0-9]+)\\s*줄(?:씩)?\\s*(?:으로|로)').firstMatch(clause) ??
          RegExp('(?:위|앞)[^0-9]{0,8}([0-9]+)\\s*줄').firstMatch(clause);
      if (m != null) {
        final n = int.parse(m.group(1)!).clamp(0, 9);
        settings.headingPad = true;
        settings.headingPadAbove = n;
        applied.add('소제목 위 여백 $n줄');
        matched = true;
      }
      m = RegExp('(?:아래|밑).*?([0-9]+)\\s*줄(?:씩)?\\s*(?:으로|로)').firstMatch(clause) ??
          RegExp('(?:아래|밑)[^0-9]{0,8}([0-9]+)\\s*줄').firstMatch(clause);
      if (m != null) {
        final n = int.parse(m.group(1)!).clamp(0, 9);
        settings.headingPad = true;
        settings.headingPadBelow = n;
        applied.add('소제목 아래 여백 $n줄');
        matched = true;
      }
    }

    // 2) 글머리 들여쓰기 칸 수
    if (!matched && RegExp('스페이스|공백|들여쓰|칸').hasMatch(clause) && clause.contains('칸')) {
      m = RegExp('([0-9]+)\\s*칸\\s*(?:으로|로|만)').firstMatch(clause);
      if (m == null) {
        final all = RegExp('([0-9]+)\\s*칸').allMatches(clause).toList();
        if (all.isNotEmpty) m = all.last;
      }
      if (m != null) {
        final n = int.parse(m.group(1)!).clamp(0, 9);
        settings.bulletIndent = n;
        applied.add('글머리 들여쓰기 $n칸');
        matched = true;
      }
    }
    if (!matched &&
        RegExp('들여쓰기|스페이스|공백').hasMatch(clause) &&
        RegExp('없애|제거|빼').hasMatch(clause) &&
        RegExp('칸|들여쓰기').hasMatch(clause)) {
      settings.bulletIndent = 0;
      applied.add('글머리 들여쓰기 없음');
      matched = true;
    }

    // 3) 글머리 기호
    if (!matched && RegExp('글머리|불릿|블릿|bullet|항목\\s*기호', caseSensitive: false).hasMatch(clause)) {
      final map = <(RegExp, String, String)>[
        (RegExp('하이픈|대시'), '-', '하이픈 -'),
        (RegExp('가운뎃점|중간점|점불릿|·'), '·', '가운뎃점 ·'),
        (RegExp('흰\\s*불릿|◦'), '◦', '흰 불릿 ◦'),
        (RegExp('불릿|•'), '•', '불릿 •'),
        (RegExp('원래|그대로|유지'), 'keep', '원래 기호 유지'),
      ];
      for (final e in map) {
        if (e.$1.hasMatch(clause)) {
          settings.bulletChar = e.$2;
          applied.add('글머리 기호 → ${e.$3}');
          matched = true;
          break;
        }
      }
    }

    // 4) 구분선
    if (!matched && RegExp('구분선|가로선|---').hasMatch(clause)) {
      if (RegExp('없애|제거|삭제|빼').hasMatch(clause)) {
        settings.hrMode = 'remove';
        applied.add('구분선(---) 제거');
        matched = true;
      } else if (RegExp('살려|유지|남겨|보존').hasMatch(clause)) {
        settings.hrMode = 'keep';
        applied.add('구분선(---) 유지');
        matched = true;
      }
    }

    // 5) 강조
    if (!matched && RegExp('강조|굵은|굵게|볼드|bold|\\*\\*', caseSensitive: false).hasMatch(clause)) {
      if (RegExp('작은\\s*따옴표|홑따옴표|외따옴표').hasMatch(clause)) {
        settings.emphStyle = 'quoteSingle';
        applied.add("강조 → 작은따옴표 '강조'");
        matched = true;
      } else if (RegExp('큰\\s*따옴표|쌍따옴표').hasMatch(clause)) {
        settings.emphStyle = 'quoteDouble';
        applied.add('강조 → 큰따옴표 "강조"');
        matched = true;
      } else if (RegExp('없애|제거|빼').hasMatch(clause)) {
        settings.emphStyle = 'remove';
        applied.add('강조 마커 제거(플레인)');
        matched = true;
      } else if (RegExp('유지|그대로').hasMatch(clause)) {
        settings.emphStyle = 'keep';
        applied.add('강조 그대로 유지');
        matched = true;
      }
    }

    // 6) 출처
    if (!matched && RegExp('출처|인용|레퍼런스|참고\\s*링크').hasMatch(clause)) {
      if (RegExp('없애|제거|삭제|빼').hasMatch(clause)) {
        settings.removeCitations = true;
        applied.add('출처 링크 제거 켬');
        matched = true;
      } else if (RegExp('살려|유지|남겨').hasMatch(clause)) {
        settings.removeCitations = false;
        applied.add('출처 링크 유지');
        matched = true;
      }
    }

    // 7) 제목 스타일
    if (!matched && RegExp('제목|소제목').hasMatch(clause) && !clause.contains('줄')) {
      if (clause.contains('대괄호')) {
        settings.headingMode = 'bracket';
        applied.add('제목 → [대괄호]');
        matched = true;
      } else if (RegExp('기호|■').hasMatch(clause)) {
        settings.headingMode = 'prefix';
        applied.add('제목 → ■ 기호');
        matched = true;
      } else if (RegExp('텍스트만|글자만').hasMatch(clause)) {
        settings.headingMode = 'strip';
        applied.add('제목 → 텍스트만');
        matched = true;
      }
    }

    // 8) A를 B로 바꿔 (치환)
    if (!matched) {
      m = RegExp("['\"“”‘’]([^'\"“”‘’]+)['\"“”‘’]\\s*(?:을|를)?\\s*['\"“”‘’]([^'\"“”‘’]+)['\"“”‘’]\\s*(?:으로|로)\\s*(?:모두\\s*|전부\\s*|다\\s*)?(?:바꿔|바꾸|치환|교체|변경)")
              .firstMatch(clause) ??
          RegExp("([^\\s'\"“”‘’]+)\\s*(?:을|를)\\s*([^\\s'\"“”‘’]+)\\s*(?:으로|로)\\s*(?:모두\\s*|전부\\s*|다\\s*)?(?:바꿔|바꾸|치환|교체|변경)")
              .firstMatch(clause);
      if (m != null) {
        final find = m.group(1)!;
        final repl = m.group(2)!;
        final always = RegExp('항상|앞으로|매번|자동').hasMatch(clause);
        if (newBody.contains(find)) {
          newBody = newBody.split(find).join(repl);
          bodyChanged = true;
        }
        if (always) {
          settings.customRules.add(CustomRule(find: find, replace: repl));
        }
        applied.add('"$find" → "$repl" 바꾸기${always ? ' (자동 규칙 저장)' : ''}');
        matched = true;
      }
    }

    if (!matched) unknown.add(clause);
  }

  return WizardOutcome(applied: applied, unknown: unknown, body: newBody, bodyChanged: bodyChanged);
}

/// 숫자 보존 검증 (기획서 30절 NumberGuard 경량판)
String numberGuard(String before, String after) {
  List<String> nums(String s) =>
      RegExp(r'\d+(?:[.,]\d+)*%?').allMatches(s).map((m) => m.group(0)!).toList();
  final b = nums(before);
  final a = nums(after).toSet();
  final missing = b.where((x) => !a.contains(x)).toList();
  if (missing.isEmpty) return '';
  final head = missing.take(5).join(', ');
  return '주의: 원문의 숫자 ${b.length}개 중 ${missing.length}개가 결과에서 발견되지 않습니다 ($head${missing.length > 5 ? '…' : ''})';
}
