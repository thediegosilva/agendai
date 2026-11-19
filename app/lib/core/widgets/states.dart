import 'package:material_ui/material_ui.dart';

import '../api_client.dart';
import '../theme.dart';

/// Ilustração simples + texto para listas vazias.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.amber.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColors.amber.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(icon, color: AppColors.amber, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

/// Mensagem de erro com botão de tentar de novo.
class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => EmptyState(
    icon: Icons.cloud_off_rounded,
    title: 'Ops, algo deu errado',
    message: apiErrorMessage(error),
    action: OutlinedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Tentar de novo'),
      style: OutlinedButton.styleFrom(minimumSize: const Size(160, 48)),
    ),
  );
}

/// Carregando centralizado com padding.
class LoadingBox extends StatelessWidget {
  const LoadingBox({super.key, this.height = 160});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: const Center(
      child: SizedBox.square(
        dimension: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    ),
  );
}

/// Título de seção com ação opcional à direita.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Pílula pequena (status, tags).
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.color = AppColors.amber, this.icon});

  final String text;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

/// Pergunta de confirmação no estilo do app.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surfaceHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Voltar', style: TextStyle(color: AppColors.text)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(110, 44),
            backgroundColor: destructive ? AppColors.danger : AppColors.amber,
            foregroundColor: destructive ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}
