import 'package:material_ui/material_ui.dart';

import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/ui.dart';
import '../data/models.dart';

(String, Color) appointmentStatus(Appointment a) => switch (a.status) {
  AppointmentStatus.canceled => ('Cancelado', AppColors.danger),
  AppointmentStatus.completed => ('Concluído', AppColors.success),
  AppointmentStatus.scheduled when a.isUpcoming => (
    'Confirmado',
    AppColors.success,
  ),
  AppointmentStatus.scheduled => ('Realizado', AppColors.textMuted),
};

/// Selo de data em vidro âmbar: SEX / 20 / NOV.
class DateBadge extends StatelessWidget {
  const DateBadge({super.key, required this.date, this.active = true});

  final DateTime date;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final fg = active ? const Color(0xFFFFE3B3) : AppColors.textMuted;
    final small = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
      color: fg,
      height: 1.2,
    );
    return Container(
      width: 58,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: active
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.amber.withValues(alpha: 0.42),
                  AppColors.ember.withValues(alpha: 0.18),
                ],
              )
            : null,
        color: active ? null : const Color(0x0FFFFFFF),
        border: Border.all(
          color: active
              ? AppColors.amber.withValues(alpha: 0.65)
              : AppColors.outline,
        ),
      ),
      child: Column(
        children: [
          Text(weekdayShort[weekdayIndex(date)].toUpperCase(), style: small),
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: active ? Colors.white : AppColors.textMuted,
              height: 1.15,
            ),
          ),
          Text(monthShort[date.month - 1].toUpperCase(), style: small),
        ],
      ),
    );
  }
}

/// Cartão de agendamento do cliente (referência: "Próximos horários").
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    this.onCancel,
    this.onTap,
  });

  final Appointment appointment;
  final VoidCallback? onCancel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final theme = Theme.of(context);
    final active = a.isUpcoming;
    final (statusText, statusColor) = appointmentStatus(a);

    final card = GlassCard(
      radius: 24,
      highlight: active,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DateBadge(date: a.startsAt, active: active),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${formatTime(a.startsAt)} – ${formatTime(a.endsAt)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.serviceName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (a.businessName != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0x14FFFFFF),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: AppColors.amber,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      a.businessName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              GradientText(
                formatMoney(a.priceCents),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (onCancel != null && active) ...[
                DangerOutlineButton(
                  label: 'Cancelar',
                  compact: true,
                  onPressed: onCancel!,
                ),
                const SizedBox(width: 8),
              ],
              Pill(statusText, color: statusColor, icon: Icons.circle),
            ],
          ),
        ],
      ),
    );

    return Opacity(
      opacity: active ? 1 : 0.6,
      child: onTap == null
          ? card
          : GestureDetector(
              onTap: onTap,
              child: MouseRegion(cursor: SystemMouseCursors.click, child: card),
            ),
    );
  }
}

/// Linha de atendimento no painel do dono (referência: "Próximos atendimentos").
class OwnerAppointmentTile extends StatelessWidget {
  const OwnerAppointmentTile({
    super.key,
    required this.appointment,
    this.onCancel,
  });

  final Appointment appointment;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final a = appointment;
    final theme = Theme.of(context);
    final today = isSameDay(a.startsAt, DateTime.now());
    final when = today
        ? formatTime(a.startsAt)
        : '${formatDayShort(a.startsAt)} · ${formatTime(a.startsAt)}';
    final narrow = MediaQuery.sizeOf(context).width < 520;

    return GlassCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          InitialsAvatar(name: a.clientName ?? '?', size: narrow ? 44 : 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.clientName ?? 'Cliente',
                  style: theme.textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        when,
                        style: const TextStyle(
                          color: Color(0xFF1C1205),
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    Text(
                      [
                        a.serviceName,
                        if (a.clientPhone case final p?) formatPhone(p),
                      ].join(' · '),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onCancel != null && a.isUpcoming) ...[
            const SizedBox(width: 8),
            DangerOutlineButton(
              label: 'Cancelar',
              compact: narrow,
              onPressed: onCancel!,
            ),
          ],
        ],
      ),
    );
  }
}
