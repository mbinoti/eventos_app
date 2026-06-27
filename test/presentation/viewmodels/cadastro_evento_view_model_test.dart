import 'dart:io';

import 'package:eventos_app/core/errors/app_exception.dart';
import 'package:eventos_app/core/errors/error_logger.dart';
import 'package:eventos_app/models/event.dart';
import 'package:eventos_app/models/event_like_state.dart';
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
  DateTime? dataFimEvento;
  List<String>? imagemUrls;
  Event? updatedEvent;

  @override
  Future<void> addEvent(Event event) async {}

  @override
  Future<void> deleteEvent(String id) async {}

  @override
  Future<List<Event>> getEvents() async => [];

  @override
  Stream<List<Event>> watchEvents() => Stream.value(const []);

  @override
  Stream<Event?> watchEvent(String eventId) => const Stream.empty();

  @override
  Stream<EventLikeState> watchEventLikeState(String eventId) {
    return Stream.value(const EventLikeState(likesCount: 0, isLiked: false));
  }

  @override
  Future<EventLikeState> getEventLikeState(String id) async {
    return const EventLikeState(likesCount: 0, isLiked: false);
  }

  @override
  Future<EventLikeState> setEventLiked({
    required String eventId,
    required bool isLiked,
  }) async {
    return EventLikeState(likesCount: isLiked ? 1 : 0, isLiked: isLiked);
  }

  @override
  Future<void> createEvent({
    required String titulo,
    required String cidade,
    required DateTime dataEvento,
    DateTime? dataFimEvento,
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
    this.dataFimEvento = dataFimEvento;
    this.imagemUrls = imagemUrls;
  }

  @override
  Future<void> updateEvent(Event event) async {
    if (shouldThrow) {
      throw Exception('falha-update-event');
    }

    updatedEvent = event;
  }
}

class _LoggedError {
  const _LoggedError({
    required this.error,
    required this.feature,
    required this.operation,
    required this.context,
  });

  final Object error;
  final String feature;
  final String operation;
  final Map<String, Object?> context;
}

class _FakeErrorLogger implements AppErrorLogger {
  final entries = <_LoggedError>[];

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
    entries.add(
      _LoggedError(
        error: error,
        feature: feature,
        operation: operation,
        context: context,
      ),
    );
  }
}

