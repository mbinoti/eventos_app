import 'dart:io';

import 'package:flutter/foundation.dart';

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
        imagemUrls: urls,
        descricao: descricao?.trim(),
      );
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
