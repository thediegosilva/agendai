import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api_client.dart';
import '../../../core/format.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/ui.dart';
import '../../booking/data/models.dart';
import '../data/owner_repository.dart';

/// Abre um formulário em painel inferior (mobile) / diálogo (telas largas).
Future<void> showFormSheet(BuildContext context, Widget child) {
  final wide = MediaQuery.sizeOf(context).width > 640;
  if (wide) {
    return showDialog<void>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surfaceHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: child,
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceHigh,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewInsetsOf(ctx).bottom,
      ),
      child: SingleChildScrollView(child: child),
    ),
  );
}

// ---------------------------------------------------------------------------
// Negócio
// ---------------------------------------------------------------------------

/// Formulário de criação/edição do negócio.
class BusinessForm extends ConsumerStatefulWidget {
  const BusinessForm({super.key, this.business, this.onSaved});

  /// null = criação.
  final Business? business;
  final VoidCallback? onSaved;

  @override
  ConsumerState<BusinessForm> createState() => _BusinessFormState();
}

class _BusinessFormState extends ConsumerState<BusinessForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.business?.name);
  late final _description = TextEditingController(
    text: widget.business?.description,
  );
  late final _address = TextEditingController(text: widget.business?.address);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(ownerRepositoryProvider);
    try {
      final b = widget.business;
      if (b == null) {
        await repo.createBusiness(
          name: _name.text.trim(),
          description: _description.text.trim(),
          address: _address.text.trim(),
        );
      } else {
        await repo.updateBusiness(
          b.id,
          name: _name.text.trim(),
          description: _description.text.trim(),
          address: _address.text.trim(),
        );
      }
      ref.invalidate(myBusinessProvider);
      widget.onSaved?.call();
    } catch (e) {
      if (mounted) showAppSnack(context, apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final creating = widget.business == null;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nome do negócio',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            validator: (v) =>
                (v == null || v.trim().length < 2) ? 'Informe o nome' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _address,
            decoration: const InputDecoration(
              labelText: 'Endereço (opcional)',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Descrição (opcional)',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            label: creating ? 'Criar meu negócio' : 'Salvar',
            icon: creating ? Icons.rocket_launch_outlined : Icons.check_rounded,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Serviço
// ---------------------------------------------------------------------------

class ServiceForm extends ConsumerStatefulWidget {
  const ServiceForm({super.key, required this.businessId, this.service});

  final String businessId;

  /// null = criação.
  final BusinessService? service;

  @override
  ConsumerState<ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends ConsumerState<ServiceForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.service?.name);
  late final _price = TextEditingController(
    text: widget.service == null
        ? null
        : (widget.service!.priceCents / 100)
              .toStringAsFixed(2)
              .replaceAll('.', ','),
  );
  late int _duration = widget.service?.durationMinutes ?? 30;
  bool _saving = false;

  static const _durations = [15, 20, 30, 45, 60, 75, 90, 120, 150, 180, 240];

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  int? _parseCents(String text) {
    final normalized = text.trim().replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(normalized);
    return value == null || value < 0 ? null : (value * 100).round();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final repo = ref.read(ownerRepositoryProvider);
    final cents = _parseCents(_price.text)!;
    try {
      if (widget.service == null) {
        await repo.addService(
          widget.businessId,
          name: _name.text.trim(),
          durationMinutes: _duration,
          priceCents: cents,
        );
      } else {
        await repo.updateService(
          widget.service!.id,
          name: _name.text.trim(),
          durationMinutes: _duration,
          priceCents: cents,
        );
      }
      ref.invalidate(myBusinessProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) showAppSnack(context, apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final durations = {..._durations, _duration}.toList()..sort();
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.service == null ? 'Novo serviço' : 'Editar serviço',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nome',
              hintText: 'Ex.: Corte masculino',
              prefixIcon: Icon(Icons.content_cut_rounded),
            ),
            validator: (v) =>
                (v == null || v.trim().length < 2) ? 'Informe o nome' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Preço',
              prefixText: 'R\$ ',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
            validator: (v) =>
                _parseCents(v ?? '') == null ? 'Preço inválido' : null,
          ),
          const SizedBox(height: 20),
          Text(
            'Duração',
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in durations)
                ChoiceChip(
                  label: Text(formatDuration(d)),
                  selected: d == _duration,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _duration = d),
                ),
            ],
          ),
          const SizedBox(height: 24),
          GradientButton(
            label: 'Salvar serviço',
            icon: Icons.check_rounded,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Horário de funcionamento
// ---------------------------------------------------------------------------

class HoursEditor extends ConsumerStatefulWidget {
  const HoursEditor({super.key, required this.business});

  final Business business;

  @override
  ConsumerState<HoursEditor> createState() => _HoursEditorState();
}

class _DayState {
  _DayState({required this.open, required this.from, required this.to});

  bool open;
  int from;
  int to;
}

class _HoursEditorState extends ConsumerState<HoursEditor> {
  late final Map<int, _DayState> _days = {
    for (var d = 0; d < 7; d++)
      d: switch (widget.business.hoursFor(d)) {
        null => _DayState(open: false, from: 9 * 60, to: 18 * 60),
        final h => _DayState(open: true, from: h.openMinute, to: h.closeMinute),
      },
  };
  bool _saving = false;
  bool _dirty = false;

  Future<void> _pick(int weekday, {required bool start}) async {
    final day = _days[weekday]!;
    final current = start ? day.from : day.to;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      final m = picked.hour * 60 + picked.minute;
      if (start) {
        day.from = m;
      } else {
        day.to = m == 0 ? 24 * 60 : m;
      }
      _dirty = true;
    });
  }

  Future<void> _save() async {
    final invalid = _days.entries.where(
      (e) => e.value.open && e.value.to <= e.value.from,
    );
    if (invalid.isNotEmpty) {
      showAppSnack(
        context,
        '${weekdayLong[invalid.first.key]}: o fechamento deve ser depois da abertura.',
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(ownerRepositoryProvider).setHours(widget.business.id, [
        for (final MapEntry(key: d, value: s) in _days.entries)
          if (s.open)
            OpeningHours(weekday: d, openMinute: s.from, closeMinute: s.to),
      ]);
      ref.invalidate(myBusinessProvider);
      if (mounted) {
        setState(() => _dirty = false);
        showAppSnack(context, 'Horários salvos!', error: false);
      }
    } catch (e) {
      if (mounted) showAppSnack(context, apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          radius: 20,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              for (final d in [1, 2, 3, 4, 5, 6, 0])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Switch(
                        value: _days[d]!.open,
                        activeTrackColor: AppColors.amber,
                        onChanged: (v) => setState(() {
                          _days[d]!.open = v;
                          _dirty = true;
                        }),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 72,
                        child: Text(
                          weekdayLong[d],
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      const Spacer(),
                      if (_days[d]!.open) ...[
                        _TimeButton(
                          minute: _days[d]!.from,
                          onTap: () => _pick(d, start: true),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('–'),
                        ),
                        _TimeButton(
                          minute: _days[d]!.to,
                          onTap: () => _pick(d, start: false),
                        ),
                      ] else
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Fechado',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GradientButton(
          label: 'Salvar horários',
          icon: Icons.check_rounded,
          loading: _saving,
          onPressed: _dirty ? _save : null,
        ),
      ],
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({required this.minute, required this.onTap});

  final int minute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(72, 40),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    child: Text(formatMinute(minute)),
  );
}
