import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../repositories/storage_repository.dart';
import 'cadastro_evento_state.dart';

class CadastroEventoCubit extends Cubit<CadastroEventoState> {
  final StorageRepository storage;

  CadastroEventoCubit(this.storage) : super(CadastroEventoInitial());

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
        final url = await storage.uploadImagemComSeguranca(imagem);
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
