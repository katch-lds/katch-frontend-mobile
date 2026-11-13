import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../core/input_rules.dart';
import '../../models/file_selection.dart';
import '../../state/load_status.dart';
import '../../state/profile_files_controller.dart';
import '../../state/profile_store.dart';
import '../../widgets/connection_banner.dart';
import '../../widgets/field_error_text.dart';
import '../../widgets/form_message.dart';
import '../../widgets/load_failure_view.dart';
import '../../widgets/remote_image.dart';
import '../../widgets/save_button.dart';

/// Fotografia, curriculum vitae e hiperligações, M06 (RF010, RF011, RF012).
class ProfileFilesScreen extends StatefulWidget {
  const ProfileFilesScreen({super.key});

  /// Confirmação apresentada depois da gravação.
  static const successMessage =
      'Os ficheiros e as hiperligações foram gravados.';

  /// Indicações do protótipo junto de cada ficheiro.
  static const photoHint = 'Só JPEG ou PNG até 5 MB';
  static const cvHint = 'Só PDF até 5 MB';

  @override
  State<ProfileFilesScreen> createState() => _ProfileFilesScreenState();
}

class _ProfileFilesScreenState extends State<ProfileFilesScreen> {
  late final ProfileFilesController _controller;
  late final ProfileStore _store;

  @override
  void initState() {
    super.initState();
    final dependencies = AppScope.of(context);
    _store = dependencies.profile;
    _controller = ProfileFilesController(
      service: dependencies.profileService,
      profile: _store,
      picker: dependencies.filePicker,
    );
    unawaited(_load());
  }

  Future<void> _load() async {
    await _store.load();
    _controller.load();
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
      const SnackBar(content: Text(ProfileFilesScreen.successMessage)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ficheiros e hiperligações')),
      body: Column(
        children: [
          ConnectionBanner(monitor: dependencies.monitor),
          Expanded(
            child: ListenableBuilder(
              listenable: Listenable.merge([_controller, _store]),
              builder: (context, _) {
                final profile = _store.profile;
                if (profile == null) {
                  return _store.status == LoadStatus.failed
                      ? LoadFailureView(
                          message: null,
                          onRetry: () => unawaited(_load()),
                        )
                      : const Center(child: CircularProgressIndicator());
                }
                final loading = _controller.status == LoadStatus.loading;
                final errors = _controller.errors;
                final drafts = _controller.linkDrafts;
                return SingleChildScrollView(
                  key: const Key('files-list'),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionTitle('Fotografia'),
                      Row(
                        children: [
                          RemoteImage(
                            key: const Key('files-photo'),
                            url: profile.photoUrl,
                            baseUrl: dependencies.config.apiBaseUrl,
                            credentials: dependencies.session,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _FileChoice(
                              selection: _controller.photo,
                              empty: 'Nenhuma fotografia escolhida.',
                              hint: ProfileFilesScreen.photoHint,
                              buttonKey: const Key('files-pick-photo'),
                              buttonLabel: 'Escolher fotografia',
                              enabled: !loading,
                              onPick: _controller.pickPhoto,
                              error: errors.reasonFor(
                                ProfileFilesController.photoField,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle('Curriculum vitae'),
                      Text(
                        profile.hasCv
                            ? 'Curriculum vitae enviado.'
                            : 'Sem curriculum vitae.',
                        key: const Key('files-cv-status'),
                      ),
                      const SizedBox(height: 8),
                      _FileChoice(
                        selection: _controller.cv,
                        empty: 'Nenhum PDF escolhido.',
                        hint: ProfileFilesScreen.cvHint,
                        buttonKey: const Key('files-pick-cv'),
                        buttonLabel: 'Escolher PDF',
                        enabled: !loading,
                        onPick: _controller.pickCv,
                        error: errors.reasonFor(ProfileFilesController.cvField),
                      ),
                      const SizedBox(height: 24),
                      const _SectionTitle(
                        'Hiperligações (até ${InputRules.maxLinks})',
                      ),
                      for (var index = 0; index < drafts.length; index++)
                        KeyedSubtree(
                          key: ValueKey(drafts[index].key),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              key: Key('files-link-$index'),
                              initialValue: drafts[index].url,
                              enabled: !loading,
                              keyboardType: TextInputType.url,
                              decoration: InputDecoration(
                                labelText: 'Hiperligação ${index + 1}',
                                hintText: 'https://',
                                errorText: errors.reasonFor(
                                  ProfileFilesController.linkField(index),
                                ),
                                errorMaxLines: 3,
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  key: Key('files-link-remove-$index'),
                                  tooltip: 'Retirar',
                                  icon: const Icon(Icons.close),
                                  onPressed: loading
                                      ? null
                                      : () => _controller.removeLink(index),
                                ),
                              ),
                              onChanged: (value) =>
                                  _controller.setLink(index, value),
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          key: const Key('files-add-link'),
                          onPressed: loading ? null : _controller.addLink,
                          icon: const Icon(Icons.add_link),
                          label: const Text('Adicionar hiperligação'),
                        ),
                      ),
                      FieldErrorText(
                        errors.reasonFor(ProfileFilesController.linksField),
                        key: const Key('files-links-error'),
                      ),
                      FormMessage(message: _controller.errorMessage),
                      const SizedBox(height: 8),
                      SaveButton(
                        key: const Key('files-save'),
                        loading: loading,
                        onPressed: _save,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _FileChoice extends StatelessWidget {
  const _FileChoice({
    required this.selection,
    required this.empty,
    required this.hint,
    required this.buttonKey,
    required this.buttonLabel,
    required this.enabled,
    required this.onPick,
    required this.error,
  });

  final FileSelection? selection;
  final String empty;
  final String hint;
  final Key buttonKey;
  final String buttonLabel;
  final bool enabled;
  final Future<void> Function() onPick;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final file = selection;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(file == null ? empty : 'Escolhido: ${file.name}'),
        Text(hint, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        OutlinedButton(
          key: buttonKey,
          onPressed: enabled ? () => unawaited(onPick()) : null,
          child: Text(buttonLabel),
        ),
        FieldErrorText(error),
      ],
    );
  }
}
