import '../models/match_dto.dart';

/// Matches do Candidato (modelo de classes, secção 5; API v02, 6.7).
abstract interface class MatchService {
  /// Matches confirmados, do mais recente para o mais antigo, incluindo os de
  /// vagas encerradas e de Empresas suspensas (RF024, RF025).
  Future<List<MatchDto>> list();
}
