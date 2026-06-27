import 'dart:async';

import 'package:eventos_app/models/event.dart';
import 'package:eventos_app/models/event_like_state.dart';
import 'package:eventos_app/presentation/viewmodels/event_feed_view_model.dart';
import 'package:eventos_app/repositories/event_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _RealtimeEventRepository implements EventRepository {
  final _eventsController = StreamController<List<Event>>();
  final _likeStateControllers = <String, StreamController<EventLikeState>>{};
  List<Event> events = const [];
  final deletedEventIds = <String>[];

  void emit(List<Event> nextEvents) {
    events = nextEvents;
    _eventsController.add(nextEvents);
  }

  Future<void> close() async {
    await _eventsController.close();
    for (final controller in _likeStateControllers.values) {
      await controller.close();
    }
  }

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
  Future<void> deleteEvent(String id) async {
    deletedEventIds.add(id);
  }

  @override
  Future<List<Event>> getEvents() async => events;

  @override
  Stream<List<Event>> watchEvents() => _eventsController.stream;

  @override
  Stream<Event?> watchEvent(String eventId) => _eventsController.stream
      .map((events) => events.firstWhere((event) => event.id == eventId));

  @override
  Stream<EventLikeState> watchEventLikeState(String eventId) {
    return _likeStateControllers
        .putIfAbsent(eventId, StreamController<EventLikeState>.new)
        .stream;
  }

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
    final nextLikes = isLiked
        ? event.likesCount + 1
        : event.likesCount > 0
            ? event.likesCount - 1
            : 0;

    return EventLikeState(
      likesCount: nextLikes,
      isLiked: isLiked,
    );
  }

  @override
  Future<void> updateEvent(Event event) async {}
}

void main() {
  group('EventFeedViewModel', () {
    test('updates the feed when the repository stream emits new events',
        () async {
      final repository = _RealtimeEventRepository();
      final viewModel = EventFeedViewModel(
        repository,
        now: () => DateTime(2026, 6, 20, 10),
      );
      addTearDown(() async {
        viewModel.dispose();
        await repository.close();
      });

      expect(viewModel.isLoading, isTrue);

      repository.emit([_event('festival')]);
      await pumpEventQueue();

      expect(viewModel.isLoading, isFalse);
      expect(viewModel.events.map((event) => event.id), ['festival']);

      repository.emit([_event('festival'), _event('cinema')]);
      await pumpEventQueue();

      expect(viewModel.events.map((event) => event.id), [
        'festival',
        'cinema',
      ]);
    });

    test('does not show events with a start date before today', () async {
      final repository = _RealtimeEventRepository();
      final viewModel = EventFeedViewModel(
        repository,
        now: () => DateTime(2026, 6, 22, 10),
      );
      addTearDown(() async {
        viewModel.dispose();
        await repository.close();
      });

      repository.emit([
        _event('past', date: DateTime(2026, 6, 21, 23, 59)),
        _event('today', date: DateTime(2026, 6, 22, 23, 59)),
        _event('future', date: DateTime(2026, 6, 23)),
      ]);
      await pumpEventQueue();

      expect(viewModel.events.map((event) => event.id), ['today', 'future']);
    });

    test('applies the start-date filter when events are manually loaded',
        () async {
      final repository = _RealtimeEventRepository()
        ..events = [
          _event('today', date: DateTime(2026, 6, 22)),
          _event('future', date: DateTime(2026, 6, 23)),
        ];
      final viewModel = EventFeedViewModel(
        repository,
        now: () => DateTime(2026, 6, 22, 18),
      );
      addTearDown(() async {
        viewModel.dispose();
        await repository.close();
      });

      await viewModel.loadEvents();

      expect(viewModel.events.map((event) => event.id), ['today', 'future']);
    });

    test('keeps local liked state when realtime event data refreshes',
        () async {
      final repository = _RealtimeEventRepository();
      final viewModel = EventFeedViewModel(
        repository,
        now: () => DateTime(2026, 6, 20, 10),
      );
      addTearDown(() async {
        viewModel.dispose();
        await repository.close();
      });

      repository.emit([_event('show', likesCount: 4)]);
      await pumpEventQueue();

      await viewModel.setEventLiked('show', true);

      expect(viewModel.events.single.isLiked, isTrue);
      expect(viewModel.events.single.likesCount, 5);

      repository.emit([_event('show', likesCount: 9)]);
      await pumpEventQueue();

      expect(viewModel.events.single.isLiked, isTrue);
      expect(viewModel.events.single.likesCount, 9);
    });

    test('removes deleted event locally and returns success', () async {
      final repository = _RealtimeEventRepository();
      final viewModel = EventFeedViewModel(
        repository,
        now: () => DateTime(2026, 6, 20, 10),
      );
      addTearDown(() async {
        viewModel.dispose();
        await repository.close();
      });

      repository.emit([_event('festival'), _event('cinema')]);
      await pumpEventQueue();

      final result = await viewModel.deleteEvent('festival');

      expect(result, isTrue);
      expect(repository.deletedEventIds, ['festival']);
      expect(viewModel.events.map((event) => event.id), ['cinema']);
    });

    test('watchEvent emits null when realtime feed removes the event',
        () async {
      final repository = _RealtimeEventRepository();
      final viewModel = EventFeedViewModel(
        repository,
        now: () => DateTime(2026, 6, 20, 10),
      );
      addTearDown(() async {
        viewModel.dispose();
        await repository.close();
      });

      repository.emit([_event('festival')]);
      await pumpEventQueue();

      final expectation = expectLater(
        viewModel.watchEvent('festival'),
        emitsInOrder([
          isA<Event>().having((event) => event.id, 'id', 'festival'),
          isNull,
        ]),
      );

      repository.emit(const []);
      await expectation;
    });
  });
}

Event _event(String id, {int likesCount = 0, DateTime? date}) {
  return Event(
    id: id,
    name: 'Event $id',
    description: 'Description $id',
    date: date ?? DateTime(2026, 6, 20),
    location: 'City',
    imageUrl: '',
    likesCount: likesCount,
  );
}
