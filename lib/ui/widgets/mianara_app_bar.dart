import 'package:flutter/material.dart';

import '../app_language.dart';
import '../theme.dart';
import 'lamba_stripe.dart';

const double mianaraAppBarHeight = 68.0;

/// Barre d'application partagée par l'espace visiteur et l'espace connecté :
/// logo, sélecteur de langue (drapeaux) et liseré lamba. `trailing` ajoute
/// une action supplémentaire avant les drapeaux (ex. déconnexion).
class MianaraAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MianaraAppBar({
    required this.language,
    required this.onSelectLanguage,
    this.trailing,
    super.key,
  });

  final AppLanguage language;
  final ValueChanged<AppLanguage> onSelectLanguage;
  final Widget? trailing;

  @override
  Size get preferredSize => const Size.fromHeight(mianaraAppBarHeight + 4);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PreferredSize(
      preferredSize: preferredSize,
      child: Column(
        children: [
          Expanded(
            child: AppBar(
              toolbarHeight: mianaraAppBarHeight,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 20,
              title: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/branding/mianara-symbole.png',
                      width: 34,
                      height: 34,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Mianara',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 19,
                    ),
                  ),
                ],
              ),
              actions: [
                ?trailing,
                _LanguageFlags(language: language, onSelect: onSelectLanguage),
                const SizedBox(width: 20),
              ],
            ),
          ),
          LambaStripe(height: isDark ? 3 : 4),
        ],
      ),
    );
  }
}

class _LanguageFlags extends StatelessWidget {
  const _LanguageFlags({required this.language, required this.onSelect});

  final AppLanguage language;
  final ValueChanged<AppLanguage> onSelect;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _FlagButton(
        flag: '🇲🇬',
        tooltip: 'Malagasy',
        active: language == AppLanguage.malagasy,
        onTap: () => onSelect(AppLanguage.malagasy),
      ),
      const SizedBox(width: 6),
      _FlagButton(
        flag: '🇫🇷',
        tooltip: 'Français',
        active: language == AppLanguage.french,
        onTap: () => onSelect(AppLanguage.french),
      ),
    ],
  );
}

class _FlagButton extends StatelessWidget {
  const _FlagButton({
    required this.flag,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final String flag;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final green = Theme.of(context).colorScheme.primary;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: active ? 34 : 28,
          height: active ? 34 : 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: active
                  ? green
                  : MianaraColors.lineStrong.withValues(alpha: 0.35),
              width: active ? 2 : 1,
            ),
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: active ? 1 : 0.45,
            child: Text(flag, style: TextStyle(fontSize: active ? 16 : 13)),
          ),
        ),
      ),
    );
  }
}
