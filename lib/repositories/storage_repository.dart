import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/error_mapper.dart';

class StorageRepository {
  Future<String> uploadImagemComSeguranca(File imagemOriginal) async {
    if (imagemOriginal.path.isEmpty || !await imagemOriginal.exists()) {
      throw AppException.validation(
          'Arquivo de imagem invalido ou nao encontrado.');
    }

    final nomeArquivo = DateTime.now().millisecondsSinceEpoch.toString();
    final ref =
        FirebaseStorage.instance.ref().child('eventos/$nomeArquivo.jpg');

    try {
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putFile(imagemOriginal, metadata);
      final url = await ref.getDownloadURL();
      return url;
    } on FirebaseException catch (exception, stackTrace) {
      throw ErrorMapper.fromFirebaseException(
        exception,
        fallbackType: AppErrorType.storage,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.storage,
        stackTrace: stackTrace,
      );
    }
  }
}
