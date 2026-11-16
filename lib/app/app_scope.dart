import 'package:flutter/widgets.dart';

import 'app_dependencies.dart';

/// Dá aos ecrãs as dependências da aplicação (modelo de classes, 9.2).
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.dependencies, required super.child});

  final AppDependencies dependencies;

  /// Dependências da aplicação, sem registar dependência no `build`; para usar
  /// no `initState` dos ecrãs.
  static AppDependencies of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    if (scope == null) {
      throw StateError('AppScope em falta na árvore de widgets.');
    }
    return scope.dependencies;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) {
    return !identical(dependencies, oldWidget.dependencies);
  }
}
