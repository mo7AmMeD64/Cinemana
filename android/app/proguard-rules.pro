## Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

## OkHttp (used by http package)
-dontwarn okhttp3.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

## Kotlin
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }

## Keep model classes
-keep class com.cinemana.app.** { *; }
