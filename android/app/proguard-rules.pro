# Flutter ProGuard / R8 rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class io.flutter.get.ui.** { *; }
-keepclassmembers class * implements io.flutter.embedding.engine.plugins.FlutterPlugin {
    public <init>();
}
