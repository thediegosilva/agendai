import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/ui.dart';
import '../auth_controller.dart';
import 'validators.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await ref
        .read(authControllerProvider.notifier)
        .login(_email.text.trim(), _password.text);
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
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FadeSlideIn(index: i++, child: const BrandLogo()),
                    const SizedBox(height: 12),
                    FadeSlideIn(
                      index: i++,
                      child: Text(
                        'Seu horário marcado em poucos toques.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    FadeSlideIn(
                      index: i++,
                      child: GlassCard(
                        child: Form(
                          key: _formKey,
                          child: AutofillGroup(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Bem-vindo de volta',
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Entre para ver seus agendamentos.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  decoration: const InputDecoration(
                                    labelText: 'E-mail',
                                    prefixIcon: Icon(Icons.alternate_email),
                                  ),
                                  validator: validateEmail,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _password,
                                  obscureText: _obscure,
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    labelText: 'Senha',
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
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Informe a senha'
                                      : null,
                                ),
                                const SizedBox(height: 28),
                                GradientButton(
                                  label: 'Entrar',
                                  icon: Icons.arrow_forward_rounded,
                                  loading: _loading,
                                  onPressed: _submit,
                                ),
                              ],
                            ),
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
                            'Não tem conta?',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/register'),
                            child: const Text('Cadastre-se'),
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
