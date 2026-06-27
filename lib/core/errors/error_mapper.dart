import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import 'app_exception.dart';

class ErrorMapper {
  static AppException fromObject(
    Object error, {
    AppErrorType fallbackType = AppErrorType.unknown,
    StackTrace? stackTrace,
  }) {
    if (error is AppException) {
      return error.withStackTrace(stackTrace);
    }

    if (error is FirebaseException) {
      return fromFirebaseException(
        error,
        fallbackType: fallbackType,
        stackTrace: stackTrace,
      );
    }

    if (error is PlatformException) {
      return _fromPlatformException(
        error,
        fallbackType: fallbackType,
        stackTrace: stackTrace,
      );
    }

    if (error is SocketException || error is TimeoutException) {
      return AppException(
        type: AppErrorType.network,
        userMessage:
            'Sem conexao com a internet no momento. Verifique sua rede e tente novamente.',
        technicalMessage: error.toString(),
        cause: error,
        stackTrace: stackTrace,
      );
    }

    return AppException(
      type: fallbackType,
      userMessage: fallbackMessageFor(fallbackType),
      technicalMessage: error.toString(),
      cause: error,
      stackTrace: stackTrace,
    );
  }

  static AppException fromFirebaseException(
    FirebaseException exception, {
    AppErrorType fallbackType = AppErrorType.unknown,
    StackTrace? stackTrace,
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
        stackTrace: stackTrace,
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
        stackTrace: stackTrace,
      );
    }

    if (code == 'not-found' || code == 'object-not-found') {
      return AppException(
        type: AppErrorType.notFound,
        userMessage: 'O recurso solicitado nao foi encontrado.',
        technicalMessage:
            'FirebaseException(${exception.code}): ${exception.message}',
        cause: exception,
        stackTrace: stackTrace,
      );
    }

    return AppException(
      type: fallbackType,
      userMessage: fallbackMessageFor(fallbackType),
      technicalMessage:
          'FirebaseException(${exception.code}): ${exception.message}',
      cause: exception,
      stackTrace: stackTrace,
    );
  }

  static String fallbackMessageFor(AppErrorType type) {
    return switch (type) {
      AppErrorType.network =>
        'Sem conexao com a internet no momento. Verifique sua rede e tente novamente.',
      AppErrorType.database =>
        'Nao foi possivel acessar os dados agora. Tente novamente em instantes.',
      AppErrorType.storage =>
        'Nao foi possivel enviar a imagem agora. Tente novamente em instantes.',
      AppErrorType.validation =>
        'Revise os dados informados e tente novamente.',
      AppErrorType.permission =>
        'Voce nao tem permissao para realizar esta acao. Fale com o administrador.',
      AppErrorType.notFound => 'O recurso solicitado nao foi encontrado.',
      AppErrorType.unknown =>
        'Ocorreu um erro inesperado. Tente novamente em instantes.',
    };
  }

  static AppException _fromPlatformException(
    PlatformException exception, {
    required AppErrorType fallbackType,
    StackTrace? stackTrace,
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
        stackTrace: stackTrace,
      );
    }

    return AppException(
      type: fallbackType,
      userMessage: fallbackMessageFor(fallbackType),
      technicalMessage: 'PlatformException(${exception.code}): $message',
      cause: exception,
      stackTrace: stackTrace,
    );
  }

  static const Set<String> _networkCodes = {
    'network-request-failed',
    'unavailable',
    'deadline-exceeded',
  };
}
