import 'package:flutter/material.dart';

/// Bandeau de rayures inspiré du motif lamba de la charte graphique
/// (Mianara-Charte-graphique/Motifs/motif-lamba.svg), rejoué en widgets
/// pour éviter une dépendance SVG supplémentaire.
class LambaStripe extends StatelessWidget {
  const LambaStripe({this.height = 6, super.key});

  final double height;

  static const _widths = [24.0, 6.0, 6.0, 6.0, 12.0, 6.0, 24.0, 4.0];
  static const _colors = [
    Color(0xFF0E6B4F),
    Color(0xFF0E6B4F),
    Color(0xFFF2B33D),
    Color(0xFF0E6B4F),
    Color(0xFFC2492B),
    Color(0xFF0E6B4F),
    Color(0xFF0E6B4F),
    Color(0xFF12241D),
  ];

  @override
  Widget build(BuildContext context) => ClipRRect(
    child: SizedBox(
      height: height,
      child: Row(
        children: List.generate(
          _widths.length,
          (i) => Expanded(
            flex: (_widths[i] * 10).round(),
            child: ColoredBox(color: _colors[i]),
          ),
        ),
      ),
    ),
  );
}
