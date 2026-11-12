import 'package:material_ui/material_ui.dart';

/// Confirmação da ativação da conta, M04 (RF005).
///
/// A conta fica ativa de imediato, sem aprovação do Administrador, e a sessão
/// já está iniciada com a resposta do registo.
class RegisterSuccessScreen extends StatelessWidget {
  const RegisterSuccessScreen({super.key, required this.onStart});

  /// Abre a área do Candidato («Começar a explorar»).
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle_outline, size: 64),
              const SizedBox(height: 16),
              Text(
                'A sua conta está ativa',
                style: textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Já pode explorar vagas e completar o seu perfil.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                key: const Key('register-start'),
                onPressed: onStart,
                child: const Text('Começar a explorar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
