import 'package:flutter/material.dart';

const dreamMint = Color(0xFFA8E6CF);
const dreamInk = Color(0xFF0C1418);
const dreamSurface = Color(0xFF152027);
Color mutedColor(BuildContext context) =>
    Theme.of(context).colorScheme.onSurfaceVariant;

enum Appearance { dreamDark, midnightOled, aurora, pureLight, custom }

extension AppearanceLabel on Appearance {
  String get label => [
    'Dream Dark',
    'Midnight OLED',
    'Aurora',
    'Pure Light',
    'Theme Studio',
  ][index];
}

ThemeData dreamTheme(
  Appearance preset, {
  Color seed = dreamMint,
  double density = 0,
}) {
  final light = preset == Appearance.pureLight;
  final background = switch (preset) {
    Appearance.midnightOled => Colors.black,
    Appearance.aurora => const Color(0xFF101525),
    Appearance.pureLight => const Color(0xFFF6F5EF),
    _ => dreamInk,
  };
  final accent = preset == Appearance.aurora ? const Color(0xFFB9B3F8) : seed;
  final scheme =
      ColorScheme.fromSeed(
        seedColor: accent,
        brightness: light ? Brightness.light : Brightness.dark,
      ).copyWith(
        primary: light ? const Color(0xFF276C59) : accent,
        surface: background,
        onSurfaceVariant: light
            ? const Color(0xFF52626A)
            : const Color(0xFFA7B4BB),
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    fontFamily: 'Manrope',
    visualDensity: VisualDensity(horizontal: density, vertical: density),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontWeight: FontWeight.w700,
        fontSize: 20,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: light ? Colors.white : dreamSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.onSurface.withValues(alpha: .08),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 76,
      backgroundColor: background,
      indicatorColor: accent.withValues(alpha: .14),
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(
          fontFamily: 'Manrope',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.onSurface.withValues(alpha: .05),
      hintStyle: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

class DreamMark extends StatelessWidget {
  final double size;
  const DreamMark({super.key, this.size = 36});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    widthFactor: 1,
    heightFactor: 1,
    child: SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _DreamMarkPainter(Theme.of(context).colorScheme.primary),
      ),
    ),
  );
}

class _DreamMarkPainter extends CustomPainter {
  final Color color;
  _DreamMarkPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final moon = Path.combine(
      PathOperation.difference,
      Path()..addOval(rect.deflate(size.width * .08)),
      Path()..addOval(
        Rect.fromCircle(
          center: Offset(size.width * .69, size.height * .31),
          radius: size.width * .35,
        ),
      ),
    );
    canvas.drawPath(moon, Paint()..color = color);
    final star = Path()
      ..moveTo(size.width * .76, size.height * .48)
      ..lineTo(size.width * .8, size.height * .61)
      ..lineTo(size.width * .93, size.height * .65)
      ..lineTo(size.width * .8, size.height * .69)
      ..lineTo(size.width * .76, size.height * .82)
      ..lineTo(size.width * .72, size.height * .69)
      ..lineTo(size.width * .59, size.height * .65)
      ..lineTo(size.width * .72, size.height * .61)
      ..close();
    canvas.drawPath(star, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DreamMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
