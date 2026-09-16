// نسخة AGP/Kotlin المعتمدة في settings.gradle.kts — يجب أن تبقى متطابقة معها.
val agpVersion = "8.11.1"
val kotlinPluginVersion = "2.2.20"

allprojects {
    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        google()
        mavenCentral()
    }
}

// بعض حزم Flutter (flutter_localization, geocoding_android, stripe_android ...) ما زالت تعلن
// classpath خاص بها بنسخ AGP قديمة (7.3.1 / 7.4.2 ...) داخل buildscript الخاص بها.
// هذه النسخ لا تُستخدم فعلياً — الكلاسات تُحمَّل من classpath الجذر — لكن Gradle يحاول تنزيلها
// فيفشل البناء (مثال: Could not find builder-7.4.2.jar). لذلك نوحّد كل النسخ هنا
// ونضيف نفس المستودعات إلى buildscript الخاص بكل مشروع فرعي.
subprojects {
    buildscript.repositories.apply {
        maven { setUrl("https://maven.aliyun.com/repository/google") }
        google()
        mavenCentral()
    }
    buildscript.configurations.configureEach {
        resolutionStrategy.eachDependency {
            if (requested.group == "com.android.tools.build" && requested.name == "gradle") {
                useVersion(agpVersion)
            }
            if (requested.group == "org.jetbrains.kotlin" &&
                (requested.name == "kotlin-gradle-plugin" || requested.name == "kotlin-stdlib")
            ) {
                useVersion(kotlinPluginVersion)
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
