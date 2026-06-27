import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_logger.dart';
import '../../core/errors/error_mapper.dart';
import '../../models/event.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/storage_repository.dart';

class CadastroEventoViewModel extends ChangeNotifier {
  CadastroEventoViewModel({
    required StorageRepository storageRepository,
    required EventRepository eventRepository,
    AppErrorLogger? errorLogger,
    DateTime Function()? now,
  })  : _storageRepository = storageRepository,
        _eventRepository = eventRepository,
        _errorLogger = errorLogger ?? const NoopErrorLogger(),
        _now = now ?? DateTime.now;

  final StorageRepository _storageRepository;
  final EventRepository _eventRepository;
  final AppErrorLogger _errorLogger;
  final DateTime Function() _now;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> cadastrarEvento({
    required String titulo,
    required String cidade,
    required DateTime dataEvento,
    DateTime? dataFimEvento,
    required List<File> imagens,
    String? descricao,
  }) async {
    final tituloLimpo = titulo.trim();
    final cidadeLimpa = cidade.trim();

    if (tituloLimpo.isEmpty || cidadeLimpa.isEmpty || imagens.isEmpty) {
      _errorMessage = 'Dados obrigatorios invalidos para cadastro do evento.';
      notifyListeners();
      return false;
    }

    if (_isBeforeDate(dataEvento, _today())) {
      _errorMessage = 'A data de inicio nao pode ser anterior a data de hoje.';
      notifyListeners();
      return false;
    }

    final dataFimNormalizada = _normalizeEndDate(dataEvento, dataFimEvento);
    if (dataFimNormalizada != null &&
        _isBeforeDate(dataFimNormalizada, dataEvento)) {
      _errorMessage = 'A data de fim nao pode ser anterior a data de inicio.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final urls = <String>[];
      for (final imagem in imagens) {
        final url = await _storageRepository.uploadImagemComSeguranca(imagem);
        urls.add(url);
      }

      await _eventRepository.createEvent(
        titulo: tituloLimpo,
        cidade: cidadeLimpa,
        dataEvento: dataEvento,
        dataFimEvento: dataFimNormalizada,
        imagemUrls: urls,
        descricao: descricao?.trim(),
      );
      return true;
    } catch (error, stackTrace) {
      final mapped = ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.unknown,
        stackTrace: stackTrace,
      );
      _errorMessage = mapped.userMessage;
      unawaited(
        _errorLogger.log(
          mapped,
          stackTrace: stackTrace,
          feature: 'event_form',
          operation: 'create_event',
          fallbackType: AppErrorType.unknown,
          context: {
            'imageCount': imagens.length,
            'hasDescription': descricao?.trim().isNotEmpty ?? false,
          },
        ),
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> atualizarEvento({
    required Event evento,
    required String titulo,
    required String cidade,
    required DateTime dataEvento,
    DateTime? dataFimEvento,
    required List<File> novasImagens,
    String? descricao,
  }) async {
    final tituloLimpo = titulo.trim();
    final cidadeLimpa = cidade.trim();
    final descricaoLimpa = descricao?.trim() ?? '';

    if (tituloLimpo.isEmpty || cidadeLimpa.isEmpty) {
      _errorMessage = 'Dados obrigatorios invalidos para alteracao do evento.';
      notifyListeners();
      return false;
    }

    final dataFimNormalizada = _normalizeEndDate(dataEvento, dataFimEvento);
    if (dataFimNormalizada != null &&
        _isBeforeDate(dataFimNormalizada, dataEvento)) {
      _errorMessage = 'A data de fim nao pode ser anterior a data de inicio.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      var imageUrl = evento.imageUrl;
      if (novasImagens.isNotEmpty) {
        imageUrl = await _storageRepository
            .uploadImagemComSeguranca(novasImagens.first);
      }

      await _eventRepository.updateEvent(
        Event(
          id: evento.id,
          name: tituloLimpo,
          description: descricaoLimpa,
          date: dataEvento,
          endDate: dataFimNormalizada,
          location: cidadeLimpa,
          imageUrl: imageUrl,
          likesCount: evento.likesCount,
          isLiked: evento.isLiked,
        ),
      );
      return true;
    } catch (error, stackTrace) {
      final mapped = ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.unknown,
        stackTrace: stackTrace,
      );
      _errorMessage = mapped.userMessage;
      unawaited(
        _errorLogger.log(
          mapped,
          stackTrace: stackTrace,
          feature: 'event_form',
          operation: 'update_event',
          fallbackType: AppErrorType.unknown,
          context: {
            'eventId': evento.id,
            'newImageCount': novasImagens.length,
            'hasDescription': descricaoLimpa.isNotEmpty,
          },
        ),
      );
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  DateTime? _normalizeEndDate(DateTime startDate, DateTime? endDate) {
    if (endDate == null || _isSameDate(startDate, endDate)) {
      return null;
    }

    return endDate;
  }

  bool _isSameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  bool _isBeforeDate(DateTime first, DateTime second) {
    final firstDate = DateTime(first.year, first.month, first.day);
    final secondDate = DateTime(second.year, second.month, second.day);
    return firstDate.isBefore(secondDate);
  }

  DateTime _today() {
    final now = _now();
    return DateTime(now.year, now.month, now.day);
  }
}
