import 'package:flutter/material.dart';

/// Jetons de couleur Mianara (clair + sombre), alignés sur
/// Mianara-Charte-graphique/tokens-couleurs-typo.json.
abstract final class MianaraColors {
  // Surfaces
  static const paper = Color(0xFFF8F6F1);
  static const paperDark = Color(0xFF0F1A16);
  static const surfaceRaised = Color(0xFFFFFFFF);
  static const surfaceRaisedDark = Color(0xFF16241F);
  static const surfaceSunken = Color(0xFFEFEBE3);
  static const surfaceSunkenDark = Color(0xFF0B1411);
  static const line = Color(0xFFDCE3DE);
  static const lineDark = Color(0xFF2A3A33);
  static const lineStrong = Color(0xFF7A8B83);

  // Texte
  static const ink = Color(0xFF12241D);
  static const inkDark = Color(0xFFEEF3EF);
  static const muted = Color(0xFF4F5E57);
  static const mutedDark = Color(0xFFA7B5AE);

  // Vert ravinala (marque)
  static const green = Color(0xFF0E6B4F);
  static const greenDark = Color(0xFF4CC08F);
  static const greenHover = Color(0xFF0A4A37);
  static const greenSoft = Color(0xFFE6F2EC);
  static const greenSoftDark = Color(0xFF123A2C);
  static const onGreen = Color(0xFFFFFFFF);

  // Terre rouge (accent de marque)
  static const red = Color(0xFFC2492B);
  static const redDark = Color(0xFFF08A6C);
  static const redSoft = Color(0xFFFBEAE4);
  static const redSoftDark = Color(0xFF3A1D14);

  // Soleil (récompenses, progression, mise en avant)
  static const sun = Color(0xFFF2B33D);
  static const sunDark = Color(0xFFF5C35F);
  static const sunSoft = Color(0xFFFEF4DC);
  static const sunSoftDark = Color(0xFF3A2C0E);

  // États
  static const warning = Color(0xFF8A5A00);
  static const warningDark = Color(0xFFF5C35F);
  static const warningSoft = Color(0xFFFEF4DC);
  static const warningSoftDark = Color(0xFF3A2C0E);
  static const danger = Color(0xFFB42318);
  static const dangerDark = Color(0xFFF97066);
  static const dangerSoft = Color(0xFFFDECEA);
  static const dangerSoftDark = Color(0xFF3A1614);
  static const info = Color(0xFF1D5FA8);
  static const infoDark = Color(0xFF7DB4F0);
  static const infoSoft = Color(0xFFE8F0FA);
  static const infoSoftDark = Color(0xFF12263D);
}

/// Dégradés réutilisés pour les cartes vedettes et barres de progression.
abstract final class MianaraGradients {
  static const hero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [MianaraColors.green, MianaraColors.greenHover],
  );

  static const heroDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF16382C), Color(0xFF0B1411)],
  );

  static const progress = LinearGradient(
    colors: [MianaraColors.sun, MianaraColors.red],
  );
}

/// Rayons cohérents avec la charte (sm/md/lg/xl/pill).
abstract final class MianaraRadii {
  static const sm = 6.0;
  static const md = 10.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

abstract final class MianaraTheme {
  static ThemeData light = _build(Brightness.light);
  static ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final surface = isDark ? MianaraColors.paperDark : MianaraColors.paper;
    final surfaceRaised = isDark
        ? MianaraColors.surfaceRaisedDark
        : MianaraColors.surfaceRaised;
    final ink = isDark ? MianaraColors.inkDark : MianaraColors.ink;
    final muted = isDark ? MianaraColors.mutedDark : MianaraColors.muted;
    final green = isDark ? MianaraColors.greenDark : MianaraColors.green;
    final line = isDark ? MianaraColors.lineDark : MianaraColors.line;

    final textTheme = TextTheme(
      // display — écrans d'accueil/résultat
      displaySmall: TextStyle(
        color: ink,
        fontSize: 44,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.02,
        height: 1.15,
      ),
      // h1 — titre de page
      headlineMedium: TextStyle(
        color: ink,
        fontSize: 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.01,
        height: 1.2,
      ),
      // h2 — titre de section
      titleLarge: TextStyle(
        color: ink,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      // h3 — titre de carte
      titleMedium: TextStyle(
        color: ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      // body-lg — intro
      bodyLarge: TextStyle(color: ink, fontSize: 18, height: 1.5),
      // body — texte courant (jamais < 16px sur mobile)
      bodyMedium: TextStyle(color: muted, fontSize: 16, height: 1.5),
      // body-sm — métadonnées
      bodySmall: TextStyle(color: muted, fontSize: 14, height: 1.4),
      // label — boutons, champs, onglets
      labelLarge: TextStyle(
        color: ink,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      // overline — surtitres
      labelSmall: TextStyle(
        color: muted,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: surface,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: MianaraColors.green,
        brightness: brightness,
        primary: green,
        onPrimary: isDark ? MianaraColors.paperDark : MianaraColors.onGreen,
        secondary: isDark ? MianaraColors.sunDark : MianaraColors.sun,
        surface: surface,
        onSurface: ink,
        error: isDark ? MianaraColors.dangerDark : MianaraColors.danger,
      ),
      fontFamily: 'PlusJakartaSans',
      textTheme: textTheme,
      dividerColor: line,
      cardTheme: CardThemeData(
        color: surfaceRaised,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MianaraRadii.lg),
          side: BorderSide(color: line),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceRaised,
        labelStyle: TextStyle(color: muted, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MianaraRadii.md + 4),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MianaraRadii.md + 4),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MianaraRadii.md + 4),
          borderSide: BorderSide(color: green, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: green,
          foregroundColor: isDark
              ? MianaraColors.paperDark
              : MianaraColors.onGreen,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MianaraRadii.pill),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: green,
          side: BorderSide(color: line),
          minimumSize: const Size(54, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MianaraRadii.pill),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceRaised,
        selectedColor: isDark
            ? MianaraColors.greenSoftDark
            : MianaraColors.greenSoft,
        labelStyle: TextStyle(fontWeight: FontWeight.w700, color: ink),
        secondaryLabelStyle: TextStyle(fontWeight: FontWeight.w700, color: green),
        side: BorderSide(color: line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MianaraRadii.pill),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceRaised,
        elevation: 0,
        height: 84,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: isDark
            ? MianaraColors.greenSoftDark
            : MianaraColors.greenSoft,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MianaraRadii.pill),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            height: 1.2,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected) ? green : muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected) ? green : muted,
          ),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: green,
        linearTrackColor: isDark
            ? MianaraColors.greenSoftDark
            : MianaraColors.greenSoft,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? green
              : (isDark ? MianaraColors.mutedDark : Colors.white),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? (isDark ? MianaraColors.greenSoftDark : MianaraColors.greenSoft)
              : line,
        ),
      ),
    );
  }
}
