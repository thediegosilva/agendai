import 'dart:async';

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
import '../../profile/profile_page.dart';
import '../data/booking_repository.dart';
import '../data/models.dart';
import 'appointment_card.dart';

/// Área do cliente: Início, Buscar, Meus Agendamentos e Perfil.
class ClientShell extends ConsumerStatefulWidget {
  const ClientShell({super.key, required this.user});

  final AuthUser user;

  @override
  ConsumerState<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends ConsumerState<ClientShell> {
  int _tab = 0;

  void _go(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    return AppShell(
      index: _tab,
      onSelect: _go,
      onLogout: () => ref.read(authControllerProvider.notifier).logout(),
      items: const [
        NavItem(
          Icons.home_outlined,
          'Início',
          selectedIcon: Icons.home_rounded,
        ),
        NavItem(Icons.search_rounded, 'Buscar'),
        NavItem(
          Icons.calendar_month_outlined,
          'Agendamentos',
          selectedIcon: Icons.calendar_month_rounded,
        ),
        NavItem(
          Icons.person_outline_rounded,
          'Perfil',
          selectedIcon: Icons.person_rounded,
        ),
      ],
      pages: [
        _HomeTab(user: widget.user, onNavigate: _go),
        const _SearchTab(),
        const _AppointmentsTab(),
        ProfilePage(user: widget.user),
      ],
    );
  }
}

/// Saudação conforme o horário.
String greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Bom dia';
  if (h < 18) return 'Boa tarde';
  return 'Boa noite';
}

Future<void> cancelAppointmentFlow(
  BuildContext context,
  WidgetRef ref,
  Appointment a,
) async {
  final ok = await confirmDialog(
    context,
    title: 'Cancelar horário?',
    message:
        '${a.serviceName} em ${a.businessName}\n'
        '${formatRelativeDay(a.startsAt)} às ${formatTime(a.startsAt)}',
    confirmLabel: 'Cancelar horário',
    destructive: true,
  );
  if (!ok || !context.mounted) return;
  try {
    await ref.read(bookingRepositoryProvider).cancel(a.id);
    ref.invalidate(myAppointmentsProvider);
    if (context.mounted) {
      showAppSnack(context, 'Horário cancelado.', error: false);
    }
  } catch (e) {
    if (context.mounted) showAppSnack(context, apiErrorMessage(e));
  }
}

// ---------------------------------------------------------------------------
// Início
// ---------------------------------------------------------------------------

class _HomeTab extends ConsumerWidget {
  const _HomeTab({required this.user, required this.onNavigate});

  final AuthUser user;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appointments = ref.watch(myAppointmentsProvider);
    final businesses = ref.watch(businessSearchProvider(''));
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    var i = 0;

