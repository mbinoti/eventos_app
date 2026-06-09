import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import 'app_exception.dart';

class ErrorMapper {
  static AppException fromObject(
    Object error, {
    AppErrorType fallbackType = AppErrorType.unknown,
  }) {
    if (error is AppException) {
      return error;
    }

    if (error is FirebaseException) {
      return fromFirebaseException(error, fallbackType: fallbackType);
    }

    if (error is PlatformException) {
      return _fromPlatformException(error, fallbackType: fallbackType);
    }

    if (error is SocketException || error is TimeoutException) {
      return AppException(
        type: AppErrorType.network,
        userMessage:
            'Sem conexao com a internet no momento. Verifique sua rede e tente novamente.',
        technicalMessage: error.toString(),
        cause: error,
      );
    }

    final knownMessage = _extractKnownMessage(error);

    return AppException(
      type: fallbackType,
      userMessage: knownMessage ??
          'Ocorreu um erro inesperado. Tente novamente em instantes.',
      technicalMessage: error.toString(),
      cause: error,
    );
  }

  static AppException fromFirebaseException(
    FirebaseException exception, {
    AppErrorType fallbackType = AppErrorType.unknown,
  }) {
    final code = exception.code.toLowerCase();

    if (_networkCodes.contains(code)) {
      return AppException(
        type: AppErrorType.network,
        userMessage:
            'Sem conexao com a internet no momento. Verifique sua rede e tente novamente.',
        technicalMessage:
            'FirebaseException(${exception.code}): ${exception.message}',
        cause: exception,
      );
    }

    if (code == 'permission-denied') {
      return AppException(
        type: AppErrorType.permission,
        userMessage:
            'Voce nao tem permissao para realizar esta acao. Fale com o administrador.',
        technicalMessage:
            'FirebaseException(${exception.code}): ${exception.message}',
        cause: exception,
      );
    }

    if (code == 'not-found' || code == 'object-not-found') {
      return AppException(
        type: AppErrorType.notFound,
        userMessage: 'O recurso solicitado nao foi encontrado.',
        technicalMessage:
            'FirebaseException(${exception.code}): ${exception.message}',
        cause: exception,
      );
    }

    final fallbackMessage = switch (fallbackType) {
      AppErrorType.database =>
        'Nao foi possivel acessar os dados agora. Tente novamente em instantes.',
      AppErrorType.storage =>
        'Nao foi possivel processar o upload do arquivo no momento.',
      _ => 'Ocorreu um erro inesperado. Tente novamente em instantes.',
    };

    return AppException(
      type: fallbackType,
      userMessage: fallbackMessage,
      technicalMessage:
          'FirebaseException(${exception.code}): ${exception.message}',
      cause: exception,
    );
  }

  static AppException _fromPlatformException(
    PlatformException exception, {
    required AppErrorType fallbackType,
  }) {
    final code = exception.code.toLowerCase();
    final message = exception.message ?? '';

    if (code == 'channel-error') {
      return AppException(
        type: fallbackType,
        userMessage:
            'Nao foi possivel iniciar um servico interno do app. Feche o aplicativo e abra novamente.',
        technicalMessage: 'PlatformException(${exception.code}): $message',
        cause: exception,
      );
    }

    return AppException(
      type: fallbackType,
      userMessage: 'Ocorreu um erro inesperado. Tente novamente em instantes.',
      technicalMessage: 'PlatformException(${exception.code}): $message',
      cause: exception,
    );
  }

  static const Set<String> _networkCodes = {
    'network-request-failed',
    'unavailable',
    'deadline-exceeded',
    'failed-precondition',
  };

  static String? _extractKnownMessage(Object error) {
    final raw = error.toString().trim();
    if (raw.isEmpty) {
      return null;
    }

    if (raw.startsWith('Exception:')) {
      final message = raw.replaceFirst('Exception:', '').trim();
      return message.isNotEmpty ? message : null;
    }

    if (raw.startsWith('Error:')) {
      final message = raw.replaceFirst('Error:', '').trim();
      return message.isNotEmpty ? message : null;
    }

    return raw;
  }
}
