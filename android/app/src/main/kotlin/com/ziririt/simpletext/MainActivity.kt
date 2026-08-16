package com.ziririt.simpletext

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// 2026-08-16 앱 잠금 — local_auth가 안드로이드에서 생체 확인 창을 띄우려면
// AndroidX의 BiometricPrompt를 쓴다. 그건 FragmentActivity 위에서만 뜬다.
// FlutterActivity 그대로 두면 앱이 죽지 않고 조용히 실패한다(더 나쁘다).
class MainActivity : FlutterFragmentActivity() {

    // 2026-08-17 다른 앱에서 보낸 글 받기.
    //
    // 안드로이드는 공유를 '인텐트'로 보낸다. 앱이 꺼져 있으면 앱을 켜면서
    // 주고, 켜져 있으면 onNewIntent로 준다. **두 길이 다르므로 둘 다 받아야
    // 한다** — 하나만 받으면 "처음엔 되는데 두 번째부터 안 된다"가 된다.
    //
    // 받은 글을 여기서 바로 밀지 않고 서랍에 넣어 두는 이유: 인텐트는
    // 플러터 화면이 준비되기 전에 도착할 수 있다. 그때 밀면 아무도 안 듣는다.
    private var pending: String? = null
    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        val ch = MethodChannel(engine.dartExecutor.binaryMessenger, "skyblue/share")
        ch.setMethodCallHandler { call, result ->
            when (call.method) {
                // 다트가 준비되면 가지러 온다. 준 것은 서랍에서 지운다 —
                // 안 그러면 앱을 다시 켤 때마다 같은 글이 또 들어온다.
                "take" -> {
                    result.success(pending)
                    pending = null
                }
                else -> result.notImplemented()
            }
        }
        channel = ch
        pending = extract(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val text = extract(intent) ?: return
        val ch = channel
        if (ch != null) {
            // 이미 켜져 있으니 바로 밀어 준다.
            ch.invokeMethod("received", text)
        } else {
            pending = text
        }
    }

    /// 인텐트에서 글을 꺼낸다. 우리 것이 아니면 null.
    private fun extract(intent: Intent?): String? {
        if (intent == null) return null
        val text = when (intent.action) {
            Intent.ACTION_SEND ->
                if (intent.type?.startsWith("text/") == true) {
                    intent.getStringExtra(Intent.EXTRA_TEXT)
                } else {
                    null
                }
            // 어느 앱에서든 글자를 끌어 고르면 뜨는 메뉴. 공유 시트보다 손이
            // 덜 가서, 쓰는 사람은 이쪽을 더 자주 쓴다. 공짜로 얻는 자리라
            // 같이 받는다.
            Intent.ACTION_PROCESS_TEXT ->
                intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
            else -> null
        }
        return if (text.isNullOrBlank()) null else text
    }
}
