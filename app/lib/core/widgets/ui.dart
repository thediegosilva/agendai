import 'package:material_ui/material_ui.dart';

import '../theme.dart';

export 'cinematic_background.dart';

/// Vidro fosco com tom âmbar e borda que "pega luz" no topo.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(28),
    this.radius = 28,
    this.glow = false,
    this.highlight = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  /// Halo âmbar em volta do cartão (para destaques).
  final bool glow;

  /// Borda e fundo mais quentes (item selecionado, card principal).
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
          if (glow)
            BoxShadow(
              color: AppColors.glow.withValues(alpha: 0.22),
              blurRadius: 36,
              spreadRadius: -6,
            ),
        ],
      ),
      // Sem BackdropFilter: o desfoque em tempo real é o que mais pesa no
      // Android. Um fundo quente semi-opaco dá o mesmo efeito de vidro.
      child: ClipRRect(
        borderRadius: br,
        child: CustomPaint(
          foregroundPainter: _GlowBorderPainter(
            radius: radius,
            strong: highlight || glow,
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Color(0xC4150F0A)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: highlight
                      ? const [Color(0x47FFB45A), Color(0x17FF8A3D)]
                      : const [Color(0x2BFFC98A), Color(0x0AFFFFFF)],
                ),
              ),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowBorderPainter extends CustomPainter {
  _GlowBorderPainter({required this.radius, required this.strong});

  final double radius;
  final bool strong;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.75),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strong ? 1.5 : 1.1
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.amber.withValues(alpha: strong ? 0.85 : 0.5),
          AppColors.amber.withValues(alpha: strong ? 0.3 : 0.12),
          AppColors.ember.withValues(alpha: strong ? 0.45 : 0.18),
        ],
        stops: const [0, 0.55, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(_GlowBorderPainter old) =>
      old.radius != radius || old.strong != strong;
}

/// Círculo com ícone e brilho âmbar (categorias, serviços, estatísticas).
class GlowIcon extends StatelessWidget {
  const GlowIcon(this.icon, {super.key, this.size = 56});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: const Alignment(-0.3, -0.4),
        colors: [
          AppColors.amber.withValues(alpha: 0.45),
          const Color(0xFF3A2614),
        ],
      ),
      border: Border.all(color: AppColors.amber.withValues(alpha: 0.55)),
      boxShadow: [
        BoxShadow(
          color: AppColors.glow.withValues(alpha: 0.35),
          blurRadius: size * 0.45,
          spreadRadius: -size * 0.12,
        ),
      ],
    ),
    child: Icon(icon, color: const Color(0xFFFFE3B3), size: size * 0.48),
  );
}

/// Botão principal com degradê âmbar e brilho.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.height = 56,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final double height;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final textStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: const Color(0xFF1C1205),
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedScale(
        scale: _hover && enabled ? 1.02 : 1,
        duration: const Duration(milliseconds: 180),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: AppColors.brandGradient,
            border: Border.all(color: const Color(0x66FFF1D6)),
            boxShadow: [
              BoxShadow(
                color: AppColors.glow.withValues(
                  alpha: !enabled ? 0.0 : (_hover ? 0.6 : 0.38),
                ),
                blurRadius: _hover ? 36 : 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Opacity(
            opacity: widget.onPressed == null ? 0.45 : 1,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: enabled ? widget.onPressed : null,
                child: Center(
                  child: widget.loading
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF1C1205),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  widget.label,
                                  style: textStyle,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.icon != null) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  widget.icon,
                                  size: 20,
                                  color: const Color(0xFF1C1205),
                                ),
                              ],
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão secundário vermelho com contorno (ex.: "Cancelar").
class DangerOutlineButton extends StatelessWidget {
  const DangerOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.compact = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.danger,
      backgroundColor: AppColors.danger.withValues(alpha: 0.06),
      side: BorderSide(color: AppColors.danger.withValues(alpha: 0.7)),
      minimumSize: Size(compact ? 72 : 96, compact ? 34 : 42),
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    child: Text(label),
  );
}

/// Faz o filho surgir com fade + leve deslize, com atraso configurável
/// (use índices crescentes para um efeito em cascata).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  late final _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 60 * widget.index.clamp(0, 10)), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// Símbolo da marca: quadrado laranja com calendário e check.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.26),
      gradient: AppColors.brandGradient,
      border: Border.all(color: const Color(0x55FFF1D6)),
      boxShadow: [
        BoxShadow(
          color: AppColors.glow.withValues(alpha: 0.5),
          blurRadius: size * 0.6,
          spreadRadius: -size * 0.12,
        ),
      ],
    ),
    child: Icon(
      Icons.event_available_rounded,
      size: size * 0.58,
      color: const Color(0xFF1C1205),
    ),
  );
}

/// Nome da marca: "Agenda" + "í" laranja em degradê.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key, this.fontSize = 40});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.displaySmall?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -fontSize * 0.03,
      fontSize: fontSize,
      height: 1.1,
      shadows: [
        Shadow(
          color: AppColors.glow.withValues(alpha: 0.35),
          blurRadius: fontSize * 0.5,
        ),
      ],
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('Agenda', style: style),
        GradientText('í', style: style),
      ],
    );
  }
}

/// Logo completa: símbolo + nome (vertical ou horizontal).
class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 72,
    this.showName = true,
    this.horizontal = false,
  });

  final double size;
  final bool showName;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    if (!showName) return BrandMark(size: size);
    if (horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandMark(size: size),
          SizedBox(width: size * 0.3),
          BrandWordmark(fontSize: size * 0.68),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandMark(size: size),
        SizedBox(height: size * 0.25),
        BrandWordmark(fontSize: size * 0.6),
      ],
    );
  }
}

/// Texto pintado com o degradê da marca.
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => AppColors.brandGradient.createShader(r),
      child: Text(text, style: style),
    );
  }
}

/// Avatar redondo com as iniciais.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.size = 44});

  final String name;
  final double size;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4A3420), Color(0xFF2A1D12)],
      ),
      border: Border.all(color: AppColors.amber.withValues(alpha: 0.45)),
    ),
    child: Text(
      _initials,
      style: TextStyle(
        color: const Color(0xFFFFE3B3),
        fontWeight: FontWeight.w700,
        fontSize: size * 0.36,
      ),
    ),
  );
}

/// Snackbar padronizada para erros e sucessos.
void showAppSnack(BuildContext context, String message, {bool error = true}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: error ? AppColors.danger : AppColors.success,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
