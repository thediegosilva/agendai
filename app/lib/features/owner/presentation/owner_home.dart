import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api_client.dart';
import '../../../core/category.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/ui.dart';
import '../../auth/auth_controller.dart';
import '../../auth/data/auth_user.dart';
import '../../booking/data/booking_repository.dart';
import '../../booking/data/models.dart';
import '../../booking/presentation/appointment_card.dart';
import '../../profile/profile_page.dart';
import '../data/owner_repository.dart';
import 'owner_forms.dart';

/// Painel do dono: Agenda, Serviços, Horários e Perfil.
class OwnerShell extends ConsumerStatefulWidget {
  const OwnerShell({super.key, required this.user});

  final AuthUser user;

  @override
  ConsumerState<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends ConsumerState<OwnerShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(myBusinessProvider);

    Widget needsBusiness(Widget Function(Business b) builder) => business.when(
      loading: () => const ShellPage(children: [LoadingBox(height: 400)]),
      error: (e, _) => ShellPage(
        children: [
          ErrorRetry(
            error: e,
            onRetry: () => ref.invalidate(myBusinessProvider),
          ),
        ],
      ),
      data: (b) => b == null
          ? const ShellPage(
              maxWidth: 560,
              children: [FadeSlideIn(child: _Onboarding())],
            )
          : builder(b),
    );

    return AppShell(
      index: _tab,
      onSelect: (i) => setState(() => _tab = i),
      onLogout: () => ref.read(authControllerProvider.notifier).logout(),
      items: const [
        NavItem(
          Icons.calendar_month_outlined,
          'Agenda',
          selectedIcon: Icons.calendar_month_rounded,
        ),
        NavItem(Icons.content_cut_rounded, 'Serviços'),
        NavItem(
          Icons.schedule_outlined,
          'Horários',
          selectedIcon: Icons.schedule_rounded,
        ),
        NavItem(
          Icons.person_outline_rounded,
          'Perfil',
          selectedIcon: Icons.person_rounded,
        ),
      ],
      pages: [
        needsBusiness((b) => _AgendaTab(business: b, user: widget.user)),
        needsBusiness((b) => _ServicesTab(business: b)),
        needsBusiness(
          (b) => ShellPage(
            maxWidth: 680,
            children: [
              const _PageTitle(
                'Horário de funcionamento',
                subtitle:
                    'Ligue os dias em que você atende e ajuste os horários.',
              ),
              HoursEditor(key: ValueKey('hours-${b.id}'), business: b),
            ],
          ),
        ),
        ProfilePage(
          user: widget.user,
          extra: [
            if (business.value case final b?) ...[
              const SizedBox(height: 16),
              FadeSlideIn(index: 1, child: _BusinessSummary(business: b)),
            ],
          ],
        ),
      ],
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle(this.title, {this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.headlineMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.amber,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _Onboarding extends StatelessWidget {
  const _Onboarding();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      highlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: GlowIcon(Icons.rocket_launch_rounded, size: 60),
          ),
          const SizedBox(height: 16),
          Text('Vamos abrir as portas?', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Cadastre seu negócio e comece a receber agendamentos. '
            'Já deixamos um horário padrão (seg a sáb, 9h às 18h) '
            'que você pode ajustar depois.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          const BusinessForm(),
        ],
      ),
    );
  }
}

