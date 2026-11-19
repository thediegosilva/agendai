import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/category.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/ui.dart';
import '../data/booking_repository.dart';
import '../data/models.dart';

class BusinessPage extends ConsumerWidget {
  const BusinessPage({super.key, required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final business = ref.watch(businessProvider(businessId));
    return Scaffold(
      body: CinematicBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: business.when(
                loading: () => const LoadingBox(height: 400),
                error: (e, _) => Column(
                  children: [
                    const RoundBackButton(),
                    ErrorRetry(
                      error: e,
                      onRetry: () =>
                          ref.invalidate(businessProvider(businessId)),
                    ),
                  ],
                ),
                data: (b) => _BusinessView(business: b),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão de voltar redondo de vidro.
class RoundBackButton extends StatelessWidget {
  const RoundBackButton({super.key, this.fallback = '/'});

  final String fallback;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: IconButton(
      tooltip: 'Voltar',
      style: IconButton.styleFrom(
        backgroundColor: const Color(0x1FFFC98A),
        foregroundColor: AppColors.amber,
        side: BorderSide(color: AppColors.amber.withValues(alpha: 0.35)),
      ),
      onPressed: () => context.canPop() ? context.pop() : context.go(fallback),
      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
    ),
  );
}

/// Agrupa dias seguidos com o mesmo horário: "Seg – Sex  09:00–19:00".
List<(String, String?)> groupHours(Business b) {
  const order = [1, 2, 3, 4, 5, 6, 0];
  String? hoursOf(int d) => switch (b.hoursFor(d)) {
    null => null,
    final h => '${formatMinute(h.openMinute)}–${formatMinute(h.closeMinute)}',
  };
  final groups = <(String, String?)>[];
  var start = 0;
  for (var i = 1; i <= order.length; i++) {
    if (i < order.length && hoursOf(order[i]) == hoursOf(order[start])) {
      continue;
    }
    final first = order[start], last = order[i - 1];
    final label = first == last
        ? weekdayLong[first]
        : '${weekdayShort[first]} – ${weekdayShort[last]}';
    groups.add((label, hoursOf(first)));
    start = i;
  }
  return groups;
}

class _BusinessView extends StatelessWidget {
  const _BusinessView({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) {
    final b = business;
    final theme = Theme.of(context);
    final cat = businessCategory(b.name, b.description);
    var i = 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        const RoundBackButton(),
        const SizedBox(height: 8),
        FadeSlideIn(
          index: i++,
          child: Column(
            children: [
              Text(
                b.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(cat.icon, size: 18, color: AppColors.amber),
                  const SizedBox(width: 6),
                  Text(
                    '${cat.label} · ${b.services.length} '
                    '${b.services.length == 1 ? 'serviço' : 'serviços'}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FadeSlideIn(
          index: i++,
          child: _Hero(business: b),
        ),
        const SizedBox(height: 28),
        FadeSlideIn(index: i++, child: const _AmberTitle('Serviços')),
        if (b.services.isEmpty)
          const EmptyState(
            icon: Icons.content_cut_rounded,
            title: 'Nenhum serviço disponível',
            message: 'Este estabelecimento ainda não cadastrou serviços.',
          )
        else
          for (final s in b.services)
            FadeSlideIn(
              index: i++,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ServiceTile(
                  service: s,
                  onTap: () => context.push('/business/${b.id}/book/${s.id}'),
                ),
              ),
            ),
        const SizedBox(height: 20),
        FadeSlideIn(
          index: i++,
          child: const _AmberTitle('Horário de funcionamento'),
        ),
        FadeSlideIn(
          index: i++,
          child: GlassCard(
            radius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              children: [
                for (final (label, hours) in groupHours(b))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: AppColors.amber,
                        ),
                        const SizedBox(width: 10),
                        Text(label, style: theme.textTheme.bodyLarge),
                        const Spacer(),
                        Text(
                          hours ?? 'Fechado',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: hours == null
                                ? AppColors.textMuted
                                : AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AmberTitle extends StatelessWidget {
  const _AmberTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(color: AppColors.amber),
    ),
  );
}

/// "Capa" do estabelecimento: palco iluminado com o ícone da categoria.
class _Hero extends StatelessWidget {
  const _Hero({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = businessCategory(business.name, business.description);
    return GlassCard(
      radius: 26,
      highlight: true,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 150,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.2),
                radius: 1.2,
                colors: [
                  Color(0x66FFB45A),
                  Color(0x14FF7A45),
                  Colors.transparent,
                ],
                stops: [0, 0.5, 1],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Luzes de palco.
                for (final x in [-0.85, -0.45, 0.45, 0.85])
                  Align(
                    alignment: Alignment(x, -0.75),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFE3B3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.glow.withValues(alpha: 0.9),
                            blurRadius: 22,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ),
                GlowIcon(cat.icon, size: 84),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (business.description != null)
                  Text(business.description!, style: theme.textTheme.bodyLarge),
                if (business.address != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: AppColors.amber,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          business.address!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatefulWidget {
  const _ServiceTile({required this.service, required this.onTap});

  final BusinessService service;
  final VoidCallback onTap;

  @override
  State<_ServiceTile> createState() => _ServiceTileState();
}

class _ServiceTileState extends State<_ServiceTile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Semantics(
          button: true,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            scale: _hover ? 1.015 : 1,
            child: GlassCard(
              radius: 22,
              glow: _hover,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GlowIcon(serviceIcon(s.name), size: 52),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: theme.textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '• ${formatDuration(s.durationMinutes)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GradientText(
                        formatMoney(s.priceCents),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Agendar →',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.amber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
