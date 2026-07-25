# ML Kit Text Recognition - Keep all
-keep class com.google.mlkit.vision.text.** { *; }

# Keep language-specific recognizers
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }

# Keep Flutter plugin
-keep class com.google_mlkit_text_recognition.** { *; }

# General ML Kit keeps
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-keep class com.google.mlkit.common.** { *; }
