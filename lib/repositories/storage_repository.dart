import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class StorageRepository {
  Future<String> uploadImagemComSeguranca(File imagemOriginal) async {
    if (imagemOriginal.path.isEmpty || !await imagemOriginal.exists()) {
      throw Exception('Arquivo de imagem inválido ou não encontrado.');
    }

    final nomeArquivo = DateTime.now().millisecondsSinceEpoch.toString();
    final ref =
        FirebaseStorage.instance.ref().child('eventos/$nomeArquivo.jpg');

    try {
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final uploadTask = await ref.putFile(imagemOriginal, metadata);
      final url = await ref.getDownloadURL();
      print('✅ Upload realizado com sucesso: $url');
      return url;
    } catch (e) {
      print('❌ Erro no upload: $e');
      throw Exception('Falha ao fazer upload da imagem.');
    }
  }
}
