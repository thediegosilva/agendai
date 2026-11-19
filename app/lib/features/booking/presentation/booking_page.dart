import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api_client.dart';
import '../../../core/category.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/ui.dart';
import '../data/booking_repository.dart';
import '../data/models.dart';
import 'business_page.dart' show RoundBackButton;

/// Quantos dias à frente o cliente pode agendar.
const _daysAhead = 21;

DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({
    super.key,
    required this.businessId,
    required this.serviceId,
  });

  final String businessId;
  final String serviceId;

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  DateTime? _day;
  DateTime? _slot;
  bool _booking = false;

  SlotsArgs _args(DateTime day) =>
      (businessId: widget.businessId, serviceId: widget.serviceId, day: day);

  Future<void> _confirm(Business business, BusinessService service) async {
    final slot = _slot!;
    setState(() => _booking = true);
    try {
      await ref.read(bookingRepositoryProvider).book(service.id, slot);
      ref.invalidate(myAppointmentsProvider);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _SuccessDialog(
          business: business,
          service: service,
          startsAt: slot,
        ),
      );
      if (mounted) context.go('/');
    } on DioException catch (e) {
      if (!mounted) return;
      showAppSnack(context, apiErrorMessage(e));
      if (e.response?.statusCode == 409) {
        // Alguém pegou o horário antes: recarrega a grade.
        setState(() => _slot = null);
        ref.invalidate(slotsProvider(_args(_day!)));
      }
    } finally {
      if (mounted) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(businessProvider(widget.businessId));
    return Scaffold(
      body: CinematicBackground(
        child: SafeArea(
          child: business.when(
            loading: () => const LoadingBox(height: 400),
            error: (e, _) => ErrorRetry(
              error: e,
              onRetry: () =>
                  ref.invalidate(businessProvider(widget.businessId)),
            ),
            data: (b) {
              final service = b.services
                  .where((s) => s.id == widget.serviceId)
                  .firstOrNull;
              if (service == null) {
                return const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Serviço não encontrado',
                );
              }
              final today = _today();
              _day ??=
                  List.generate(
                    _daysAhead,
                    (i) => today.add(Duration(days: i)),
                  ).firstWhere(
                    (d) => b.hoursFor(weekdayIndex(d)) != null,
                    orElse: () => today,
                  );
              return _buildContent(context, b, service);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Business b,
    BusinessService service,
  ) {
    final theme = Theme.of(context);
    final day = _day!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Row(
                    children: [
                      RoundBackButton(fallback: '/business/${b.id}'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Escolha dia e horário',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FadeSlideIn(
                    child: GlassCard(
                      radius: 22,
                      highlight: true,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          GlowIcon(serviceIcon(service.name), size: 50),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.name,
                                  style: theme.textTheme.titleMedium,
                                ),
                                Text(
                                  '${b.name} · ${formatDuration(service.durationMinutes)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GradientText(
                            formatMoney(service.priceCents),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeSlideIn(
                    index: 1,
                    child: _CalendarGrid(
                      business: b,
                      selected: day,
                      onSelect: (d) => setState(() {
                        _day = d;
                        _slot = null;
                      }),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Horários · ${formatRelativeDay(day)}',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  _SlotsGrid(
                    closed: b.hoursFor(weekdayIndex(day)) == null,
                    slots: ref.watch(slotsProvider(_args(day))),
                    selected: _slot,
                    onSelect: (s) => setState(() => _slot = s),
                    onRetry: () => ref.invalidate(slotsProvider(_args(day))),
                  ),
                ],
              ),
            ),
            _ConfirmBar(
              slot: _slot,
              price: service.priceCents,
              loading: _booking,
              onConfirm: () => _confirm(b, service),
            ),
          ],
        ),
      ),
    );
  }
}

/// Calendário em grade (semana começando no domingo), dos próximos 21 dias.
class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.business,
    required this.selected,
    required this.onSelect,
  });

  final Business business;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = _today();
    final last = today.add(const Duration(days: _daysAhead - 1));
    final start = today.subtract(Duration(days: weekdayIndex(today)));
    final end = last.add(Duration(days: 6 - weekdayIndex(last)));
    final days = [
      for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1)))
        d,
    ];
    final months = {today.month, last.month}.toList();
    final title = months.length == 1
        ? '${monthLong[today.month - 1]} ${today.year}'
        : '${monthLong[today.month - 1]} – ${monthLong[last.month - 1]}';

    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: AppColors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title[0].toUpperCase() + title.substring(1),
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final w in weekdayShort)
                Expanded(
                  child: Text(
                    w.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.95,
            children: [
              for (final d in days)
                _DayCell(
                  day: d,
                  outOfRange: d.isBefore(today) || d.isAfter(last),
                  closed: business.hoursFor(weekdayIndex(d)) == null,
                  selected: isSameDay(d, selected),
                  isToday: isSameDay(d, today),
                  onTap: () => onSelect(d),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.outOfRange,
    required this.closed,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime day;
  final bool outOfRange;
  final bool closed;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (outOfRange) {
      return Center(
        child: Text(
          '${day.day}',
          style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.25)),
        ),
      );
    }
    final enabled = !closed;
    final fg = selected
        ? const Color(0xFF1C1205)
        : closed
        ? AppColors.textMuted.withValues(alpha: 0.45)
        : AppColors.text;

    return Semantics(
      button: enabled,
      selected: selected,
      label: formatDayShort(day),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: selected ? AppColors.brandGradient : null,
              color: selected
                  ? null
                  : closed
                  ? Colors.transparent
                  : const Color(0x14FFFFFF),
              border: Border.all(
                color: selected
                    ? const Color(0x88FFF1D6)
                    : isToday
                    ? AppColors.amber.withValues(alpha: 0.6)
                    : closed
                    ? const Color(0x0FFFFFFF)
                    : AppColors.outline,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: AppColors.glow.withValues(alpha: 0.5),
                    blurRadius: 18,
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${day.day}',
                  style: TextStyle(
                    color: fg,
                    fontSize: 16,
                    fontWeight: selected || isToday
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
                if (closed)
                  // Dia fechado: riscado em "X".
                  Positioned.fill(child: CustomPaint(painter: _CrossPainter()))
                else if (!selected)
                  Positioned(
                    bottom: 6,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.amber,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    const inset = 10.0;
    canvas
      ..drawLine(
        const Offset(inset, inset),
        Offset(size.width - inset, size.height - inset),
        p,
      )
      ..drawLine(
        Offset(size.width - inset, inset),
        Offset(inset, size.height - inset),
        p,
      );
  }

  @override
  bool shouldRepaint(_CrossPainter oldDelegate) => false;
}

class _SlotsGrid extends StatelessWidget {
  const _SlotsGrid({
    required this.closed,
    required this.slots,
    required this.selected,
    required this.onSelect,
    required this.onRetry,
  });

  final bool closed;
  final AsyncValue<List<DateTime>> slots;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (closed) {
      return const EmptyState(
        icon: Icons.door_front_door_outlined,
        title: 'Fechado neste dia',
        message: 'Escolha outro dia no calendário.',
      );
    }
    return slots.when(
      loading: () => const LoadingBox(height: 120),
      error: (e, _) => ErrorRetry(error: e, onRetry: onRetry),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.event_busy_rounded,
            title: 'Sem horários livres',
            message: 'Esse dia lotou. Que tal o próximo?',
          );
        }
        final groups = [
          ('Manhã', Icons.wb_sunny_rounded, list.where((s) => s.hour < 12)),
          (
            'Tarde',
            Icons.wb_twilight_rounded,
            list.where((s) => s.hour >= 12 && s.hour < 18),
          ),
          ('Noite', Icons.nightlight_round, list.where((s) => s.hour >= 18)),
        ].where((g) => g.$3.isNotEmpty);

        return LayoutBuilder(
          builder: (context, c) {
            final perRow = c.maxWidth >= 560 ? 5 : (c.maxWidth >= 380 ? 4 : 3);
            final w = (c.maxWidth - (perRow - 1) * 10) / perRow;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (label, icon, items) in groups) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10, top: 4),
                    child: Row(
                      children: [
                        Icon(icon, color: AppColors.amber, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final s in items)
                        SizedBox(
                          width: w,
                          child: _SlotChip(
                            time: s,
                            selected: s == selected,
                            onTap: () => onSelect(s),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _SlotChip extends StatelessWidget {
  const _SlotChip({
    required this.time,
    required this.selected,
    required this.onTap,
  });

  final DateTime time;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: formatTime(time),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: selected
                  ? AppColors.brandGradient
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x26FFFFFF), Color(0x0DFFFFFF)],
                    ),
              border: Border.all(
                color: selected
                    ? const Color(0x88FFF1D6)
                    : const Color(0x1FFFFFFF),
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: AppColors.glow.withValues(alpha: 0.5),
                    blurRadius: 20,
                  ),
              ],
            ),
            child: Text(
              formatTime(time),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: selected ? const Color(0xFF1C1205) : AppColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.slot,
    required this.price,
    required this.loading,
    required this.onConfirm,
  });

  final DateTime? slot;
  final int price;
  final bool loading;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xE61A130D), Color(0xFA0A0806)],
        ),
        border: Border(
          top: BorderSide(color: AppColors.amber.withValues(alpha: 0.25)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: slot == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_available_rounded,
                          color: AppColors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${formatRelativeDay(slot!)} às ${formatTime(slot!)}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
          ),
          GradientButton(
            label: slot == null
                ? 'Selecione um horário'
                : 'Confirmar agendamento — ${formatMoney(price)}',
            loading: loading,
            onPressed: slot == null ? null : onConfirm,
          ),
        ],
      ),
    );
  }
}

/// "Ingresso" de confirmação com animação de entrada.
class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({
    required this.business,
    required this.service,
    required this.startsAt,
  });

  final Business business;
  final BusinessService service;
  final DateTime startsAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.85, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (_, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: GlassCard(
            glow: true,
            highlight: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.brandGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.glow.withValues(alpha: 0.6),
                        blurRadius: 30,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 42,
                    color: Color(0xFF1C1205),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Horário garantido!',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                _TicketRow(Icons.storefront_rounded, business.name),
                _TicketRow(serviceIcon(service.name), service.name),
                _TicketRow(
                  Icons.event_rounded,
                  '${formatRelativeDay(startsAt)} às ${formatTime(startsAt)}',
                ),
                _TicketRow(
                  Icons.payments_rounded,
                  formatMoney(service.priceCents),
                ),
                const SizedBox(height: 24),
                GradientButton(
                  label: 'Ver meus horários',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 20, color: AppColors.amber),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ),
      ],
    ),
  );
}
