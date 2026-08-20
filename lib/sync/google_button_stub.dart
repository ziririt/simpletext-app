/// 웹이 아닌 자리. 구글 단추는 없다.
///
/// 여기서 이 단추를 그릴 일이 없다 — 폰과 맥은 우리가 signIn() 을 부른다.
library;

import 'package:flutter/widgets.dart';

/// 아무것도 안 그린다. 부르는 쪽이 kIsWeb 으로 이미 걸러 낸다.
Widget googleSignInButton() => const SizedBox.shrink();
