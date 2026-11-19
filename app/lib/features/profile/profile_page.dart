import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_shell.dart';
import '../../core/widgets/states.dart';
import '../../core/widgets/ui.dart';
import '../auth/auth_controller.dart';
import '../auth/data/auth_user.dart';

/// Perfil do usuário (cliente ou dono), com conteúdo extra opcional.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, required this.user, this.extra = const []});

  final AuthUser user;
  final List<Widget> extra;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    Widget row(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.amber, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );

    return ShellPage(
      maxWidth: 640,
      children: [
        Text('Perfil', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 24),
        FadeSlideIn(
          child: GlassCard(
            highlight: true,
            child: Column(
              children: [
                InitialsAvatar(name: user.name, size: 88),
                const SizedBox(height: 16),
                Text(user.name, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Pill(
                  user.isOwner ? 'Proprietário' : 'Cliente',
                  icon: user.isOwner
                      ? Icons.storefront_rounded
                      : Icons.person_rounded,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          index: 1,
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            radius: 24,
            child: Column(
              children: [
                row(Icons.alternate_email, 'E-mail', user.email),
                if (user.phone != null && user.phone!.isNotEmpty) ...[
                  const Divider(height: 1),
                  row(
                    Icons.phone_outlined,
                    'Telefone',
                    formatPhone(user.phone!),
                  ),
                ],
              ],
            ),
          ),
        ),
        ...extra,
        const SizedBox(height: 24),
        FadeSlideIn(
          index: 2,
          child: OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sair da conta'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: BorderSide(color: AppColors.danger.withValues(alpha: 0.6)),
            ),
          ),
        ),
      ],
    );
  }
}
