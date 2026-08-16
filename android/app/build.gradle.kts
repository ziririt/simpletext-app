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