    return ShellPage(
      onRefresh: () async {
        ref.invalidate(myAppointmentsProvider);
        ref.invalidate(businessSearchProvider(''));
        await ref.read(myAppointmentsProvider.future);
      },
      children: [
        FadeSlideIn(
          index: i++,
          child: Row(
            children: [
              if (!wide) ...[
                const BrandLogo(size: 44, horizontal: true),
                const Spacer(),
              ] else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${greeting()}, ${user.name.split(' ').first}!',
                        style: theme.textTheme.headlineMedium,
                      ),
                      Text(
                        'Pronto para o seu próximo horário?',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              GestureDetector(
                onTap: () => onNavigate(3),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InitialsAvatar(name: user.name, size: 46),
                ),
              ),
            ],
          ),
        ),
        if (!wide) ...[
          const SizedBox(height: 18),
          FadeSlideIn(
            index: i++,
            child: Text(
              '${greeting()}, ${user.name.split(' ').first}!',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        FadeSlideIn(
          index: i++,
          child: _SearchBox(onTap: () => onNavigate(1)),
        ),
        const SizedBox(height: 28),
        FadeSlideIn(
          index: i++,
          child: SectionTitle(
            'Próximos horários',
            trailing: TextButton(
              onPressed: () => onNavigate(2),
              child: const Text('Ver todos'),
            ),
          ),
        ),
        FadeSlideIn(
          index: i++,
          child: appointments.when(
            loading: () => const LoadingBox(height: 140),
            error: (e, _) => ErrorRetry(
              error: e,
              onRetry: () => ref.invalidate(myAppointmentsProvider),
            ),
            data: (all) {
              final upcoming = all.where((a) => a.isUpcoming).toList()
                ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
              if (upcoming.isEmpty) return const _NoAppointmentsBanner();
              return Column(
                children: [
                  for (final a in upcoming.take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppointmentCard(
                        appointment: a,
                        onTap: a.businessId == null
                            ? null
                            : () => context.push('/business/${a.businessId}'),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        FadeSlideIn(index: i++, child: const SectionTitle('Estabelecimentos')),
        ...businessList(context, ref, businesses, '', startIndex: i),
      ],
    );
  }
}

/// Barra de busca "falsa" do Início: leva para a aba Buscar.
class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: MouseRegion(
      cursor: SystemMouseCursors.text,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0x26FFC98A), Color(0x0FFFFFFF)],
          ),
          border: Border.all(color: AppColors.amber.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: AppColors.glow.withValues(alpha: 0.18),
              blurRadius: 24,
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: AppColors.amber, size: 26),
            const SizedBox(width: 12),
            Text(
              'Buscar estabelecimento...',
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NoAppointmentsBanner extends StatelessWidget {
  const _NoAppointmentsBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.all(20),
      radius: 24,
      child: Row(
        children: [
          const GlowIcon(Icons.local_activity_rounded, size: 52),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nenhum horário marcado',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  'Escolha um estabelecimento e garanta seu lugar.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de estabelecimentos (usada no Início e na Busca).
List<Widget> businessList(
  BuildContext context,
  WidgetRef ref,
  AsyncValue<List<Business>> businesses,
  String query, {
  int startIndex = 0,
}) => businesses.when(
  loading: () => [const LoadingBox()],
  error: (e, _) => [
    ErrorRetry(
      error: e,
      onRetry: () => ref.invalidate(businessSearchProvider(query)),
    ),
  ],
  data: (list) => list.isEmpty
      ? [
          EmptyState(
            icon: Icons.storefront_outlined,
            title: query.isEmpty
                ? 'Nenhum estabelecimento ainda'
                : 'Nada encontrado',
            message: query.isEmpty
                ? 'Assim que os negócios se cadastrarem, eles aparecem aqui.'
                : 'Tente outro nome.',
          ),
        ]
      : [
          for (final (n, b) in list.indexed)
            FadeSlideIn(
              index: startIndex + n,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: BusinessCard(
                  business: b,
                  onTap: () => context.push('/business/${b.id}'),
                ),
              ),
            ),
        ],
);

// ---------------------------------------------------------------------------
// Buscar
// ---------------------------------------------------------------------------

class _SearchTab extends ConsumerStatefulWidget {
  const _SearchTab();

  @override
  ConsumerState<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<_SearchTab> {
  final _search = TextEditingController();
  Timer? _debounce;
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _query = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final businesses = ref.watch(businessSearchProvider(_query));
    return ShellPage(
      children: [
        Text('Buscar', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        TextField(
          controller: _search,
          onChanged: _onChanged,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Barbearia, salão, estúdio...',
            prefixIcon: const Icon(Icons.search_rounded),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide(
                color: AppColors.amber.withValues(alpha: 0.45),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
            ),
            suffixIcon: ListenableBuilder(
              listenable: _search,
              builder: (_, _) => _search.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _search.clear();
                        _onChanged('');
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SectionTitle(
          _query.isEmpty ? 'Todos os estabelecimentos' : 'Resultados',
        ),
        ...businessList(context, ref, businesses, _query),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Meus agendamentos
// ---------------------------------------------------------------------------

class _AppointmentsTab extends ConsumerWidget {
  const _AppointmentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(myAppointmentsProvider);
    return ShellPage(
      onRefresh: () async {
        ref.invalidate(myAppointmentsProvider);
        await ref.read(myAppointmentsProvider.future);
      },
      children: [
        Text(
          'Meus agendamentos',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 20),
        ...appointments.when(
          loading: () => [const LoadingBox()],
          error: (e, _) => [
            ErrorRetry(
              error: e,
              onRetry: () => ref.invalidate(myAppointmentsProvider),
            ),
          ],
          data: (all) {
            final upcoming = all.where((a) => a.isUpcoming).toList()
              ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
            final past = all.where((a) => !a.isUpcoming).toList();
            if (all.isEmpty) {
              return [
                const EmptyState(
                  icon: Icons.event_note_rounded,
                  title: 'Nada por aqui ainda',
                  message: 'Seus horários marcados aparecem nesta tela.',
                ),
              ];
            }
            return [
              const SectionTitle('Próximos'),
              if (upcoming.isEmpty) const _NoAppointmentsBanner(),
              for (final (n, a) in upcoming.indexed)
                FadeSlideIn(
                  index: n,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppointmentCard(
                      appointment: a,
                      onCancel: () => cancelAppointmentFlow(context, ref, a),
                    ),
                  ),
                ),
              if (past.isNotEmpty) ...[
                const SizedBox(height: 16),
                const SectionTitle('Histórico'),
                for (final a in past)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppointmentCard(appointment: a),
                  ),
              ],
            ];
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Cartão de estabelecimento
// ---------------------------------------------------------------------------

class BusinessCard extends StatefulWidget {
  const BusinessCard({super.key, required this.business, required this.onTap});

  final Business business;
  final VoidCallback onTap;

  @override
  State<BusinessCard> createState() => _BusinessCardState();
}

class _BusinessCardState extends State<BusinessCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.business;
    final theme = Theme.of(context);
    final cat = businessCategory(b.name, b.description);
    final today = b.hoursFor(weekdayIndex(DateTime.now()));
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: AppColors.textMuted,
    );

    Widget line(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppColors.amber),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: muted,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    final hoursText = today == null
        ? 'Fechado hoje'
        : 'Hoje ${formatMinute(today.openMinute)}–${formatMinute(today.closeMinute)}';
    final services = b.serviceCount == null
        ? null
        : '${b.serviceCount} ${b.serviceCount == 1 ? 'serviço' : 'serviços'}';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 200),
          scale: _hover ? 1.015 : 1,
          child: GlassCard(
            radius: 24,
            glow: _hover,
            padding: const EdgeInsets.all(18),
            child: Semantics(
              button: true,
              child: Row(
                children: [
                  GlowIcon(cat.icon, size: 68),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.name,
                          style: theme.textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          cat.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.amber.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (b.address != null)
                          line(Icons.location_on_rounded, b.address!),
                        line(
                          Icons.schedule_rounded,
                          [hoursText, ?services].join(' · '),
                        ),
                        if (b.minPriceCents != null) ...[
                          const SizedBox(height: 8),
                          GradientText(
                            'A partir de ${formatMoney(b.minPriceCents!)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
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