void main() {
  group('CadastroEventoViewModel', () {
    test('retorna false quando dados obrigatorios sao invalidos', () async {
      final eventRepository = _FakeEventRepository();
      final viewModel = CadastroEventoViewModel(
        storageRepository: _FakeStorageRepository(),
        eventRepository: eventRepository,
        now: () => DateTime(2026, 6, 1, 9),
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

    test('retorna false quando data de inicio e anterior a data de hoje',
        () async {
      final eventRepository = _FakeEventRepository();
      final viewModel = CadastroEventoViewModel(
        storageRepository: _FakeStorageRepository(),
        eventRepository: eventRepository,
        now: () => DateTime(2026, 6, 2, 15),
      );

      final result = await viewModel.cadastrarEvento(
        titulo: 'Feira de Artes',
        cidade: 'Sao Paulo',
        dataEvento: DateTime(2026, 6, 1, 23, 59),
        imagens: [File('/tmp/img1.jpg')],
      );

      expect(result, isFalse);
      expect(
        viewModel.errorMessage,
        'A data de inicio nao pode ser anterior a data de hoje.',
      );
      expect(eventRepository.titulo, isNull);
    });

    test('cadastra evento com descricao e urls de upload', () async {
      final eventRepository = _FakeEventRepository();
      final viewModel = CadastroEventoViewModel(
        storageRepository: _FakeStorageRepository(),
        eventRepository: eventRepository,
        now: () => DateTime(2026, 6, 1, 9),
      );

      final result = await viewModel.cadastrarEvento(
        titulo: ' Feira de Artes ',
        cidade: ' Sao Paulo ',
        dataEvento: DateTime(2026, 6, 1),
        dataFimEvento: DateTime(2026, 6, 3),
        imagens: [File('/tmp/img1.jpg'), File('/tmp/img2.jpg')],
        descricao: 'Entrada gratuita',
      );

      expect(result, isTrue);
      expect(viewModel.errorMessage, isNull);
      expect(eventRepository.titulo, 'Feira de Artes');
      expect(eventRepository.cidade, 'Sao Paulo');
      expect(eventRepository.descricao, 'Entrada gratuita');
      expect(eventRepository.dataEvento, DateTime(2026, 6, 1));
      expect(eventRepository.dataFimEvento, DateTime(2026, 6, 3));
      expect(eventRepository.imagemUrls, hasLength(2));
      expect(eventRepository.imagemUrls!.first, contains('img1.jpg'));
      expect(viewModel.isLoading, isFalse);
    });

    test('retorna false quando data de fim vem antes da data de inicio',
        () async {
      final eventRepository = _FakeEventRepository();
      final viewModel = CadastroEventoViewModel(
        storageRepository: _FakeStorageRepository(),
        eventRepository: eventRepository,
        now: () => DateTime(2026, 6, 1, 9),
      );

      final result = await viewModel.cadastrarEvento(
        titulo: 'Feira de Artes',
        cidade: 'Sao Paulo',
        dataEvento: DateTime(2026, 6, 3),
        dataFimEvento: DateTime(2026, 6, 1),
        imagens: [File('/tmp/img1.jpg')],
      );

      expect(result, isFalse);
      expect(
        viewModel.errorMessage,
        'A data de fim nao pode ser anterior a data de inicio.',
      );
      expect(eventRepository.titulo, isNull);
    });

    test('retorna false e expoe erro quando upload falha', () async {
      final errorLogger = _FakeErrorLogger();
      final viewModel = CadastroEventoViewModel(
        storageRepository: _FakeStorageRepository(shouldThrow: true),
        eventRepository: _FakeEventRepository(),
        errorLogger: errorLogger,
        now: () => DateTime(2026, 6, 1, 9),
      );

      final result = await viewModel.cadastrarEvento(
        titulo: 'Show',
        cidade: 'Recife',
        dataEvento: DateTime(2026, 7, 10),
        imagens: [File('/tmp/img1.jpg')],
      );

      expect(result, isFalse);
      expect(
        viewModel.errorMessage,
        'Ocorreu um erro inesperado. Tente novamente em instantes.',
      );
      expect(viewModel.isLoading, isFalse);
      expect(errorLogger.entries, hasLength(1));
      expect(errorLogger.entries.single.feature, 'event_form');
      expect(errorLogger.entries.single.operation, 'create_event');
      expect(errorLogger.entries.single.context['imageCount'], 1);

      final loggedError = errorLogger.entries.single.error;
      expect(loggedError, isA<AppException>());
      expect(
        (loggedError as AppException).technicalMessage,
        contains('falha-upload'),
      );
    });

    test('atualiza evento mantendo imagem atual quando nenhuma nova e enviada',
        () async {
      final eventRepository = _FakeEventRepository();
      final viewModel = CadastroEventoViewModel(
        storageRepository: _FakeStorageRepository(),
        eventRepository: eventRepository,
      );
      final evento = Event(
        id: 'show-2026',
        name: 'Show antigo',
        description: 'Descricao antiga',
        date: DateTime(2026, 7, 1),
        location: 'Recife',
        imageUrl: 'https://fake.storage/atual.jpg',
        likesCount: 7,
        isLiked: true,
      );

      final result = await viewModel.atualizarEvento(
        evento: evento,
        titulo: ' Show novo ',
        cidade: ' Olinda ',
        dataEvento: DateTime(2026, 7, 2),
        novasImagens: const [],
        descricao: 'Entrada franca',
      );

      expect(result, isTrue);
      expect(viewModel.errorMessage, isNull);
      expect(eventRepository.updatedEvent, isNotNull);
      expect(eventRepository.updatedEvent!.id, 'show-2026');
      expect(eventRepository.updatedEvent!.name, 'Show novo');
      expect(eventRepository.updatedEvent!.location, 'Olinda');
      expect(eventRepository.updatedEvent!.date, DateTime(2026, 7, 2));
      expect(eventRepository.updatedEvent!.description, 'Entrada franca');
      expect(
        eventRepository.updatedEvent!.imageUrl,
        'https://fake.storage/atual.jpg',
      );
      expect(eventRepository.updatedEvent!.likesCount, 7);
      expect(eventRepository.updatedEvent!.isLiked, isTrue);
    });
  });
}
