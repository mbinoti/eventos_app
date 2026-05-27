import 'dart:io';

import 'package:eventos_app/models/event.dart';
import 'package:eventos_app/presentation/viewmodels/cadastro_evento_view_model.dart';
import 'package:eventos_app/repositories/event_repository.dart';
import 'package:eventos_app/repositories/storage_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeStorageRepository implements StorageRepository {
  _FakeStorageRepository({this.shouldThrow = false});

  final bool shouldThrow;

  @override
  Future<String> uploadImagemComSeguranca(File imagemOriginal) async {
    if (shouldThrow) {
      throw Exception('falha-upload');
    }

    return 'https://fake.storage/${imagemOriginal.path.split('/').last}';
  }
}

class _FakeEventRepository implements EventRepository {
  bool shouldThrow = false;

  String? titulo;
  String? cidade;
  String? descricao;
  DateTime? dataEvento;
  List<String>? imagemUrls;

  @override
  Future<void> addEvent(Event event) async {}

  @override
  Future<void> deleteEvent(String id) async {}

  @override
  Future<List<Event>> getEvents() async => [];

  @override
  Future<void> createEvent({
    required String titulo,
    required String cidade,
    required DateTime dataEvento,
    required List<String> imagemUrls,
    String? descricao,
  }) async {
    if (shouldThrow) {
      throw Exception('falha-create-event');
    }

    this.titulo = titulo;
    this.cidade = cidade;
    this.descricao = descricao;
    this.dataEvento = dataEvento;
    this.imagemUrls = imagemUrls;
  }

  @override
  Future<void> updateEvent(Event event) async {}
}

void main() {
  group('CadastroEventoViewModel', () {
    test('retorna false quando dados obrigatorios sao invalidos', () async {
      final eventRepository = _FakeEventRepository();
      final viewModel = CadastroEventoViewModel(
        storageRepository: _FakeStorageRepository(),
        eventRepository: eventRepository,
      );

      final result = await viewModel.cadastrarEvento(
        titulo: '   ',
        cidade: 'Curitiba',
        dataEvento: DateTime(2026, 5, 26),
        imagens: const [],
      );

      expect(result, isFalse);
      expect(
        viewModel.errorMessage,
        'Dados obrigatorios invalidos para cadastro do evento.',
      );
      expect(eventRepository.titulo, isNull);
    });

    test('cadastra evento com descricao e urls de upload', () async {
      final eventRepository = _FakeEventRepository();
      final viewModel = CadastroEventoViewModel(
        storageRepository: _FakeStorageRepository(),
        eventRepository: eventRepository,
      );

      final result = await viewModel.cadastrarEvento(
        titulo: ' Feira de Artes ',
        cidade: ' Sao Paulo ',
        dataEvento: DateTime(2026, 6, 1),
        imagens: [File('/tmp/img1.jpg'), File('/tmp/img2.jpg')],
        descricao: 'Entrada gratuita',
      );

      expect(result, isTrue);
      expect(viewModel.errorMessage, isNull);
      expect(eventRepository.titulo, 'Feira de Artes');
      expect(eventRepository.cidade, 'Sao Paulo');
      expect(eventRepository.descricao, 'Entrada gratuita');
      expect(eventRepository.imagemUrls, hasLength(2));
      expect(eventRepository.imagemUrls!.first, contains('img1.jpg'));
      expect(viewModel.isLoading, isFalse);
    });

    test('retorna false e expoe erro quando upload falha', () async {
      final viewModel = CadastroEventoViewModel(
        storageRepository: _FakeStorageRepository(shouldThrow: true),
        eventRepository: _FakeEventRepository(),
      );

      final result = await viewModel.cadastrarEvento(
        titulo: 'Show',
        cidade: 'Recife',
        dataEvento: DateTime(2026, 7, 10),
        imagens: [File('/tmp/img1.jpg')],
      );

      expect(result, isFalse);
      expect(viewModel.errorMessage, contains('falha-upload'));
      expect(viewModel.isLoading, isFalse);
    });
  });
}
