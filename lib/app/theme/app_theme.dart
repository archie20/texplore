import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

export 'notebook_colors.dart';

const serifFamily = 'Newsreader';
const sansFamily = 'Inter';
const monoFamily = 'JetBrains Mono';

const TextStyle monoStyle = TextStyle(
  fontFamily: monoFamily,
  fontSize: 12,
  height: 1.4,
);

FThemeData notebookTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors = dark ? _darkColors : _lightColors;
  return FThemeData(
    touch: false,
    debugLabel: dark ? 'Research notebook dark' : 'Research notebook light',
    colors: colors,
    typography: FTypography(
      display: FTypeface.inherit(
        colors: colors,
        touch: false,
        fontFamily: serifFamily,
      ),
      body: FTypeface.inherit(
        colors: colors,
        touch: false,
        fontFamily: sansFamily,
      ),
    ),
  );
}

final FColors _lightColors = FColors(
  brightness: Brightness.light,
  systemOverlayStyle: SystemUiOverlayStyle.dark,
  barrier: const Color(0x141A1A1A),
  background: const Color(0xFFFFFFFF),
  foreground: const Color(0xFF1A1A1A),
  primary: const Color(0xFF2C2622),
  primaryForeground: const Color(0xFFFFFFFF),
  secondary: const Color(0xFFF4F4F4),
  secondaryForeground: const Color(0xFF1A1A1A),
  muted: const Color(0xFFF3F3F3),
  mutedForeground: const Color(0xFF6E6E6E),
  destructive: const Color(0xFF9B3A3A),
  destructiveForeground: const Color(0xFFFAF9F6),
  error: const Color(0xFF9B3A3A),
  errorForeground: const Color(0xFFFAF9F6),
  card: const Color(0xFFFFFFFF),
  border: const Color(0xFFE6E6E6),
);

final FColors _darkColors = FColors(
  brightness: Brightness.dark,
  systemOverlayStyle: SystemUiOverlayStyle.light,
  barrier: const Color(0x99000000),
  background: const Color(0xFF16181D),
  foreground: const Color(0xFFE8E6E1),
  primary: const Color(0xFFE7E0D4),
  primaryForeground: const Color(0xFF12151A),
  secondary: const Color(0xFF262A32),
  secondaryForeground: const Color(0xFFE8E6E1),
  muted: const Color(0xFF262A32),
  mutedForeground: const Color(0xFFA39E96),
  destructive: const Color(0xFFE08B8B),
  destructiveForeground: const Color(0xFF1A1212),
  error: const Color(0xFFE08B8B),
  errorForeground: const Color(0xFF1A1212),
  card: const Color(0xFF1E2128),
  border: const Color(0xFF2C3038),
);
