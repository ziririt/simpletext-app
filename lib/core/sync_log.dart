/// 동기화 기록 — 마지막 몇 바퀴에 무엇이 오갔나.
///
/// 왜 만들었나 (2026-08-27 소유자 요청). 동기화는 잘 될 때는 아무 말이
/// 없고, 안 될 때도 아무 말이 없다. "켜짐"이라는 초록 글씨 하나로는
/// "맥에서 쓴 글이 왜 아이폰에 두 시간째 안 오나"에 답할 수 없다.
/// 오간 것을 남겨 두면, 그 물음이 "8시 5분에 올라갔는데 10시 35분에
/// 받았다"라는 사실로 바뀐다. 사실이 있어야 고칠 수 있다.
///
/// 설계에서 정한 것 두 가지.
///
/// **빈 바퀴는 안 적는다.** 30초마다 한 바퀴가 도는데 대개는 오가는 것이
/// 없다. 그것까지 적으면 60칸이 30분 만에 '아무 일 없음'으로 가득 차서,
/// 정작 보고 싶은 어제 오후의 사건이 밀려 나간다. 마지막으로 확인한
/// 시각은 이미 따로 있다(lastSyncMs). 여기는 **사건만** 남긴다.
///
/// **실패는 빈 바퀴여도 적는다.** 아무것도 못 옮긴 채 끝난 바퀴야말로
/// 알아야 할 일이다.
library;

import 'dart:convert';

/// 한 바퀴에서 실제로 일어난 일.
class SyncEvent {
  /// 바퀴가 끝난 시각.
  final int atMs;

  /// 이 기기에서 창고로 올린 메모 수.
  final int up;

  /// 창고에서 이 기기로 받은 메모 수.
  final int down;

  /// 바퀴에 걸린 시간(밀리초).
  final int ms;

  /// 실패 사유. 성공이면 null.
  final String? err;

  const SyncEvent({
    required this.atMs,
    this.up = 0,
    this.down = 0,
    this.ms = 0,
    this.err,
  });

  bool get ok => err == null;

  /// 적어 둘 만한 바퀴인가. 위 머리말의 규칙이 여기 한 줄로 있다.
  bool get worthKeeping => !ok || up > 0 || down > 0;

  Map<String, dynamic> toJson() => {
        'at': atMs,
        if (up != 0) 'up': up,
        if (down != 0) 'dn': down,
        if (ms != 0) 'ms': ms,
        if (err != null) 'err': err,
      };

  static SyncEvent? fromJson(Object? o) {
    if (o is! Map) return null;
    final at = o['at'];
    if (at is! int) return null;
    final err = o['err'];
    return SyncEvent(
      atMs: at,
      up: o['up'] is int ? o['up'] as int : 0,
      down: o['dn'] is int ? o['dn'] as int : 0,
      ms: o['ms'] is int ? o['ms'] as int : 0,
      err: err is String && err.isNotEmpty ? err : null,
    );
  }
}

/// 고리 버퍼. 최신이 앞(0번)이다.
class SyncLog {
  /// 몇 개까지 들고 있나. 60이면 사건이 뜸한 기기에서 며칠치가 남는다.
  static const int kMax = 60;

  final List<SyncEvent> events;

  SyncLog([List<SyncEvent>? e]) : events = List<SyncEvent>.from(e ?? const []);

  bool get isEmpty => events.isEmpty;

  /// 적을 것이면 적고, 아니면 그냥 지나간다. 돌려주는 값은 '적었나'.
  bool add(SyncEvent e) {
    if (!e.worthKeeping) return false;
    events.insert(0, e);
    if (events.length > kMax) events.removeRange(kMax, events.length);
    return true;
  }

  /// 마지막으로 무언가를 올린 시각. 없으면 null.
  int? get lastUpMs {
    for (final e in events) {
      if (e.up > 0) return e.atMs;
    }
    return null;
  }

  /// 마지막으로 무언가를 받은 시각. 없으면 null.
  int? get lastDownMs {
    for (final e in events) {
      if (e.down > 0) return e.atMs;
    }
    return null;
  }

  String encode() => jsonEncode([for (final e in events) e.toJson()]);

  /// 깨진 글자가 와도 절대 던지지 않는다. 기록 하나 때문에 동기화가
  /// 멈추면 본말이 뒤집힌다.
  static SyncLog decode(String? s) {
    if (s == null || s.isEmpty) return SyncLog();
    try {
      final o = jsonDecode(s);
      if (o is! List) return SyncLog();
      final out = <SyncEvent>[];
      for (final x in o) {
        final e = SyncEvent.fromJson(x);
        if (e != null) out.add(e);
        if (out.length >= kMax) break;
      }
      return SyncLog(out);
    } catch (_) {
      return SyncLog();
    }
  }
}
