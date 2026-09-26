import 'package:flutter/material.dart';

import '../theme.dart';

class MianaraNavItem {
  const MianaraNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Barre de navigation compacte : seule l'icône est visible tant que l'onglet
/// n'est pas actif ; l'onglet actif s'élargit doucement pour révéler son
/// libellé à gauche de l'icône. Évite qu'un libellé long (ex. malagasy) ne se
/// retrouve coupé faute de place.
class MianaraNavBar extends StatelessWidget {
  const MianaraNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    super.key,
  });

  final List<MianaraNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark
          ? MianaraColors.surfaceRaisedDark
          : MianaraColors.surfaceRaised,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavButton(
                  item: items[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelect(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final MianaraNavItem item;
  final bool selected;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 280);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final green = isDark ? MianaraColors.greenDark : MianaraColors.green;
    final muted = isDark ? MianaraColors.mutedDark : MianaraColors.muted;
    final indicator = isDark
        ? MianaraColors.greenSoftDark
        : MianaraColors.greenSoft;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: _duration,
        curve: _curve,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 14 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected ? indicator : Colors.transparent,
          borderRadius: BorderRadius.circular(MianaraRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRect(
              child: AnimatedSize(
                duration: _duration,
                curve: _curve,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          item.label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: green,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            AnimatedSwitcher(
              duration: _duration,
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                key: ValueKey(selected),
                color: selected ? green : muted,
                size: 23,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
