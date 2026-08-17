import Flutter
import UIKit

/// 다른 앱이 우리에게 무언가를 건넬 때 그 소식이 도착하는 자리.
///
/// 2026-08-18 — 여기가 비어 있어서 '파일로 열기'가 통째로 안 됐다.
/// AppDelegate 에 받는 자리를 만들어 뒀는데, 씬(UIScene) 방식 앱에서는
/// UIKit 이 앱 델리게이트가 아니라 **씬 델리게이트에게** 보낸다.
///
/// 받는 자리가 **비어 있는 것**과 **없는 것**은 겉으로 똑같아 보인다.
/// 둘 다 아무 일도 안 일어난다. 그래서 이런 종류는 코드를 봐서는 안
/// 보이고, 실제로 던져 봐야 보인다.
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
    ShareBridge.stashInbox()
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

  /// 앱이 앞으로 나올 때마다 공유 확장이 놓고 간 것을 가져온다.
  ///
  /// 2026-08-18 — 공유 시트에서 우리를 고르면 확장이 글을 앱 그룹 창고에
  /// 놓고 끝난다. 확장은 앱을 열지 않는다(애플이 열어 준 길이 아니다).
  /// 그러니 앱이 스스로 창고를 확인해야 하고, 그 시점은 '앞으로 나올
  /// 때'다 — 그때가 사용자가 앱을 보고 있는 순간이기 때문이다.
  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    ShareBridge.pushInbox()
  }
}
