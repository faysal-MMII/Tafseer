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
-keep class io.flutter.plugins.awesomenotifications.** { *; }

# Android notifications framework
-keep class android.app.NotificationManager { *; }
-keep class androidx.core.app.NotificationCompat { *; }
-keep class androidx.core.app.NotificationCompat$* { *; }

# Scheduled notifications and alarms
-keep class android.app.AlarmManager { *; }
-keep class * extends android.content.BroadcastReceiver { *; }

# Entry points for release builds
-keep class * {
    native <methods>;
}

-keepattributes Annotation
-keep @interface androidx.annotation.Keep
-keep @androidx.annotation.Keep class * {*;}

# Firebase rules 
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Google Play Services 
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# SQLite-related rules
-keep class android.database.** { *; }
-keep class net.sqlcipher.** { *; }
-dontwarn net.sqlcipher.**

# Play Store Split Compatibility
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.splitcompat.**

# OpenStreetMap (flutter_map, latlong2)
-keep class org.osmdroid.** { *; }
-keep class org.mapsforge.** { *; }
-dontwarn org.osmdroid.**
-dontwarn org.mapsforge.**

# Geolocator & Location plugin (to avoid removing location-related classes)
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.location.** { *; }
-dontwarn com.baseflow.**

# Path Provider & Shared Preferences (to avoid breaking file operations)
-keep class io.flutter.plugins.pathprovider.** { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Keep MainActivity and Application classes
-keep class dev.faisal.tafseer.MainActivity { *; }
-keep class dev.faisal.tafseer.Application { *; }

# Keep JSON serialization 
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# To Ensure Reflection APIs work
-keepattributes *Annotation*
-keep @interface androidx.annotation.Keep
-keep @androidx.annotation.Keep class * {*;}
-keepclasseswithmembers class * {
    @androidx.annotation.Keep *;
}