/// Selo do negócio no topo do painel (nome + "Proprietário").
class _BusinessChip extends StatelessWidget {
  const _BusinessChip({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) => GlassCard(
    radius: 18,
    padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GlowIcon(businessCategory(business.name).icon, size: 40),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(business.name, style: Theme.of(context).textTheme.titleSmall),
            const Text(
              'Proprietário',
              style: TextStyle(color: AppColors.amber, fontSize: 12),
            ),
          ],
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Agenda
// ---------------------------------------------------------------------------

class _AgendaTab extends ConsumerWidget {
  const _AgendaTab({required this.business, required this.user});

  final Business business;
  final AuthUser user;

  Future<void> _cancel(
    BuildContext context,
    WidgetRef ref,
    Appointment a,
  ) async {
    final ok = await confirmDialog(
      context,
      title: 'Cancelar este horário?',
      message:
          '${a.clientName} · ${a.serviceName}\n'
          '${formatRelativeDay(a.startsAt)} às ${formatTime(a.startsAt)}',
      confirmLabel: 'Cancelar horário',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(bookingRepositoryProvider).cancel(a.id);
      ref.invalidate(businessAppointmentsProvider(business.id));
      if (context.mounted) {
        showAppSnack(context, 'Horário cancelado.', error: false);
      }
    } catch (e) {
      if (context.mounted) showAppSnack(context, apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(businessAppointmentsProvider(business.id));
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    final now = DateTime.now();

    return ShellPage(
      maxWidth: 980,
      onRefresh: () async {
        ref.invalidate(businessAppointmentsProvider(business.id));
        await ref.read(businessAppointmentsProvider(business.id).future);
      },
      children: [
        if (!wide) ...[
          Row(
            children: [
              const BrandLogo(size: 40, horizontal: true),
              const Spacer(),
              InitialsAvatar(name: user.name, size: 42),
            ],
          ),
          const SizedBox(height: 20),
        ],
        ...appointments.when(
          loading: () => [
            _PageTitle('Agenda de Hoje', subtitle: formatDayLong(now)),
            const LoadingBox(),
          ],
          error: (e, _) => [
            const _PageTitle('Agenda de Hoje'),
            ErrorRetry(
              error: e,
              onRetry: () =>
                  ref.invalidate(businessAppointmentsProvider(business.id)),
            ),
          ],
          data: (all) {
            final upcoming = all.where((a) => a.isUpcoming).toList();
            final today = upcoming
                .where((a) => isSameDay(a.startsAt, now))
                .toList();
            final later = upcoming
                .where((a) => !isSameDay(a.startsAt, now))
                .toList();
            final revenue = upcoming.fold(0, (sum, a) => sum + a.priceCents);
            final n = today.length;

            Widget tile(Appointment a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OwnerAppointmentTile(
                appointment: a,
                onCancel: () => _cancel(context, ref, a),
              ),
            );

            return [
              FadeSlideIn(
                child: _PageTitle(
                  'Agenda de Hoje',
                  subtitle:
                      '${wide ? formatDayLong(now) : formatDayShort(now)} • $n '
                      '${n == 1 ? 'compromisso' : 'compromissos'} hoje',
                  trailing: wide ? _BusinessChip(business: business) : null,
                ),
              ),
              FadeSlideIn(
                index: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        icon: Icons.event_available_rounded,
                        value: '$n',
                        label: wide ? 'Atendimentos hoje' : 'Hoje',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Stat(
                        icon: Icons.schedule_rounded,
                        value: '${upcoming.length}',
                        label: wide ? 'Agendamentos futuros' : 'Futuros',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Stat(
                        icon: Icons.payments_rounded,
                        value: formatMoney(revenue),
                        label: wide ? 'Faturamento previsto' : 'Previsto',
                        highlight: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (upcoming.isEmpty)
                EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'Agenda livre',
                  message: business.services.isEmpty
                      ? 'Cadastre seus serviços para começar a receber clientes.'
                      : 'Quando alguém marcar um horário, ele aparece aqui.',
                )
              else ...[
                SectionTitle(
                  today.isEmpty ? 'Hoje: nenhum atendimento' : 'Hoje',
                ),
                for (final a in today) tile(a),
                if (later.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const SectionTitle('Próximos dias'),
                  for (final a in later) tile(a),
                ],
              ],
            ];
          },
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    final style =
        (wide ? theme.textTheme.displaySmall : theme.textTheme.headlineSmall)
            ?.copyWith(fontWeight: FontWeight.w800);
    return GlassCard(
      radius: 22,
      glow: highlight,
      highlight: true,
      padding: EdgeInsets.symmetric(
        horizontal: wide ? 20 : 10,
        vertical: wide ? 24 : 14,
      ),
      child: Column(
        children: [
          GlowIcon(icon, size: wide ? 60 : 38),
          SizedBox(height: wide ? 14 : 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: GradientText(value, style: style),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Serviços
// ---------------------------------------------------------------------------

class _ServicesTab extends ConsumerWidget {
  const _ServicesTab({required this.business});

  final Business business;

  Future<void> _remove(
    BuildContext context,
    WidgetRef ref,
    BusinessService s,
  ) async {
    final ok = await confirmDialog(
      context,
      title: 'Remover "${s.name}"?',
      message:
          'Se ele já tiver agendamentos, será apenas desativado '
          'para manter o histórico.',
      confirmLabel: 'Remover',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(ownerRepositoryProvider).removeService(s.id);
      ref.invalidate(myBusinessProvider);
    } catch (e) {
      if (context.mounted) showAppSnack(context, apiErrorMessage(e));
    }
  }

  Future<void> _toggle(
    BuildContext context,
    WidgetRef ref,
    BusinessService s,
  ) async {
    try {
      await ref
          .read(ownerRepositoryProvider)
          .updateService(s.id, active: !s.active);
      ref.invalidate(myBusinessProvider);
    } catch (e) {
      if (context.mounted) showAppSnack(context, apiErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    void openForm([BusinessService? s]) => showFormSheet(
      context,
      ServiceForm(businessId: business.id, service: s),
    );

    return ShellPage(
      maxWidth: 760,
      children: [
        _PageTitle(
          'Serviços',
          subtitle:
              '${business.services.where((s) => s.active).length} ativos no seu catálogo',
        ),
        if (business.services.isEmpty)
          const EmptyState(
            icon: Icons.content_cut_rounded,
            title: 'Nenhum serviço ainda',
            message: 'Adicione o que você oferece, com duração e preço.',
          )
        else
          for (final (n, s) in business.services.indexed)
            FadeSlideIn(
              index: n,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Opacity(
                  opacity: s.active ? 1 : 0.5,
                  child: GestureDetector(
                    onTap: () => openForm(s),
                    child: GlassCard(
                      radius: 22,
                      padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
                      child: Row(
                        children: [
                          GlowIcon(serviceIcon(s.name), size: 50),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name,
                                  style: theme.textTheme.titleMedium,
                                ),
                                Text(
                                  '${formatDuration(s.durationMinutes)}'
                                  '${s.active ? '' : ' · inativo'}',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GradientText(
                            formatMoney(s.priceCents),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          PopupMenuButton<String>(
                            color: AppColors.surfaceHigh,
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: AppColors.textMuted,
                            ),
                            onSelected: (v) => switch (v) {
                              'edit' => openForm(s),
                              'toggle' => _toggle(context, ref, s),
                              _ => _remove(context, ref, s),
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Editar'),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(
                                  s.active ? 'Desativar' : 'Reativar',
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'remove',
                                child: Text(
                                  'Remover',
                                  style: TextStyle(color: AppColors.danger),
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
            ),
        const SizedBox(height: 12),
        GradientButton(
          label: 'Adicionar serviço',
          icon: Icons.add_rounded,
          onPressed: openForm,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Perfil: dados do negócio
// ---------------------------------------------------------------------------

class _BusinessSummary extends StatelessWidget {
  const _BusinessSummary({required this.business});

  final Business business;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cat = businessCategory(business.name, business.description);
    return GlassCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GlowIcon(cat.icon, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(business.name, style: theme.textTheme.titleLarge),
                    Text(
                      business.address ?? cat.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/business/${business.id}'),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ver como cliente'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                  onPressed: () => showFormSheet(
                    context,
                    Builder(
                      builder: (ctx) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Editar negócio',
                            style: Theme.of(ctx).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 20),
                          BusinessForm(
                            business: business,
                            onSaved: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
