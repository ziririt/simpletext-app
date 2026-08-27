/// 줄바꿈을 쳤을 때 목록을 이어 준다.
///
/// 2026-08-27 소유자 신고 — "목록의 마지막 행에서 엔터를 치면 자동으로
/// 다음 번호의 목록 또는 해당 글목록의 블릿이 유지되어야 하는데 안 된다."
///
/// 맞는 지적이다. 목록 단추는 **이미 쓴 줄들을 목록으로 바꾸는** 도구였다.
/// 그런데 사람은 목록을 그렇게 쓰지 않는다. 한 줄 쓰고, 엔터를 치고, 또
/// 한 줄 쓴다. 매 줄마다 단추로 돌아가야 하는 목록은 목록이 아니다.
///
/// ## 왜 화면과 떼어 놓았나
///
/// 이 규칙은 눈으로 보고는 틀린 줄 모른다. 들여쓰기를 물려받는가, 번호가
/// 1 씩 오르는가, 빈 항목에서 한 번 더 치면 빠져나오는가 — 어느 하나가
/// 어긋나도 화면에서는 그럴듯해 보인다. 그래서 시험을 쓸 수 있는 자리로
/// 꺼냈다. core/listify.dart 를 꺼낸 것과 같은 까닭이다.
///
/// ## 빈 항목에서 한 번 더 치면 빠져나온다
///
/// 이게 없으면 목록에서 나올 길이 없다. 마지막 항목을 쓰고 엔터를 치면
/// 새 표시가 붙고, 거기서 또 엔터를 치면 또 붙는다. 표시만 줄줄이 남은
/// 글이 된다. 빈 항목에서의 엔터는 **'목록 끝'이라는 뜻**이다. 모든
/// 글쓰기 도구가 이렇게 한다.
library;

import 'package:flutter/services.dart';

/// 줄바꿈 한 번에 무엇을 할까.
class ListStep {
  /// 줄바꿈 뒤에 이어 붙일 표시. '2. ' · '· ' · '- [ ] ' 따위.
  final String head;

  /// 커서 앞에서 걷어 낼 글자 수. 0 이 아니면 **빈 항목에서 친 엔터**라,
  /// 줄을 바꾸지 않고 표시만 지운다.
  final int strip;

  const ListStep({this.head = '', this.strip = 0});

  bool get ends => strip > 0;

  @override
  bool operator ==(Object other) =>
      other is ListStep && other.head == head && other.strip == strip;

  @override
  int get hashCode => Object.hash(head, strip);

  @override
  String toString() => 'ListStep(head: ${head.replaceAll(' ', '␣')}, strip: $strip)';
}

/// 할 일 — '- [ ] ' · '* [x] '
final RegExp _todo = RegExp(r'^([ \t]*)([-*]) \[[ xX]\] ');

/// 번호 — '1. ' · '12) '
final RegExp _num = RegExp(r'^([ \t]*)(\d+)([.)]) ');

/// 구분점·대시 — '· ' · '- ' · '• ' · '* '
final RegExp _bullet = RegExp(r'^([ \t]*)([•·*+\-–—]) ');

/// [caret] 자리에서 줄바꿈을 쳤다. 무엇을 할까. 목록이 아니면 null.
///
/// 커서가 줄 한가운데 있어도 이어 준다. 줄을 둘로 가르는 것도 목록을
/// 늘리는 일이고, 그때 새 줄이 표시 없이 시작하면 그게 더 놀랍다.
ListStep? listStep(String text, int caret) {
  if (caret < 0 || caret > text.length) return null;
  final nl = text.lastIndexOf('\n', caret > 0 ? caret - 1 : 0);
  final lineStart = (nl < 0 || caret == 0) ? 0 : nl + 1;
  if (lineStart > caret) return null;
  final upto = text.substring(lineStart, caret);

  // 표시 뒤에 알맹이가 없으면 '목록 끝'이다. 커서 앞을 통째로 걷는다.
  ListStep endHere() => ListStep(strip: caret - lineStart);

  final t = _todo.firstMatch(upto);
  if (t != null) {
    if (upto.substring(t.end).trim().isEmpty) return endHere();
    // 이어지는 항목은 늘 빈 네모다. 앞 줄이 끝난 일이라고 해서 다음 줄도
    // 끝났을 리 없다.
    return ListStep(head: '${t.group(1)}${t.group(2)} [ ] ');
  }

  final n = _num.firstMatch(upto);
  if (n != null) {
    if (upto.substring(n.end).trim().isEmpty) return endHere();
    final next = (int.tryParse(n.group(2)!) ?? 0) + 1;
    return ListStep(head: '${n.group(1)}$next${n.group(3)} ');
  }

  final b = _bullet.firstMatch(upto);
  if (b != null) {
    if (upto.substring(b.end).trim().isEmpty) return endHere();
    return ListStep(head: '${b.group(1)}${b.group(2)} ');
  }

  return null;
}

/// 글 칸에 물려 쓰는 자. 사람이 줄바꿈을 친 순간에만 끼어든다.
///
/// 자판의 엔터 키를 가로채지 않고 **글의 변화**를 보는 까닭 — 폰의 소프트
/// 자판은 키 신호를 안 준다. 입력 연결로 바뀐 글자만 온다. 키를 가로채는
/// 방식으로 짜면 맥에서만 되고 아이폰에서는 안 된다.
///
/// 끼어드는 조건을 좁게 잡았다. 글자가 **정확히 하나** 늘었고, 그 하나가
/// 줄바꿈이고, 그것을 도로 빼면 아까 글과 똑같아야 한다. 붙여넣기·자동
/// 완성·한글 조합이 지나갈 때 잘못 물지 않기 위해서다.
class ListContinueFormatter extends TextInputFormatter {
  const ListContinueFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue now) {
    if (!now.selection.isCollapsed) return now;
    final at = now.selection.baseOffset;
    if (at <= 0 || at > now.text.length) return now;
    if (now.text.length != old.text.length + 1) return now;
    if (now.text[at - 1] != '\n') return now;
    if (old.text != now.text.substring(0, at - 1) + now.text.substring(at)) {
      return now;
    }

    final step = listStep(old.text, at - 1);
    if (step == null) return now;

    if (step.ends) {
      final cut = at - 1 - step.strip;
      if (cut < 0) return now;
      final text = old.text.substring(0, cut) + old.text.substring(at - 1);
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: cut),
      );
    }

    final text = now.text.substring(0, at) + step.head + now.text.substring(at);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: at + step.head.length),
    );
  }
}
