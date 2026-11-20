import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../state/load_status.dart';
import '../../state/skills_controller.dart';
import '../../widgets/field_error_text.dart';
import '../../widgets/form_message.dart';
import '../../widgets/katch_scaffold.dart';
import '../../widgets/load_state_view.dart';
import '../../widgets/save_button.dart';
import '../../widgets/skill_chip.dart';

/// Competências do Candidato como etiquetas, M07 (RF008, RF009).
///
/// A caixa de combinação tem as competências da lista pré-definida e a opção
/// «Outro», que mostra o campo da competência livre, validada antes de ser
/// acrescentada (P07).
class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  /// Confirmação apresentada depois da gravação.
  static const successMessage = 'As competências foram gravadas.';

  /// Valor da opção «Outro» na caixa de combinação.
  static const otherOption = '__outro__';

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  late final SkillsController _controller;
  final _customLabel = TextEditingController();

  @override
  void initState() {
    super.initState();
    final dependencies = AppScope.of(context);
    _controller = SkillsController(
      service: dependencies.profileService,
      reference: dependencies.referenceData,
      profile: dependencies.profile,
    );
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.dispose();
    _customLabel.dispose();
    super.dispose();
  }

  void _choose(String? value) {
    if (value == null) {
      return;
    }
    if (value == SkillsScreen.otherOption) {
      _controller.showCustom(true);
      return;
    }
    for (final skill in _controller.available) {
      if (skill.id == value) {
        _controller.toggle(skill);
        return;
      }
    }
  }

  void _addCustom() {
    if (_controller.addCustom()) {
      _customLabel.clear();
    }
  }

  Future<void> _save() async {
    final saved = await _controller.save();
    if (!saved || !mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(SkillsScreen.successMessage)));
  }

  @override
  Widget build(BuildContext context) {
    return KatchScaffold(
      title: 'Competências',
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final status = _controller.loadStatus;
          return LoadStatusView(
            failed: status == LoadStatus.failed,
            message: _controller.errorMessage,
            fallback: 'Não foi possível obter as competências.',
            onRetry: () => unawaited(_controller.load()),
            child: status == LoadStatus.loaded ? _buildContent(context) : null,
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final loading = _controller.status == LoadStatus.loading;
    final errors = _controller.errors;
    final selected = _controller.selected;
    final custom = _controller.selectedCustom;
    return SingleChildScrollView(
      key: const Key('skills-list'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (selected.isEmpty && custom.isEmpty)
            const Text('Ainda não escolheu competências.')
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final skill in selected)
                  SkillChip(
                    key: Key('skill-chip-${skill.name}'),
                    label: skill.name,
                    onDeleted: loading ? null : () => _controller.toggle(skill),
                  ),
                for (final skill in custom)
                  SkillChip(
                    key: Key('custom-chip-${skill.label}'),
                    label: skill.label,
                    custom: true,
                    onDeleted: loading
                        ? null
                        : () => _controller.removeCustom(skill),
                  ),
              ],
            ),
          const SizedBox(height: 24),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Acrescentar competência',
              border: OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('skills-combobox'),
                isExpanded: true,
                isDense: true,
                hint: const Text('Escolha da lista ou «Outro»'),
                items: [
                  for (final skill in _controller.available)
                    DropdownMenuItem(value: skill.id, child: Text(skill.name)),
                  const DropdownMenuItem(
                    value: SkillsScreen.otherOption,
                    child: Text('Outro'),
                  ),
                ],
                onChanged: loading ? null : _choose,
              ),
            ),
          ),
          FieldErrorText(errors.reasonFor(SkillsController.skillIdField)),
          if (_controller.customEnabled) ...[
            const SizedBox(height: 16),
            TextField(
              key: const Key('skills-custom-label'),
              controller: _customLabel,
              enabled: !loading,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Outra competência',
                helperText:
                    'Entre 2 e 40 caracteres: letras, algarismos, espaços e '
                    '+ # . -',
                helperMaxLines: 2,
                errorText: errors.reasonFor(SkillsController.labelField),
                errorMaxLines: 3,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => _controller.customLabel = value,
              onSubmitted: (_) => _addCustom(),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const Key('skills-custom-cancel'),
                  onPressed: () {
                    _customLabel.clear();
                    _controller.showCustom(false);
                  },
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  key: const Key('skills-custom-add'),
                  onPressed: loading ? null : _addCustom,
                  child: const Text('Acrescentar'),
                ),
              ],
            ),
          ] else
            FieldErrorText(errors.reasonFor(SkillsController.labelField)),
          FormMessage(message: _controller.errorMessage),
          const SizedBox(height: 8),
          SaveButton(
            key: const Key('skills-save'),
            loading: loading,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
