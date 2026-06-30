# Keep Flutter Foreground Task classes
-keep class com.ryanheise.foregroundtask.** { *; }
-keep class com.example.emage.** { *; }

# Keep callback methods
-keepclassmembers class * {
    @com.ryanheise.foregroundtask.annotation.ForegroundTaskCallback *;
}

# Keep service classes
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver

# Keep Flutter engine classes
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
