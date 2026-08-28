/// 아래에 더 있다는 것을 **보이게** 하는 껍데기.
///
/// 2026-08-29 소유자 지시 — "낮은 해상도에서는 메뉴·설정 하단에 가려진
/// 부분을 스크롤하면 더 많은 항목이 있다는 직관적인 UI가 필요하다."
///
/// ## 왜 필요한가
///
/// 목록이 화면보다 길면 굴릴 수 있다. 그런데 **굴릴 수 있다는 사실
/// 자체가 안 보인다.** 마지막 줄이 화면 끝에 딱 맞아떨어지면 사람은
/// 그것이 끝인 줄 안다. 있는 기능을 못 찾는 것은 없는 것과 같다.
///
/// 스크롤바를 늘 띄우는 길도 있지만, 애플 기기에서는 손을 대야 나타나는
/// 것이 관례라 가만히 있는 화면에서는 아무 말도 안 해 준다.
///
/// ## 무엇을 하나
///
/// 아래쪽 글이 서서히 옅어지고, 그 위에 작은 꺾쇠 하나가 뜬다. **끝까지
/// 내리면 사라진다.** 끝에서도 남아 있으면 그건 거짓말이고, 거짓말하는
/// 표시는 곧 아무도 안 믿는 표시가 된다.
///
/// 위쪽에도 같은 것을 둔다(위로 올라갈 데가 남았을 때). 긴 목록에서
/// 가운데쯤 있을 때 위아래가 다 열려 있다는 것이 보여야 한다.
library;

import 'package:flutter/material.dart';

class ScrollHint extends StatefulWidget {
  const ScrollHint({
    super.key,
    required this.controller,
    required this.child,
    this.color,
    this.showTop = true,
  });

  final ScrollController controller;
  final Widget child;

  /// 옅어지며 사라질 바탕색. 안 주면 화면 바탕을 쓴다.
  final Color? color;

  final bool showTop;

  @override
  State<ScrollHint> createState() => _ScrollHintState();
}

class _ScrollHintState extends State<ScrollHint> {
  bool _more = false;
  bool _above = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_check);
    // 첫 프레임에는 아직 잴 것이 없다. 그려진 다음에 잰다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_check);
    super.dispose();
  }

  void _check() {
    if (!mounted || !widget.controller.hasClients) return;
    final p = widget.controller.position;
    // 2픽셀은 봐준다. 끝에 닿아도 소수점 때문에 아주 조금 남는 일이 있다.
    final more = p.pixels < p.maxScrollExtent - 2;
    final above = p.pixels > p.minScrollExtent + 2;
    if (more == _more && above == _above) return;
    setState(() {
      _more = more;
      _above = above;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.color ?? Theme.of(context).scaffoldBackgroundColor;
    final ink = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    return Stack(
      children: [
        // 굴린 만큼을 계속 다시 재야 한다. 알림만으로는 목록이 늘거나
        // 줄었을 때를 못 잡는다.
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (_) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _check());
            return false;
          },
          child: widget.child,
        ),
        if (widget.showTop && _above)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 20,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bg, bg.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
        if (_more)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 34,
            child: IgnorePointer(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [bg, bg.withValues(alpha: 0)],
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        size: 20, color: ink.withValues(alpha: 0.55)),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
