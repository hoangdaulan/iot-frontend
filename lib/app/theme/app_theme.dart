import 'package:flutter/material.dart';
import 'package:gp1/generated/colors.gen.dart';
import 'package:solar_icons/solar_icons.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: ColorName.primary,
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: ColorName.white,

    textTheme: const TextTheme().apply(
      displayColor: ColorName.labelPrimary,
      bodyColor: ColorName.labelPrimary,
      decorationColor: ColorName.labelSecondary,
    ),

    colorScheme: const ColorScheme.light(
      primary: ColorName.primary,
      onPrimary: ColorName.white,
      secondary: ColorName.secondary,
      onSecondary: ColorName.white,
      error: ColorName.red,
      surface: ColorName.white,
      onSurface: ColorName.black,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: ColorName.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: ColorName.labelPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      iconTheme: IconThemeData(color: ColorName.labelPrimary),
    ),

    navigationBarTheme: const NavigationBarThemeData(
      labelTextStyle: WidgetStateProperty.fromMap({
        WidgetState.selected: TextStyle(
          color: ColorName.primary,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      }),
      indicatorColor: ColorName.primary,
    ),

    dividerColor: ColorName.gray5,
    dividerTheme: const DividerThemeData(color: ColorName.gray5, space: 0, thickness: 1),

    actionIconTheme: ActionIconThemeData(
      backButtonIconBuilder: (context) => const Icon(SolarIconsOutline.altArrowLeft),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: const BorderSide(color: ColorName.primary),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: ColorName.white,
      foregroundColor: ColorName.primary,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: ColorName.gray4),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      // filled: true,
      labelStyle: const TextStyle(color: ColorName.labelSecondary),
      hintStyle: const TextStyle(color: ColorName.labelSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      suffixIconConstraints: const BoxConstraints(),
      // fillColor: ColorName.white,
      // hoverColor: ColorName.white,
      // focusColor: ColorName.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ColorName.gray4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ColorName.gray4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ColorName.primary),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ColorName.red),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ColorName.red),
      ),
      errorStyle: const TextStyle(color: ColorName.red),
    ),
  );
}
