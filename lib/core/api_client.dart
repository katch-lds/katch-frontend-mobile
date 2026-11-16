import '../models/file_selection.dart';

/// Interface única dos pedidos à API (modelo de classes do mobile v02, 4.1).
///
/// As operações devolvem o JSON já descodificado; os serviços convertem-no
/// em modelos.
abstract interface class ApiClient {
  Future<Object?> get(String path);

  Future<Object?> post(String path, [Object? body]);

  Future<Object?> put(String path, [Object? body]);

  Future<void> delete(String path);

  /// Envia um ficheiro em `multipart/form-data`, no campo `file`, com o
  /// método `PUT` (API v02, secção 2.6).
  Future<void> upload(String path, FileSelection file);
}
