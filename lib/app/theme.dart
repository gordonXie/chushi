import 'package:flutter/material.dart';

/// 认认的视觉基调：奶油底色 + 低饱和糖果色 + 大圆角，整体偏可爱、克制。
/// 只用一个主色（珊瑚橘）加两个辅助色，避免彩虹色。
class AppColors {
  static const cream = Color(0xFFFFF8F0);
  static const ink = Color(0xFF4A3F35);
  static const inkSoft = Color(0xFF8A7B6C);
  static const coral = Color(0xFFFF8A6B);
  static const coralSoft = Color(0xFFFFE3D9);
  static const mint = Color(0xFF9FD8C0);
  static const mintSoft = Color(0xFFDFF3EA);
  static const sky = Color(0xFFA9D3F0);
  static const skySoft = Color(0xFFE3F1FB);
  static const sunny = Color(0xFFFFD98A);
  static const sunnySoft = Color(0xFFFFF0D2);
  static const line = Color(0xFFEFE3D5);

  /// 卡片背景轮换用，保证相邻卡片不撞色。
  static const cardTints = [coralSoft, mintSoft, skySoft, sunnySoft];
}

class AppTheme {
  static const double radius = 24;
  static const double cardRadius = 20;
  static const double touchMin = 56;

  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.coral,
        primary: AppColors.coral,
        surface: AppColors.cream,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.cream,
    );

    return base.copyWith(
      textTheme: base.textTheme
          .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
          .copyWith(
            titleLarge: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, height: 1.3),
            titleMedium: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.w600, height: 1.3),
            bodyMedium: const TextStyle(fontSize: 15, height: 1.5),
            bodySmall: const TextStyle(
                fontSize: 13, height: 1.5, color: AppColors.inkSoft),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink),
        iconTheme: IconThemeData(color: AppColors.ink),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.coral,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(0, 52),
          side: const BorderSide(color: AppColors.line, width: 1.4),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.coral
              : AppColors.line,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
