/// 웹. 구글이 그린 진짜 단추.
///
/// 생김새를 우리가 정할 수 있는 것은 여기 적은 몇 가지뿐이다. 글자도
/// 구글이 브라우저 언어에 맞춰 넣는다 — 우리 l10n 이 안 닿는 유일한 단추다.
/// 그래서 이 단추 위에 우리 말로 된 안내 한 줄을 따로 둔다.
library;

import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget googleSignInButton() => web.renderButton(
      configuration: web.GSIButtonConfiguration(
        theme: web.GSIButtonTheme.filledBlue,
        size: web.GSIButtonSize.large,
        shape: web.GSIButtonShape.pill,
        text: web.GSIButtonText.signinWith,
      ),
    );
