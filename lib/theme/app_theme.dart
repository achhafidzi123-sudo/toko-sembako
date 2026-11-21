import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema aplikasi dirancang agar "user friendly":
/// - Warna kontras tinggi & jelas (hijau = aksi utama/uang, merah = peringatan)
/// - Ukuran font & tombol besar, nyaman untuk disentuh (minimal 48dp)
/// - Sudut membulat agar terasa ramah, tidak kaku
class AppColors {
  static const primary = Color(0xFF2E7D32); // hijau toko, identik dgn uang/segar
  static const primaryLight = Color(0xFFE8F5E9);
  static const accent = Color(0xFFFF8F00); // oranye untuk aksi sekunder/peringatan ringan
  static const danger = Color(0xFFD32F2F);
  static const bg = Color(0xFFF7F8FA);
  static const card = Colors.white;
  static const textDark = Color(0xFF1B1B1B);
  static const textMuted = Color(0xFF6B7280);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.bg,
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 16, color: AppColors.textDark),
      bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppColors.textMuted),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.headlineSmall,
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
