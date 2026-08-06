# Keep MLKit text recognition classes (loaded via reflection)
-keep class com.google.mlkit.vision.text.** { *; }
-keep class com.google.mlkit.common.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# Keep GMS MLKit model classes
-keep class com.google.android.gms.internal.mlkit_vision_text.** { *; }

# Optional MLKit language models are not bundled — suppress R8 warnings
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
