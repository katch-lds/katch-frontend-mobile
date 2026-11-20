import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../models/profile_enums.dart';
import '../../state/failure_messages.dart';
import '../../state/load_status.dart';
import '../../state/preferences_controller.dart';
import '../../state/profile_store.dart';
import '../../widgets/connection_banner.dart';
import '../../widgets/form_message.dart';
import '../../widgets/load_state_view.dart';
import '../../widgets/option_chips.dart';
import '../../widgets/save_button.dart';

/// Preferências de procura, M08 (RF007).
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  /// Confirmação apresentada depois da gravação.
  static const successMessage = 'As preferências foram gravadas.';

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  late final PreferencesController _controller;
  late final ProfileStore _store;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    final dependencies = AppScope.of(context);
    _store = dependencies.profile;
    _controller = PreferencesController(
      service: dependencies.profileService,
      profile: _store,
    );
    unawaited(_load());
  }

  Future<void> _load() async {
    await _store.load();
    if (!mounted || _store.profile == null) {
      return;
    }
    _controller.load();
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await _controller.save();
    if (!saved || !mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(PreferencesScreen.successMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monitor = AppScope.of(context).monitor;
    return Scaffold(
      appBar: AppBar(title: const Text('Preferências de procura')),
      body: Column(
        children: [
          ConnectionBanner(monitor: monitor),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([_controller, _store]),
              builder: (context, _) {
                if (!_ready) {
                  return _store.status == LoadStatus.failed
                      ? LoadStateView.failed(
                          message: _store.errorMessage,
                          fallback: profileFailureMessage,
                          onRetry: () => unawaited(_load()),
                        )
                      : const LoadStateView.loading();
                }
                return _buildForm(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final loading = _controller.status == LoadStatus.loading;
    final errors = _controller.errors;
    final titleStyle = Theme.of(context).textTheme.titleSmall;
    return SingleChildScrollView(
      key: const Key('preferences-list'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Um campo vazio ou nenhuma opção escolhida significa sem filtro.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('preferences-distance'),
            initialValue: _controller.maxDistanceText,
            enabled: !loading,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Distância máxima',
              suffixText: 'km',
              helperText: 'Entre 1 e 500 km.',
              errorText: errors.reasonFor(
                PreferencesController.maxDistanceKmField,
              ),
              errorMaxLines: 3,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => _controller.maxDistanceText = value,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('preferences-salary'),
            initialValue: _controller.minSalaryText,
            enabled: !loading,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Pretensão salarial mínima',
              suffixText: '€',
              errorText: errors.reasonFor(
                PreferencesController.minSalaryExpectationField,
              ),
              errorMaxLines: 3,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => _controller.minSalaryText = value,
          ),
          const SizedBox(height: 24),
          Text('Regime de trabalho', style: titleStyle),
          const SizedBox(height: 8),
          OptionChips<WorkMode>(
            options: WorkMode.values,
            selected: _controller.workModes,
            labelOf: (mode) => mode.label,
            keyOf: (mode) => Key('preferences-mode-${mode.wire}'),
            onToggle: _controller.toggleWorkMode,
            enabled: !loading,
          ),
          const SizedBox(height: 24),
          Text('Tipo de contrato', style: titleStyle),
          const SizedBox(height: 8),
          OptionChips<ContractType>(
            options: ContractType.values,
            selected: _controller.contractTypes,
            labelOf: (type) => type.label,
            keyOf: (type) => Key('preferences-contract-${type.wire}'),
            onToggle: _controller.toggleContractType,
            enabled: !loading,
          ),
          FormMessage(message: _controller.errorMessage),
          const SizedBox(height: 8),
          SaveButton(
            key: const Key('preferences-save'),
            loading: loading,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
