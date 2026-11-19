import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Fundo "sala de cinema": preto quente, luzes de projetor e bokeh
/// (círculos de luz desfocados) flutuando devagar.
///
/// Otimizado para celular: o movimento é lento, então atualizamos a ~30 fps
/// com um Timer em vez de redesenhar a cada vsync (60–120 Hz), e o bokeh usa
/// degradês radiais em vez de blur em tempo real.
class CinematicBackground extends StatefulWidget {
  const CinematicBackground({super.key, required this.child});

  final Widget child;

  @override
  State<CinematicBackground> createState() => _CinematicBackgroundState();
}

class _CinematicBackgroundState extends State<CinematicBackground> {
  static const _period = Duration(seconds: 40);
  static const _frame = Duration(milliseconds: 33);

  final _t = ValueNotifier<double>(0);
  final _clock = Stopwatch();
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respeita "remover animações" do sistema e telas fora de foco.
    final animate =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (animate && _timer == null) {
      _clock.start();
      _timer = Timer.periodic(_frame, (_) {
        _t.value =
            (_clock.elapsedMilliseconds % _period.inMilliseconds) /
            _period.inMilliseconds;
      });
    } else if (!animate) {
      _timer?.cancel();
      _timer = null;
      _clock.stop();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        RepaintBoundary(child: CustomPaint(painter: _CinemaPainter(_t))),
        // Vinheta: escurece as bordas como numa tela de cinema.
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.15,
                colors: [Colors.transparent, Color(0xD9000000)],
                stops: [0.5, 1],
              ),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Bokeh {
  const _Bokeh(this.x, this.y, this.r, this.alpha, this.speed, this.phase);

  final double x, y, r, alpha, speed, phase;
}

final _bokeh = () {
  final rnd = math.Random(7);
  return List.generate(22, (_) {
    final big = rnd.nextDouble() < 0.3;
    return _Bokeh(
      rnd.nextDouble(),
      rnd.nextDouble(),
      big ? 34 + rnd.nextDouble() * 44 : 9 + rnd.nextDouble() * 18,
      big ? 0.12 + rnd.nextDouble() * 0.14 : 0.3 + rnd.nextDouble() * 0.4,
      0.3 + rnd.nextDouble() * 0.7,
      rnd.nextDouble() * math.pi * 2,
    );
  });
}();

class _CinemaPainter extends CustomPainter {
  _CinemaPainter(this.t) : super(repaint: t);

  final ValueNotifier<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final a = t.value * 2 * math.pi;
    final s = size.longestSide;

    // Luzes grandes de projetor.
    _glow(
      canvas,
      Offset(
        size.width * (0.18 + 0.06 * math.sin(a)),
        size.height * (0.08 + 0.05 * math.cos(a)),
      ),
      s * 0.55,
      AppColors.amber.withValues(alpha: 0.16),
    );
    _glow(
      canvas,
      Offset(
        size.width * (0.9 + 0.05 * math.cos(a)),
        size.height * (0.85 + 0.06 * math.sin(a)),
      ),
      s * 0.5,
      AppColors.ember.withValues(alpha: 0.13),
    );
    _glow(
      canvas,
      Offset(size.width * 0.95, size.height * 0.2),
      s * 0.3,
      AppColors.glow.withValues(alpha: 0.08),
    );

    // Bokeh: sobe devagar e balança de leve. Degradê radial = aparência
    // desfocada sem o custo de blur.
    for (final b in _bokeh) {
      final y = (b.y - t.value * b.speed * 0.6) % 1.0;
      final x = b.x + 0.015 * math.sin(a * 2 * b.speed + b.phase);
      final pulse = 0.75 + 0.25 * math.sin(a * 3 + b.phase);
      final color = Color.lerp(
        AppColors.amber,
        AppColors.ember,
        b.phase / (math.pi * 2),
      )!.withValues(alpha: b.alpha * pulse);
      _glow(canvas, Offset(x * size.width, y * size.height), b.r, color);
    }
  }

  void _glow(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color,
          color.withValues(alpha: color.a * 0.55),
          color.withValues(alpha: 0),
        ],
        stops: const [0, 0.45, 1],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_CinemaPainter old) => old.t != t;
}
