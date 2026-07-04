# proguard-rules.pro
# Keep ML Kit text recognition classes used by google_mlkit_text_recognition plugin
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**
-keepclassmembers class com.google.mlkit.vision.text.** { *; }

# Keep ML Kit language-specific option classes (Japanese, Korean, Chinese, etc.)
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }

# General ML Kit keep rules (if other ML Kit modules used)
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Keep Firebase / Google Play Services classes sometimes referenced by reflection
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep any generated plugin registrant reflection usages (safety net)
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.common.** { *; }
