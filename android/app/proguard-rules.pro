# Flutter-specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# awesome_notifications specific rules
-keep class me.carda.** { *; }
-keep class me.carda.awesome_notifications.core.** { *; }
-keep class io.flutter.plugins.awesomenotifications.** { *; }

# SharedPreferences TypeToken Fix (CRITICAL for 0.10.0)
-keep class com.google.common.reflect.TypeToken { *; }
-keep class * extends com.google.common.reflect.TypeToken
-keep class com.google.gson.reflect.TypeToken { <fields>; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# SQLite Database Protection
-keep class * extends android.database.sqlite.SQLiteOpenHelper
-keep class android.database.** { *; }
-keep class androidx.sqlite.** { *; }
-dontwarn androidx.sqlite.**

# Android notifications framework
-keep class android.app.NotificationManager { *; }
-keep class androidx.core.app.NotificationCompat { *; }
-keep class androidx.core.app.NotificationCompat$* { *; }

# Scheduled notifications and alarms
-keep class android.app.AlarmManager { *; }
-keep class * extends android.content.BroadcastReceiver { *; }

# Native methods protection
-keepclasseswithmembernames class * {
    native <methods>;
}

# Serialization Support
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Annotations
-keepattributes *Annotation*
-keep @interface androidx.annotation.Keep
-keep @androidx.annotation.Keep class * {*;}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep *;
}

# GSON rules
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Firebase rules
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# SQLite-related rules
-keep class net.sqlcipher.** { *; }
-dontwarn net.sqlcipher.**

# Play Store Split Compatibility
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.splitcompat.**

# OpenStreetMap
-keep class org.osmdroid.** { *; }
-keep class org.mapsforge.** { *; }
-dontwarn org.osmdroid.**
-dontwarn org.mapsforge.**

# Geolocator & Location plugin
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.location.** { *; }
-dontwarn com.baseflow.**

# Path Provider & Shared Preferences
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Flutter Foreground Task Service
-keep class com.pravera.flutter_foreground_task.** { *; }
-keep class ** extends com.pravera.flutter_foreground_task.** { *; }
-dontwarn com.pravera.flutter_foreground_task.**
-keep class * extends android.app.Service { *; }
-keep class * extends java.lang.Thread { *; }

# Keep MainActivity and Application classes
-keep class dev.faisal.tafseer.MainActivity { *; }
-keep class dev.faisal.tafseer.Application { *; }
