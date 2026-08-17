import Flutter
import UIKit

/// 다른 앱이 우리에게 파일을 열어 달라고 할 때 그 소식이 도착하는 자리.
///
/// 2026-08-18 소유자 신고 — "LLM 답변 문서(마크업파일)를 보고있다가,
/// 내보내기를 하면 앱 중에서 내 앱이 있다. 그런데 그 앱을 선택해도 내
/// 앱에서 열리질 않네. 그냥 내 앱 리스트페이지만 떡하니 열린다."
///
/// ## 왜 그랬나
///
/// AppDelegate 에 `application(_:open:options:)` 을 제대로 넣어 뒀다.
/// 그런데 **이 앱은 씬(UIScene) 방식이다.** SceneDelegate 가 있으면
/// UIKit 은 파일 열기 소식을 앱 델리게이트가 아니라 **씬 델리게이트에게**
/// 보낸다. 그러니 우리가 만들어 둔 받는 자리에는 아무것도 오지 않았다.
///
/// 앱이 켜지기는 한다 — 파일을 열라고 시스템이 앱을 띄우기 때문이다.
/// 그래서 "목록 화면만 떡하니" 뜬다. 문이 열렸는데 손님이 다른 문으로
/// 들어와 아무도 못 만난 셈이다.
///
/// 받는 자리가 **비어 있는 것**과 **없는 것**은 겉으로 똑같아 보인다.
/// 둘 다 아무 일도 안 일어난다. 그래서 이런 종류는 코드를 봐서는 안
/// 보이고, 실제로 파일을 던져 봐야 보인다.
///
/// ## 두 길로 들어온다
///
/// **앱이 이미 떠 있었으면** openURLContexts 로 온다. 그때는 다트가
/// 준비돼 있으니 바로 밀어 준다.
///
/// **앱이 꺼져 있었으면** 씬이 만들어질 때 connectionOptions 에 담겨
/// 온다. 그 시점에는 다트가 아직 없다. 밀어 봐야 아무도 못 받으므로
/// 서랍에 넣어 두고, 다트가 켜지면 가지러 온다(ShareIntake.take).
///
/// 하나만 붙이면 "처음엔 되는데 두 번째부터 안 된다"거나 그 반대가 된다.
class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    // 플러터가 창과 엔진을 먼저 만들게 둔다.
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    // 꺼져 있다가 파일 때문에 켜진 경우. 다트가 아직 없으니 서랍에 넣는다.
    for ctx in connectionOptions.urlContexts {
      ShareBridge.stash(url: ctx.url)
    }
  }

  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    var handled = false
    for ctx in URLContexts {
      if ShareBridge.take(url: ctx.url) { handled = true }
    }
    // 우리가 안 받은 주소는 플러터에게 넘긴다. 관심 없는 것까지 삼키면
    // 남의 기능(로그인 콜백 같은 것)이 조용히 죽는다.
    if !handled {
      super.scene(scene, openURLContexts: URLContexts)
    }
  }
}
