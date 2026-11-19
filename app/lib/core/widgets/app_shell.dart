import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import 'ui.dart';

class NavItem {
  const NavItem(this.icon, this.label, {IconData? selectedIcon})
    : selectedIcon = selectedIcon ?? icon;

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Largura a partir da qual usamos a barra lateral (painel web/desktop).
const wideBreakpoint = 900.0;

/// Estrutura com navegação: barra lateral de vidro em telas largas
/// e barra inferior de vidro no celular.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.items,
    required this.index,
    required this.onSelect,
    required this.pages,
    required this.onLogout,
    this.sidebarFooter,
  });

  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onSelect;
  final List<Widget> pages;
  final VoidCallback onLogout;
  final Widget? sidebarFooter;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    final body = AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
    );

    return Scaffold(
      body: CinematicBackground(
        child: SafeArea(
          bottom: false,
          child: wide
              ? Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 0, 20),
                      child: _Sidebar(
                        items: items,
                        index: index,
                        onSelect: onSelect,
                        onLogout: onLogout,
                        footer: sidebarFooter,
                      ),
                    ),
                    Expanded(child: body),
                  ],
                )
              : Stack(
                  children: [
                    Positioned.fill(child: body),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12 + MediaQuery.paddingOf(context).bottom,
                      child: _BottomBar(
                        items: items,
                        index: index,
                        onSelect: onSelect,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Espaço a reservar no fim das listas para não ficar atrás da barra inferior.
double bottomBarInset(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= wideBreakpoint
    ? 32
    : 110 + MediaQuery.paddingOf(context).bottom;

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.items,
    required this.index,
    required this.onSelect,
    required this.onLogout,
    this.footer,
  });

  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: GlassCard(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: BrandLogo(size: 40, horizontal: true),
            ),
            const SizedBox(height: 36),
            for (final (i, item) in items.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _SideItem(
                  item: item,
                  selected: i == index,
                  onTap: () => onSelect(i),
                ),
              ),
            const Spacer(),
            ?footer,
            const Divider(height: 24),
            _SideItem(
              item: const NavItem(Icons.logout_rounded, 'Sair'),
              selected: false,
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _SideItem extends StatefulWidget {
  const _SideItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SideItem> createState() => _SideItemState();
}

class _SideItemState extends State<_SideItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.selected;
    final color = s ? const Color(0xFFFFE3B3) : AppColors.textMuted;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: s
                ? LinearGradient(
                    colors: [
                      AppColors.amber.withValues(alpha: 0.38),
                      AppColors.ember.withValues(alpha: 0.16),
                    ],
                  )
                : null,
            color: s
                ? null
                : (_hover ? const Color(0x0FFFFFFF) : Colors.transparent),
            border: Border.all(
              color: s
                  ? AppColors.amber.withValues(alpha: 0.6)
                  : Colors.transparent,
            ),
            boxShadow: [
              if (s)
                BoxShadow(
                  color: AppColors.glow.withValues(alpha: 0.25),
                  blurRadius: 20,
                ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                s ? widget.item.selectedIcon : widget.item.icon,
                color: s ? AppColors.amber : color,
                size: 22,
              ),
              const SizedBox(width: 14),
              Text(
                widget.item.label,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: s ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.items,
    required this.index,
    required this.onSelect,
  });

  final List<NavItem> items;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF261C13), Color(0xFF120D09)],
        ),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          for (final (i, item) in items.indexed)
            Expanded(
              child: _BottomItem(
                item: item,
                selected: i == index,
                onTap: () => onSelect(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.amber : AppColors.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: selected
                    ? AppColors.amber.withValues(alpha: 0.16)
                    : Colors.transparent,
                boxShadow: [
                  if (selected)
                    BoxShadow(
                      color: AppColors.glow.withValues(alpha: 0.35),
                      blurRadius: 18,
                    ),
                ],
              ),
              child: Icon(
                selected ? item.selectedIcon : item.icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Conteúdo rolável de uma aba, centralizado e com largura máxima.
class ShellPage extends StatelessWidget {
  const ShellPage({
    super.key,
    required this.children,
    this.maxWidth = 820,
    this.onRefresh,
  });

  final List<Widget> children;
  final double maxWidth;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    final list = ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        wide ? 32 : 16,
        20,
        bottomBarInset(context),
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ],
    );
    return onRefresh == null
        ? list
        : RefreshIndicator(onRefresh: onRefresh!, child: list);
  }
}
