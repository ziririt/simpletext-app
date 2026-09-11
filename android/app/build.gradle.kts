import java.util.Properties

// 2026-08-17 배포 서명.
//
// 여태 배포판을 **개발용 열쇠로 서명하고 있었다**(플러터 기본값). 그 열쇠는
// 안드로이드 SDK에 딸려 오는 것이라 누구나 같은 것을 갖고 있다 — 아무나
// 자기 것인 척 갱신판을 낼 수 있다는 뜻이고, 그래서 플레이 스토어가 받지 않는다.
//
// 열쇠는 android/key.properties에 적어 두고 저장소에는 올리지 않는다.
// 파일이 없으면 개발용으로 물러선다 — 없다고 빌드가 죽으면 남의 컴퓨터에서
// `flutter run --release`가 안 되기 때문이다.
val keystoreFile = rootProject.file("key.properties")
val keystore = Properties().apply {
    if (keystoreFile.exists()) keystoreFile.inputStream().use { load(it) }
}

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.ziririt.simpletext"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // 아이폰·맥과 같은 식별자를 쓴다. 한 번 정하면 바꿀 수 없다 —
        // 바꾸면 스토어에서 아예 다른 앱이 되고, 쓰던 사람은 갱신을 못 받는다.
        applicationId = "com.ziririt.simpletext"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        // **여기는 아직 손대지 않았다. 플레이에 내기 전에 고칠 것.**
        //
        // flutter.versionName 은 pubspec 의 version 인데, 2026-09-12 개편으로
        // 그 값은 사람이 정한 이름이 아니라 **빌드 번호에서 자동으로 만든
        // 기계용 값**이 됐다(3.245.0). 애플이 꾸러미 버전을 못 내리게 해서
        // 생긴 값이라(ITMS-90062, lib/version.dart 머리말) 사람에게 보일
        // 이름이 아니다. 지금 이대로 플레이에 내면 스토어에 '3.245.0' 이
        // 찍힌다. 애플은 '1.7' 인데.
        //
        // 구글은 versionName 에 그런 제약이 없으니, lib/version.dart 의
        // appVersion('1.7')을 읽어서 넣으면 된다. 한 줄이면 되는 일인데
        // **이 맥에는 자바가 없어 그래들을 돌려 볼 수가 없어서** 확인 못 한
        // 코드를 빌드 파일에 두지 않는다(2026-09-12). 안드로이드를 실제로
        // 굽는 자리가 생기면 그때 고치고 거기서 확인한다.
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystoreFile.exists()) {
                storeFile = rootProject.file(keystore["storeFile"] as String)
                storePassword = keystore["storePassword"] as String
                keyAlias = keystore["keyAlias"] as String
                keyPassword = keystore["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // 2026-08-17 — 릴리스 앱이 켜자마자 죽었다. 실제 로그:
            //
            //   java.lang.RuntimeException: Unable to get provider
            //   androidx.startup.InitializationProvider:
            //   Failed to create an instance of androidx.work.impl.WorkDatabase
            //
            // 까닭. 애드몹(play-services-ads)이 WorkManager를 끌고 들어오고,
            // WorkManager는 Room으로 데이터베이스를 만든다. Room은 컴파일 때
            // 생성된 클래스를 **이름으로 찾아** 만드는데(WorkDatabase_Impl),
            // R8이 그 이름을 줄여 버리면 못 찾는다. 그래서 앱이 첫 프레임도
            // 못 그리고 죽는다.
            //
            // 이 고장의 못된 점은 **디버그로는 절대 안 난다**는 것이다.
            // R8은 릴리스에서만 돈다. 그러니 `flutter run`으로는 백 번을
            // 해도 멀쩡하고, 스토어에 올린 판만 죽는다.
            //
            // 지금은 줄이기를 끈다. 켜 두려면 Room·WorkManager를 남기라는
            // 규칙을 손으로 적어야 하는데, 그 규칙이 맞는지는 **릴리스로
            // 빌드해서 실제 기기에서 켜 봐야만** 알 수 있다. 스토어에 처음
            // 내는 자리에서 그런 것을 안고 갈 이유가 없다.
            //
            // 값으로 치르는 것: APK가 몇 메가 커진다. 이 앱은 62MB이고 그중
            // 대부분이 플러터 엔진이라 비율로는 얼마 안 된다. 앱이 켜지는
            // 것과 몇 메가는 견줄 것이 아니다.
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = if (keystoreFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // 열쇠가 없는 컴퓨터에서도 `flutter run --release`는 돌아야 한다.
                // 다만 이 결과물은 스토어에 올릴 수 없다.
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
