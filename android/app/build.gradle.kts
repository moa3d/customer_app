import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Google Services تُفعَّل فقط عند وجود google-services.json — فيبقى البناء
// يعمل حتى قبل إنزال الملف من Firebase Console ولا تفشل أخطاء غامضة.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// توقيع الإصدار — يُقرأ من android/key.properties (غير متعقَّب في git).
// عند غياب الملف أو نقص أحد حقوله أو ضياع ملف المفتاح، يبقى الإصدار موقَّعاً
// بمفاتيح debug كما كان، فلا ينكسر `flutter run --release` عند من لا يملك
// المفتاح — لكن حزمة موقَّعة بـdebug لا تُقبل على Google Play.
val keystoreProperties = Properties().apply {
    val propsFile = rootProject.file("key.properties")
    if (propsFile.exists()) propsFile.inputStream().use { load(it) }
}

val hasKeystoreFields = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
    .all { !keystoreProperties.getProperty(it).isNullOrBlank() }

val releaseStoreFile = keystoreProperties.getProperty("storeFile")
    ?.let { rootProject.file(it) }
    ?.takeIf { hasKeystoreFields && it.exists() }

android {
    namespace = "com.nomnow.app"
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
        applicationId = "com.nomnow.app"
        minSdk = flutter.minSdkVersion                             // مطلوب لـ flutter_secure_storage
        targetSdk = 34       // متوافق مع أحدث متطلبات جوجل بلاي
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true

        // مفتاح خرائط غوغل يُقرأ من local.properties (غير متعقَّب في git)
        // بدل كتابته داخل AndroidManifest المرفوع مع الكود.
        // البناء لا يفشل عند غيابه — تظهر الخريطة فارغة فقط، فيبقى بناء
        // بقية التطبيق ممكناً لمن لا يملك المفتاح.
        val mapsApiKey: String = Properties().apply {
            val propsFile = rootProject.file("local.properties")
            if (propsFile.exists()) propsFile.inputStream().use { load(it) }
        }.getProperty("MAPS_API_KEY") ?: ""
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    signingConfigs {
        if (releaseStoreFile != null) {
            create("release") {
                storeFile = releaseStoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseStoreFile != null) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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

dependencies {
    implementation("com.google.android.material:material:1.12.0")
}
