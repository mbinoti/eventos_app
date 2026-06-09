import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../core/errors/error_mapper.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/storage_repository.dart';

class CadastroEventoViewModel extends ChangeNotifier {
  CadastroEventoViewModel({
    required StorageRepository storageRepository,
    required EventRepository eventRepository,
  })  : _storageRepository = storageRepository,
        _eventRepository = eventRepository;

  final StorageRepository _storageRepository;
  final EventRepository _eventRepository;

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
    } catch (error) {
      _errorMessage = ErrorMapper.fromObject(error).userMessage;
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
}
