/// 스토어 결제 — 앱과 App Store·Play 사이의 다리.
///
/// **판정 규칙은 여기에 없다.** 무엇이 프리미엄인지는 core/purchase_gate.dart가
/// 순수 함수로 들고 있고, 이 파일은 스토어에서 들은 것을 그 규칙에 넘기는
/// 일만 한다. 규칙과 다리를 섞으면 규칙을 시험할 수 없게 된다 — 그리고
/// 시험할 수 없는 규칙이 돈이 걸린 자리에 있으면 언젠가 반드시 샌다.
///
/// # 만료를 어떻게 아는가
///
/// 우리에게는 서버가 없고, 스토어가 주는 거래 기록에 만료 시각이 실려 오지도
/// 않는다. 대신 **StoreKit 2가 지금 살아 있는 권한만 돌려준다**는 성질을 쓴다
/// (in_app_purchase_storekit 0.4.11에서 기본으로 켜져 있다).
///
///   앱을 켤 때마다 restorePurchases()로 "이 사람 권한이 아직 살아 있나"를
///   묻는다. 살아 있으면 그 상품의 울타리를 오늘부터 다시 세운다. 결제가
///   끊기면 아무 응답도 안 오고, 울타리는 더 밀리지 않아 한 주기 남짓 뒤에
///   저절로 넘어간다.
///
/// 그래서 **답이 없다고 프리미엄을 뺏지 않는다.** 비행기 안이거나 스토어가
/// 잠깐 죽었을 뿐일 수 있다. 뺏는 일은 오직 시간이 한다.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'core/purchase_gate.dart';
import 'main.dart' show Store, deviceFamily;

class PurchaseService {
  PurchaseService._();

  static final PurchaseService instance = PurchaseService._();

  /// 이 판에서 결제를 팔 수 있는가. 웹·윈도우에는 붙일 스토어가 없다.
  bool get supported =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS || Platform.isAndroid);

  /// 화면이 다시 그려야 할 때 오르는 수. 상품 목록·진행 상태·오류가 바뀌면 오른다.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  final Map<String, ProductDetails> _products = <String, ProductDetails>{};

  /// 스토어가 준 상품 하나. 값은 **여기 것을 쓴다** — 우리가 적어 둔 숫자가
  /// 아니라 그 사람 나라의 실제 값이고, 통화 기호까지 스토어가 붙여 준다.
  ProductDetails? product(String id) => _products[id];

  bool get hasProducts => _products.isNotEmpty;

  bool booted = false;
  bool busy = false;
  String? lastError;

  StreamSubscription<List<PurchaseDetails>>? _sub;

  Future<void> boot() async {
    if (!supported || booted) return;
    booted = true;
    _sub = InAppPurchase.instance.purchaseStream.listen(
      _heard,
      onError: (Object e) {
        lastError = '$e';
        _bump();
      },
    );
    await loadProducts();
    await refresh();
  }

  Future<void> loadProducts() async {
    if (!supported) return;
    try {
      if (!await InAppPurchase.instance.isAvailable()) {
        lastError = 'store-unavailable';
        _bump();
        return;
      }
      final r = await InAppPurchase.instance
          .queryProductDetails(kPremiumProductIds.toSet());
      for (final p in r.productDetails) {
        _products[p.id] = p;
      }
      // 못 찾은 이름이 있으면 스토어 쪽 등록이 어긋난 것이다. 조용히 넘기면
      // 화면에 단추가 하나 없는 채로 나가고, 아무도 원인을 못 찾는다.
      if (r.notFoundIDs.isNotEmpty) {
        lastError = 'not-found: ${r.notFoundIDs.join(", ")}';
      }
      if (r.error != null) lastError = r.error!.message;
      _bump();
    } catch (e) {
      lastError = '$e';
      _bump();
    }
  }

  /// 스토어에 권한을 다시 묻는다. 앱을 켤 때와 뒤에서 돌아올 때 부른다.
  Future<void> refresh() async {
    if (!supported) return;
    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      lastError = '$e';
      _bump();
    }
  }

  /// 사람이 '구매 복원'을 눌렀을 때. 하는 일은 refresh와 같지만 화면에
  /// 진행 표시를 내주기 위해 따로 둔다.
  Future<void> restore() async {
    busy = true;
    lastError = null;
    _bump();
    await refresh();
    busy = false;
    _bump();
  }

  Future<void> buy(ProductDetails p) async {
    if (!supported) return;
    busy = true;
    lastError = null;
    _bump();
    try {
      // 구독도 buyNonConsumable로 산다 — 소모품이 아니기 때문이다.
      // buyConsumable로 사면 스토어가 '쓰고 없어지는 것'으로 다뤄
      // 복원이 안 된다.
      await InAppPurchase.instance
          .buyNonConsumable(purchaseParam: PurchaseParam(productDetails: p));
    } catch (e) {
      lastError = '$e';
      busy = false;
      _bump();
    }
  }

  Future<void> _heard(List<PurchaseDetails> list) async {
    for (final d in list) {
      switch (d.status) {
        case PurchaseStatus.pending:
          busy = true;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          busy = false;
          await _grant(d.productID);
        case PurchaseStatus.error:
          busy = false;
          lastError = d.error?.message ?? 'purchase-failed';
        case PurchaseStatus.canceled:
          busy = false;
      }
      // 이걸 안 부르면 애플·구글이 "아직 못 받았다"고 보고 같은 거래를
      // 앱 켤 때마다 다시 들이민다.
      if (d.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(d);
      }
    }
    _bump();
  }

  Future<void> _grant(String productId) async {
    if (!isPremiumProduct(productId)) return;
    final store = Store.instance;
    final s = store.settings;
    final now = DateTime.now();
    final family = deviceFamily();
    final next = s.ent.seen(productId: productId, family: family, at: now);
    final on = premiumHere(e: next, family: family, now: now);
    if (next == s.ent && on == s.premium) return;
    s.ent = next;
    s.premium = on;
    await store.persistSettings();
    store.bump();
  }

  void _bump() => revision.value++;

  void dispose() {
    unawaited(_sub?.cancel());
    _sub = null;
  }
}
