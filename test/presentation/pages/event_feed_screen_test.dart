import 'dart:io';

import 'package:eventos_app/app_theme.dart';
import 'package:eventos_app/models/event.dart';
import 'package:eventos_app/models/event_like_state.dart';
import 'package:eventos_app/presentation/pages/event_feed_screen.dart';
import 'package:eventos_app/presentation/viewmodels/event_feed_view_model.dart';
import 'package:eventos_app/repositories/event_repository.dart';
import 'package:eventos_app/repositories/storage_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeEventRepository implements EventRepository {
  _FakeEventRepository({this.events = const []});

  final List<Event> events;

  @override
  Future<void> addEvent(Event event) async {}

  @override
  Future<void> createEvent({
    required String titulo,
    required String cidade,
    required DateTime dataEvento,
    DateTime? dataFimEvento,
    required List<String> imagemUrls,
    String? descricao,
  }) async {}

  @override
  Future<void> deleteEvent(String id) async {}

  @override
  Future<List<Event>> getEvents() async => events;

  @override
  Future<EventLikeState> getEventLikeState(String id) async {
    final event = events.firstWhere((event) => event.id == id);
    return EventLikeState(
      likesCount: event.likesCount,
      isLiked: event.isLiked,
    );
  }

  @override
  Future<EventLikeState> setEventLiked({
    required String eventId,
    required bool isLiked,
  }) async {
    final event = events.firstWhere((event) => event.id == eventId);
    return EventLikeState(
      likesCount: isLiked ? event.likesCount + 1 : event.likesCount,
      isLiked: isLiked,
    );
  }

  @override
  Future<void> updateEvent(Event event) async {}
}

class _FakeStorageRepository implements StorageRepository {
  @override
  Future<String> uploadImagemComSeguranca(File imagemOriginal) async {
    return 'https://fake.storage/${imagemOriginal.path.split('/').last}';
  }
}

void main() {
  final events = [
    Event(
      id: 'festival-gastronomico-2026',
      name: 'Festival Gastronômico Sabores da Serra',
      description:
          'Chefs locais apresentam menus especiais, produtores artesanais e música ao vivo.',
      date: DateTime(2026, 6, 20),
      location: 'Petrópolis, RJ',
      imageUrl: '',
      likesCount: 34,
    ),
    Event(
      id: 'cinema-praca-2026',
      name: 'Cinema na Praça',
      description:
          'Sessão gratuita ao ar livre com programação para toda a família.',
      date: DateTime(2026, 6, 27),
      location: 'Tiradentes, MG',
      imageUrl: '',
      likesCount: 18,
    ),
  ];

  testWidgets('apresenta a agenda e os eventos em ordem de leitura',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: EventFeedList(
            events: events,
            isAdmin: false,
            isIOS: false,
            onRefresh: () async {},
            onDeleteEvent: (_) async => true,
            onLoadLikeState: (_) async => const EventLikeState(
              likesCount: 0,
              isLiked: false,
            ),
            onLikeEvent: (_, isLiked) async => EventLikeState(
              likesCount: isLiked ? 1 : 0,
              isLiked: isLiked,
            ),
          ),
        ),
      ),
    );

    expect(find.text('AGENDA LOCAL'), findsOneWidget);
    expect(find.text('Eventos para descobrir'), findsOneWidget);
    expect(
      find.text('2 eventos publicados, em ordem de data.'),
      findsOneWidget,
    );
    expect(
      find.text('Festival Gastronômico Sabores da Serra'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('Cinema na Praça'),
      400,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('Cinema na Praça'), findsOneWidget);
  });

  testWidgets('abre detalhe do evento ao tocar na lista', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: EventFeedList(
            events: events,
            isAdmin: false,
            isIOS: false,
            onRefresh: () async {},
            onDeleteEvent: (_) async => true,
            onLoadLikeState: (_) async => const EventLikeState(
              likesCount: 0,
              isLiked: false,
            ),
            onLikeEvent: (_, isLiked) async => EventLikeState(
              likesCount: isLiked ? 1 : 0,
              isLiked: isLiked,
            ),
          ),
        ),
      ),
    );

    expect(find.text(events.first.description), findsNothing);

    await tester.tap(find.text('Festival Gastronômico Sabores da Serra'));
    await tester.pumpAndSettle();

    expect(find.text('Evento'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Sobre o evento'),
      400,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('Sobre o evento'), findsOneWidget);
    expect(find.text(events.first.description), findsOneWidget);
    expect(find.text('Imagem do evento indisponível'), findsOneWidget);
  });

  testWidgets('sincroniza curtida a partir do detalhe aberto pela lista',
      (tester) async {
    bool? requestedLikeState;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: EventFeedList(
            events: events,
            isAdmin: false,
            isIOS: false,
            onRefresh: () async {},
            onDeleteEvent: (_) async => true,
            onLoadLikeState: (_) async => const EventLikeState(
              likesCount: 2,
              isLiked: false,
            ),
            onLikeEvent: (_, isLiked) async {
              requestedLikeState = isLiked;
              return EventLikeState(
                likesCount: isLiked ? 3 : 2,
                isLiked: isLiked,
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Festival Gastronômico Sabores da Serra'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byIcon(Icons.favorite_border_rounded));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pumpAndSettle();

    expect(requestedLikeState, isTrue);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('mantem login visivel e abre cadastro apos autenticar',
      (tester) async {
    final eventRepository = _FakeEventRepository(events: events);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<EventRepository>.value(value: eventRepository),
          Provider<StorageRepository>.value(value: _FakeStorageRepository()),
          ChangeNotifierProvider<EventFeedViewModel>(
            create: (_) => EventFeedViewModel(eventRepository),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: const EventFeedScreen(isAdmin: false),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Login'), findsOneWidget);
    expect(find.byIcon(Icons.login), findsOneWidget);

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'admin');
    await tester.enterText(find.byType(TextFormField).at(1), 'admin');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.text('Cadastrar Evento'), findsOneWidget);
    expect(find.text('Título'), findsOneWidget);
  });
}
