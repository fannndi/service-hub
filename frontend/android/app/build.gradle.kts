plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

fun loadProperties(path: String): Map<String, String> {
    val props = mutableMapOf<String, String>()
    val file = rootProject.file(path)
    if (file.exists()) {
        file.readLines().forEach { line ->
            val trimmed = line.trim()
            if (trimmed.isNotEmpty() && !trimmed.startsWith("#")) {
                val eq = trimmed.indexOf('=')
                if (eq > 0) {
                    props[trimmed.substring(0, eq).trim()] = trimmed.substring(eq + 1).trim()
                }
            }
        }
    }
    return props
}

val keystoreProps = loadProperties("key.properties")
val ksFile = if (keystoreProps.containsKey("storeFile")) {
    rootProject.file(keystoreProps["storeFile"]!!)
} else {
    null
}
val hasKeystore = ksFile != null && ksFile.exists()

android {
    namespace = "id.servisgadget.servisgadget_foundation"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "id.servisgadget.servisgadget_foundation"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    if (hasKeystore) {
        signingConfigs {
            create("release") {
                keyAlias = keystoreProps["keyAlias"]!!
                keyPassword = keystoreProps["keyPassword"]!!
                storeFile = ksFile!!
                storePassword = keystoreProps["storePassword"]!!
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
