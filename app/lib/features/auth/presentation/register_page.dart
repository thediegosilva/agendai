import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/ui.dart';
import '../auth_controller.dart';
import '../data/auth_user.dart';
import 'validators.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.client;
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await ref
        .read(authControllerProvider.notifier)
        .register(
          name: _name.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _password.text,
          role: _role,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    final state = ref.read(authControllerProvider);
    if (state.hasError) showAppSnack(context, apiErrorMessage(state.error!));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var i = 0;
    return Scaffold(
      body: CinematicBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeSlideIn(index: i++, child: const BrandLogo(size: 52)),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      index: i++,
                      child: GlassCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Criar conta',
                                style: theme.textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Leva menos de um minuto.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _RolePicker(
                                value: _role,
                                onChanged: (r) => setState(() => _role = r),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _name,
                                textCapitalization: TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Nome',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: validateName,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'E-mail',
                                  prefixIcon: Icon(Icons.alternate_email),
                                ),
                                validator: validateEmail,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _phone,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'Telefone (opcional)',
                                  prefixIcon: Icon(Icons.phone_outlined),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _password,
                                obscureText: _obscure,
                                onFieldSubmitted: (_) => _submit(),
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  helperText: 'Mínimo de 8 caracteres',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                                validator: validateNewPassword,
                              ),
                              const SizedBox(height: 28),
                              GradientButton(
                                label: 'Criar conta',
                                icon: Icons.arrow_forward_rounded,
                                loading: _loading,
                                onPressed: _submit,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeSlideIn(
                      index: i++,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Já tem conta?',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/login'),
                            child: const Text('Entrar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dois cartões grandes para escolher o tipo de conta.
class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.value, required this.onChanged});

  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _RoleTile(
            icon: Icons.person_rounded,
            title: 'Sou cliente',
            subtitle: 'Quero agendar',
            selected: value == UserRole.client,
            onTap: () => onChanged(UserRole.client),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RoleTile(
            icon: Icons.storefront_rounded,
            title: 'Tenho negócio',
            subtitle: 'Quero receber',
            selected: value == UserRole.owner,
            onTap: () => onChanged(UserRole.owner),
          ),
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: selected
                ? AppColors.amber.withValues(alpha: 0.12)
                : const Color(0x0AFFFFFF),
            border: Border.all(
              color: selected ? AppColors.amber : AppColors.outline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: selected ? AppColors.amber : AppColors.textMuted,
              ),
              const SizedBox(height: 10),
              Text(title, style: theme.textTheme.titleSmall),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
