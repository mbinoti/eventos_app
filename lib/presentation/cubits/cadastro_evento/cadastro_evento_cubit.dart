import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../repositories/storage_repository.dart';
import 'cadastro_evento_state.dart';

/// Cubit responsável pelo gerenciamento do estado do cadastro de eventos.
///
/// Utiliza um [StorageRepository] para salvar os dados do evento.
/// Os estados possíveis são:
/// - [CadastroEventoInitial]: estado inicial.
/// - [CadastroEventoLoading]: cadastro em andamento.
/// - [CadastroEventoSuccess]: cadastro realizado com sucesso.
/// - [CadastroEventoError]: erro ao cadastrar evento.
class CadastroEventoCubit extends Cubit<CadastroEventoState> {
  /// Repositório de armazenamento utilizado para salvar eventos.
  final StorageRepository repository;

  /// Construtor do [CadastroEventoCubit].
  CadastroEventoCubit(this.repository) : super(CadastroEventoInitial());

  /// Realiza o cadastro de um novo evento.
  ///
  /// Emite [CadastroEventoLoading] durante o processo,
  /// [CadastroEventoSuccess] em caso de sucesso,
  /// ou [CadastroEventoError] em caso de falha.
  Future<void> cadastrarEvento({
    required String titulo,
    required String cidade,
    required DateTime dataEvento,
    required List<File> imagens,
  }) async {
    emit(CadastroEventoLoading());

    try {
      print('📤 Iniciando upload das imagens...');
      List<String> urls = [];

      for (final imagem in imagens) {
        final url = await repository.uploadImagemComSeguranca(imagem);
        urls.add(url);
        print('✅ Upload concluído: $url');
      }

      print('📝 Gravando dados no Firestore...');
      await FirebaseFirestore.instance.collection('eventos').add({
        'titulo': titulo,
        'cidade': cidade,
        'imagemUrls': urls, // agora é um array de imagens
        'dataEvento': dataEvento,
        'criadoEm': DateTime.now(),
      });

      emit(CadastroEventoSucesso());
    } catch (e) {
      print('🔥 Erro ao salvar evento: $e');
      emit(CadastroEventoErro(e.toString()));
    }
  }
}
