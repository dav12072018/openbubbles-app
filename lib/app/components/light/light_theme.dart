import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Rounded LP3 Detail text for compact, readable conversation content.
const lightMessageTextStyle = TextStyle(
  fontFamily: 'Inter',
  fontSize: 14,
  height: 1.45,
  fontWeight: FontWeight.w400,
);

/// Flutter interpretation of the Light SDK's monochrome palette and typography.
/// Akkurat is licensed to Light hardware; use the app's existing Inter instead.
ThemeData createLightPhoneTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final background = dark ? Colors.black : Colors.white;
  final foreground = dark ? Colors.white : Colors.black;
  final secondary = dark ? const Color(0xFFBBBBBB) : const Color(0xFF666666);
  final surface = dark ? const Color(0xFF171717) : const Color(0xFFF2F2F2);
  final outline = dark ? const Color(0xFF555555) : const Color(0xFFAAAAAA);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: foreground,
    onPrimary: background,
    primaryContainer: foreground,
    onPrimaryContainer: background,
    secondary: foreground,
    onSecondary: background,
    secondaryContainer: surface,
    onSecondaryContainer: foreground,
    tertiary: foreground,
    onTertiary: background,
    tertiaryContainer: secondary,
    onTertiaryContainer: background,
    error: foreground,
    onError: background,
    errorContainer: surface,
    onErrorContainer: foreground,
    surface: surface,
    onSurface: foreground,
    background: background,
    onBackground: foreground,
    surfaceVariant: surface,
    onSurfaceVariant: secondary,
    outline: secondary,
    outlineVariant: outline,
    inverseSurface: foreground,
    onInverseSurface: background,
    inversePrimary: background,
    surfaceTint: Colors.transparent,
  );
  TextStyle type(double size, {Color? color}) => TextStyle(
        fontFamily: 'Inter',
        fontSize: size,
        height: 1.3,
        fontWeight: FontWeight.w400,
        color: color ?? foreground,
        letterSpacing: 0,
      );
  const square = RoundedRectangleBorder();
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: background,
    canvasColor: background,
    dividerColor: outline,
    splashFactory: NoSplash.splashFactory,
    textTheme: TextTheme(
      displayLarge: type(32),
      displayMedium: type(30),
      displaySmall: type(28),
      headlineLarge: type(28),
      headlineMedium: type(26),
      headlineSmall: type(24),
      titleLarge: type(22),
      titleMedium: type(20),
      titleSmall: type(18),
      bodyLarge: type(20),
      bodyMedium: type(18),
      bodySmall: type(14, color: secondary),
      labelLarge: type(16),
      labelMedium: type(14),
      labelSmall: type(12, color: secondary),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      foregroundColor: foreground,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: type(20),
      systemOverlayStyle:
          dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      shape: Border(bottom: BorderSide(color: outline, width: 0.5)),
    ),
    iconTheme: IconThemeData(color: foreground, size: 24),
    dividerTheme: DividerThemeData(color: outline, thickness: 0.5, space: 1),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
      foregroundColor: foreground,
      minimumSize: const Size(48, 48),
      shape: square,
      textStyle: type(16),
    )),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
      foregroundColor: foreground,
      minimumSize: const Size(48, 48),
      side: BorderSide(color: foreground),
      shape: square,
      textStyle: type(16),
    )),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
      foregroundColor: background,
      backgroundColor: foreground,
      elevation: 0,
      minimumSize: const Size(48, 48),
      shape: square,
    )),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: foreground,
      foregroundColor: background,
      elevation: 0,
      shape: square,
    ),
    dialogTheme: DialogTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: square),
    bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: square),
    popupMenuTheme: PopupMenuThemeData(
        color: background, surfaceTintColor: Colors.transparent, shape: square),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      hintStyle: type(18, color: secondary),
      border: UnderlineInputBorder(borderSide: BorderSide(color: outline)),
      focusedBorder:
          UnderlineInputBorder(borderSide: BorderSide(color: foreground)),
    ),
    textSelectionTheme: TextSelectionThemeData(
        cursorColor: foreground,
        selectionColor: foreground.withOpacity(0.25),
        selectionHandleColor: foreground),
  );
}
