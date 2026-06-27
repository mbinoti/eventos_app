import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../services/env.dart';
import 'app_exception.dart';
import 'error_mapper.dart';

abstract interface class AppErrorLogger {
  Future<void> log(
    Object error, {
    StackTrace? stackTrace,
    String feature = 'unknown',
    String operation = 'unknown',
    AppErrorType fallbackType = AppErrorType.unknown,
    Map<String, Object?> context = const {},
    bool fatal = false,
  });
}

class NoopErrorLogger implements AppErrorLogger {
  const NoopErrorLogger();

  @override
  Future<void> log(
    Object error, {
    StackTrace? stackTrace,
    String feature = 'unknown',
    String operation = 'unknown',
    AppErrorType fallbackType = AppErrorType.unknown,
    Map<String, Object?> context = const {},
    bool fatal = false,
  }) async {}
}

class FirestoreErrorLogger implements AppErrorLogger {
  FirestoreErrorLogger({
    FirebaseFirestore? firestore,
    this.collectionPath = 'app_error_logs',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String collectionPath;

  @override
  Future<void> log(
    Object error, {
    StackTrace? stackTrace,
    String feature = 'unknown',
    String operation = 'unknown',
    AppErrorType fallbackType = AppErrorType.unknown,
    Map<String, Object?> context = const {},
    bool fatal = false,
  }) async {
    final mapped = ErrorMapper.fromObject(
      error,
      fallbackType: fallbackType,
      stackTrace: stackTrace,
    );
    final cause = mapped.cause ?? error;
    final effectiveStackTrace = mapped.stackTrace ?? stackTrace;

    final payload = <String, dynamic>{
      'createdAt': FieldValue.serverTimestamp(),
      'environment': Env.flavor,
      'buildNumber': Env.buildNumber,
      'gitSha': Env.gitSha,
      'feature': _redactText(feature),
      'operation': _redactText(operation),
      'type': mapped.type.name,
      'userMessage': _redactText(mapped.userMessage),
      'technicalMessage': _truncate(
        _redactText(mapped.technicalMessage ?? cause.toString()),
        2000,
      ),
      'errorClass': cause.runtimeType.toString(),
      'stackTrace': effectiveStackTrace == null
          ? null
          : _truncate(_redactText(effectiveStackTrace.toString()), 6000),
      'fatal': fatal,
      'platform': defaultTargetPlatform.name,
      'isWeb': kIsWeb,
      'context': _sanitizeContext(context),
    };

    try {
      await _firestore.collection(collectionPath).add(payload);
    } catch (loggingError, loggingStackTrace) {
      debugPrint(
        'Nao foi possivel registrar o erro no Firebase: '
        '$loggingError\n$loggingStackTrace',
      );
    }
  }

  Map<String, dynamic> _sanitizeContext(Map<String, Object?> context) {
    final sanitized = <String, dynamic>{};

    for (final entry in context.entries) {
      if (_containsSensitiveKey(entry.key)) {
        sanitized[entry.key] = '[redigido]';
        continue;
      }

      sanitized[entry.key] = _sanitizeValue(entry.value);
    }

    return sanitized;
  }

  Object? _sanitizeValue(Object? value) {
    if (value == null || value is num || value is bool) {
      return value;
    }

    if (value is DateTime) {
      return value.toIso8601String();
    }

    if (value is Iterable) {
      return value.map(_sanitizeValue).toList(growable: false);
    }

    if (value is Map) {
      final sanitized = <String, dynamic>{};
      for (final entry in value.entries) {
        final key = entry.key.toString();
        sanitized[key] = _containsSensitiveKey(key)
            ? '[redigido]'
            : _sanitizeValue(entry.value);
      }
      return sanitized;
    }

    return _truncate(_redactText(value.toString()), 500);
  }

  bool _containsSensitiveKey(String key) {
    final normalizedKey = key.toLowerCase();
    return _sensitiveKeyParts.any(normalizedKey.contains);
  }

  String _redactText(String text) {
    final withoutEmails = text.replaceAll(
      RegExp(
        r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
        caseSensitive: false,
      ),
      '[email]',
    );

    return withoutEmails.replaceAllMapped(
      RegExp(
        r'(password|senha|token|authorization|bearer)\s*[:=]\s*[^,\s]+',
        caseSensitive: false,
      ),
      (match) => '${match.group(1)}=[redigido]',
    );
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }

    return '${text.substring(0, maxLength)}...';
  }

  static const _sensitiveKeyParts = {
    'authorization',
    'cpf',
    'email',
    'password',
    'senha',
    'telefone',
    'token',
  };
}
