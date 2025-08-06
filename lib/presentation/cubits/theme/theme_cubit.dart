import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';

/// Cubit responsável por gerenciar o tema da aplicação (claro/escuro).
///
/// Permite alternar entre os modos de tema e notifica os listeners.
class ThemeCubit extends Cubit<ThemeMode> {
  /// Construtor do [ThemeCubit].
  ThemeCubit() : super(ThemeMode.dark);

  /// Alterna entre os temas claro e escuro.
  void toggleTheme() {
    emit(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}
