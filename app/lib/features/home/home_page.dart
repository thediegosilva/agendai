import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../auth/auth_controller.dart';
import '../booking/presentation/client_home.dart';
import '../owner/presentation/owner_home.dart';

/// Tela inicial: área do cliente ou painel do dono, conforme o perfil.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user == null) return const SizedBox.shrink();
    return user.isOwner ? OwnerShell(user: user) : ClientShell(user: user);
  }
}
