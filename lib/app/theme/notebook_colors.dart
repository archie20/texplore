import 'package:flutter/widgets.dart';

/// Colours that Forui's scheme does not have: the paper canvas, edges, and
/// the small tick that marks which candidate a card belongs to.
class NotebookColors {
  const NotebookColors({
    required this.isDark,
    required this.canvas,
    required this.card,
    required this.hairline,
    required this.ink,
    required this.inkSoft,
    required this.edge,
    required this.edgeMuted,
    required this.dot,
    required this.banner,
    required this.ticks,
  });

  final bool isDark;
  final Color canvas;
  final Color card;
  final Color hairline;
  final Color ink;
  final Color inkSoft;
  final Color edge;
  final Color edgeMuted;
  final Color dot;
  final Color banner;
  final List<Color> ticks;

  static const light = NotebookColors(
    isDark: false,
    canvas: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    hairline: Color(0xFFE6E6E6),
    ink: Color(0xFF2C2622),
    inkSoft: Color(0x222C2622),
    edge: Color(0xFFD0D0D0),
    edgeMuted: Color(0xFFE3E3E3),
    dot: Color.fromARGB(255, 137, 137, 137),
    banner: Color(0xFF8A8A8A),
    ticks: [
      Color(0xFF2B4C7E),
      Color(0xFF3E6B5A),
      Color(0xFF8A5A2B),
      Color(0xFF5C4D7A),
      Color(0xFF3D6A78),
      Color(0xFF7A4E4E),
    ],
  );

  static const dark = NotebookColors(
    isDark: true,
    canvas: Color(0xFF16181D),
    card: Color(0xFF1E2128),
    hairline: Color(0xFF2C3038),
    ink: Color(0xFFE7E0D4),
    inkSoft: Color(0x33E7E0D4),
    edge: Color(0xFF3A404C),
    edgeMuted: Color(0xFF2A303A),
    dot: Color(0xFF2A2E36),
    banner: Color(0xFFA39E96),
    ticks: [
      Color(0xFF8EAFD6),
      Color(0xFF7DAB96),
      Color(0xFFD0A06A),
      Color(0xFFB3A4D4),
      Color(0xFF7EB4C2),
      Color(0xFFD4A0A0),
    ],
  );

  Color tickFor(int index) => ticks[index % ticks.length];
}

class NotebookScope extends InheritedWidget {
  const NotebookScope({required this.colors, required super.child, super.key});

  final NotebookColors colors;

  static NotebookColors of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NotebookScope>();
    assert(scope != null, 'NotebookScope is missing');
    return scope!.colors;
  }

  @override
  bool updateShouldNotify(NotebookScope oldWidget) =>
      oldWidget.colors.isDark != colors.isDark;
}

extension NotebookContext on BuildContext {
  NotebookColors get notebook => NotebookScope.of(this);
}
