import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../app/app_scope.dart';
import '../../core/input_rules.dart';
import '../../models/candidate_profile_dto.dart';
import '../../models/profile_enums.dart';
import '../../state/load_status.dart';
import '../../state/profile_form_controller.dart';
import '../../state/profile_store.dart';
import '../../widgets/form_message.dart';
import '../../widgets/load_failure_view.dart';
import '../../widgets/remote_image.dart';
import '../../widgets/save_button.dart';
import '../account/account_screen.dart';
import 'preferences_screen.dart';
import 'profile_files_screen.dart';
import 'skills_screen.dart';

/// Perfil profissional do Candidato, M05 (RF006 a RF012).
///
/// Separador «Perfil» da área do Candidato: dados do perfil (RF006) e acesso
/// aos ficheiros e hiperligações (M06), às competências (M07), às
/// preferências de procura (M08) e à conta (M20).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  /// Confirmação apresentada depois da gravação.
  static const successMessage = 'O perfil foi gravado.';

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileFormController _controller;
  late final ProfileStore _store;

  @override
  void initState() {
    super.initState();
    final dependencies = AppScope.of(context);
    _store = dependencies.profile;
    _controller = ProfileFormController(
      service: dependencies.profileService,
      profile: _store,
      reference: dependencies.referenceData,
    );
    unawaited(_controller.load());
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(ProfileScreen.successMessage)));
  }

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, _store]),
      builder: (context, _) {
        final profile = _store.profile;
        switch (_controller.loadStatus) {
          case LoadStatus.idle || LoadStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case LoadStatus.failed:
            return LoadFailureView(
              message: _controller.errorMessage,
              onRetry: () => unawaited(_controller.load()),
            );
          case LoadStatus.loaded:
            break;
        }
        if (profile == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildForm(context, profile);
      },
    );
  }

  Widget _buildForm(BuildContext context, CandidateProfileDto profile) {
    final dependencies = AppScope.of(context);
    final loading = _controller.status == LoadStatus.loading;
    final errors = _controller.errors;
    final skills = [
      for (final skill in profile.skills) skill.name,
      for (final skill in profile.customSkills) skill.label,
    ];
    return SingleChildScrollView(
      key: const Key('profile-list'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              RemoteImage(
                key: const Key('profile-photo'),
                url: profile.photoUrl,
                baseUrl: dependencies.config.apiBaseUrl,
                credentials: dependencies.session,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(profile.email),
                    Text(profile.phoneNumber),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            key: const Key('profile-desired-role'),
            initialValue: _controller.desiredRole,
            enabled: !loading,
            decoration: InputDecoration(
              labelText: 'Função pretendida',
              errorText: errors.reasonFor(
                ProfileFormController.desiredRoleField,
              ),
              errorMaxLines: 3,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => _controller.desiredRole = value,
          ),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Localidade',
              errorText: errors.reasonFor(
                ProfileFormController.locationIdField,
              ),
              border: const OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const Key('profile-location'),
                isExpanded: true,
                isDense: true,
                value: _controller.locationId,
                hint: const Text('Selecione a localidade'),
                items: [
                  for (final location in _controller.locations)
                    DropdownMenuItem(
                      value: location.id,
                      child: Text(location.name),
                    ),
                ],
                onChanged: loading
                    ? null
                    : (value) => _controller.locationId = value,
              ),
            ),
          ),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: InputDecoration(
              labelText: 'Disponibilidade',
              errorText: errors.reasonFor(
                ProfileFormController.availabilityField,
              ),
              border: const OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Availability?>(
                key: const Key('profile-availability'),
                isExpanded: true,
                isDense: true,
                value: _controller.availability,
                hint: const Text('Não indicada'),
                items: [
                  const DropdownMenuItem<Availability?>(
                    child: Text('Não indicada'),
                  ),
                  for (final availability in Availability.values)
                    DropdownMenuItem<Availability?>(
                      value: availability,
                      child: Text(availability.label),
                    ),
                ],
                onChanged: loading
                    ? null
                    : (value) => _controller.availability = value,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('profile-summary'),
            initialValue: _controller.experienceSummary,
            enabled: !loading,
            minLines: 3,
            maxLines: 8,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              labelText: 'Resumo da experiência',
              alignLabelWithHint: true,
              counterText:
                  '${_controller.summaryLength}/${InputRules.summaryMaxLength}',
              errorText: errors.reasonFor(
                ProfileFormController.experienceSummaryField,
              ),
              errorMaxLines: 3,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => _controller.experienceSummary = value,
          ),
          FormMessage(message: _controller.errorMessage),
          const SizedBox(height: 8),
          SaveButton(
            key: const Key('profile-save'),
            loading: loading,
            onPressed: _save,
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            key: const Key('profile-open-files'),
            leading: const Icon(Icons.attach_file),
            title: const Text('Fotografia, CV e hiperligações'),
            subtitle: Text(
              '${profile.hasCv ? 'CV enviado' : 'Sem CV'} · '
              '${profile.links.length} de ${InputRules.maxLinks} hiperligações',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(const ProfileFilesScreen()),
          ),
          ListTile(
            key: const Key('profile-open-skills'),
            leading: const Icon(Icons.sell_outlined),
            title: const Text('Competências'),
            subtitle: Text(
              skills.isEmpty ? 'Sem competências' : skills.join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(const SkillsScreen()),
          ),
          ListTile(
            key: const Key('profile-open-preferences'),
            leading: const Icon(Icons.tune),
            title: const Text('Preferências de procura'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(const PreferencesScreen()),
          ),
          ListTile(
            key: const Key('profile-open-account'),
            leading: const Icon(Icons.manage_accounts_outlined),
            title: const Text('Conta'),
            subtitle: const Text('Palavra-passe e fim de sessão'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(const AccountScreen()),
          ),
        ],
      ),
    );
  }
}
