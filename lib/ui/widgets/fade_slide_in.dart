import 'package:flutter/material.dart';

/// Fait apparaître [child] en fondu avec un léger glissement vers le haut.
/// Utilisé pour donner un peu de vie aux listes d'accueil sans surcharger
/// l'interface : chaque élément peut décaler son départ via [delay] pour un
/// effet d'apparition échelonnée.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    required this.child,
    this.delay = Duration.zero,
    this.offset = 16,
    super.key,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> {
  double _target = 0;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _target = 1;
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) setState(() => _target = 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: _target),
    duration: const Duration(milliseconds: 420),
    curve: Curves.easeOutCubic,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, (1 - value) * widget.offset),
        child: child,
      ),
    ),
    child: widget.child,
  );
}
