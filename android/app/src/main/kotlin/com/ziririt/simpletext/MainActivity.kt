package com.ziririt.simpletext

import io.flutter.embedding.android.FlutterFragmentActivity

// 2026-08-16 앱 잠금 — local_auth가 안드로이드에서 생체 확인 창을 띄우려면
// AndroidX의 BiometricPrompt를 쓴다. 그건 FragmentActivity 위에서만 뜬다.
// FlutterActivity 그대로 두면 앱이 죽지 않고 조용히 실패한다(더 나쁘다).
class MainActivity : FlutterFragmentActivity()
