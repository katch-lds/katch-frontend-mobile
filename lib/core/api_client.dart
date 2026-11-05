/// Interface única dos pedidos à API (modelo de classes do mobile v02, 4.1).
///
/// As operações devolvem o JSON já descodificado; os serviços convertem-no
/// em modelos.
abstract interface class ApiClient {
  Future<Object?> get(String path);

  Future<Object?> post(String path, [Object? body]);

  Future<Object?> put(String path, [Object? body]);

  Future<void> delete(String path);
}
