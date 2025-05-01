plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "net.in.mogam.bwinter"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "net.in.mogam.bwinter"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = (((System.currentTimeMillis() / 1000).toInt()))
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// バージョンコードを動的に生成してpubspec.yamlを更新するタスク
tasks.register("updateVersionCode") {
    doLast {
        val versionCode = (System.currentTimeMillis() / 1000).toInt()
        val pubspecFile = file("../../pubspec.yaml")
        val content = pubspecFile.readText().replace("__VERSION_CODE__", versionCode.toString())
        pubspecFile.writeText(content)
        println("Updated version code to $versionCode")
    }
}

// ビルド前にバージョンコードを更新
tasks.named("preBuild") {
    dependsOn("updateVersionCode")
}
