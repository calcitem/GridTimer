# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep Flutter Local Notifications plugin classes
-keep class com.dexterous.** { *; }

# Keep AudioPlayers plugin classes
-keep class xyz.luan.audioplayers.** { *; }

# Keep Flutter TTS plugin classes
-keep class com.tundralabs.fluttertts.** { *; }

# Keep Hive classes (for data persistence)
-keep class ** implements io.hive.hive_flutter.** { *; }

# Keep Permission Handler plugin classes
-keep class com.baseflow.permissionhandler.** { *; }

# Gson (if used by any plugin)
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelables
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep R class members
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Keep annotations
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations

