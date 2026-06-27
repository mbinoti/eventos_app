enum AppErrorType {
  network,
  database,
  storage,
  validation,
  permission,
  notFound,
  unknown,
}

class AppException implements Exception {
  const AppException({
    required this.type,
    required this.userMessage,
    this.technicalMessage,
    this.cause,
    this.stackTrace,
  });

  final AppErrorType type;
  final String userMessage;
  final String? technicalMessage;
  final Object? cause;
  final StackTrace? stackTrace;

  factory AppException.validation(String userMessage) {
    return AppException(
        type: AppErrorType.validation, userMessage: userMessage);
  }

  factory AppException.notFound(String userMessage) {
    return AppException(type: AppErrorType.notFound, userMessage: userMessage);
  }

  factory AppException.unknown({
    required String userMessage,
    String? technicalMessage,
    Object? cause,
    StackTrace? stackTrace,
  }) {
    return AppException(
      type: AppErrorType.unknown,
      userMessage: userMessage,
      technicalMessage: technicalMessage,
      cause: cause,
      stackTrace: stackTrace,
    );
  }

  AppException withStackTrace(StackTrace? fallbackStackTrace) {
    if (stackTrace != null || fallbackStackTrace == null) {
      return this;
    }

    return AppException(
      type: type,
      userMessage: userMessage,
      technicalMessage: technicalMessage,
      cause: cause,
      stackTrace: fallbackStackTrace,
    );
  }

  @override
  String toString() => userMessage;
}
