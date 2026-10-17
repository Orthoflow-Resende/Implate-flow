# Tink (androidx.security) references Error Prone annotations that are not
# shipped at runtime. R8 treats those missing classes as a hard failure.
-dontwarn com.google.errorprone.annotations.CanIgnoreReturnValue
-dontwarn com.google.errorprone.annotations.CheckReturnValue
-dontwarn com.google.errorprone.annotations.Immutable
-dontwarn com.google.errorprone.annotations.RestrictedApi
