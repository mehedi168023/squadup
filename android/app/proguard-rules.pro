# ----------------------------------------------------------------------------
# SquadUp release ProGuard/R8 rules.
# R8 is enabled for the release build (minify + resource shrink). These keeps
# prevent reflection-based plugins from being stripped/obfuscated.
# ----------------------------------------------------------------------------

# Flutter engine + embedding.
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# flutter_local_notifications uses Gson + reflection over its model classes.
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep enum values() / valueOf() (used reflectively by serializers).
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Silence warnings from optional annotation deps pulled in transitively.
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
