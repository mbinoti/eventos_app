import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import '../../core/errors/error_logger.dart';
import '../../core/errors/error_mapper.dart';
import '../../models/event.dart';
import '../../models/event_like_state.dart';
import '../../repositories/event_repository.dart';

class EventFeedViewModel extends ChangeNotifier {
  EventFeedViewModel(
    this._eventRepository, {
    AppErrorLogger? errorLogger,
    DateTime Function()? now,
  })  : _errorLogger = errorLogger ?? const NoopErrorLogger(),
        _now = now ?? DateTime.now {
    _listenToEvents();
  }

  final EventRepository _eventRepository;
  final AppErrorLogger _errorLogger;
  final DateTime Function() _now;
  final StreamController<List<Event>> _eventUpdates =
      StreamController<List<Event>>.broadcast(sync: true);
  StreamSubscription<List<Event>>? _eventsSubscription;
  bool _isDisposed = false;

  bool _isLoading = true;
  List<Event> _events = [];
  String? _errorMessage;
  String? _likeErrorMessage;

  bool get isLoading => _isLoading;
  List<Event> get events => List.unmodifiable(_events);
  String? get errorMessage => _errorMessage;
  String? get likeErrorMessage => _likeErrorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => !_isLoading && !hasError && _events.isEmpty;

  void _listenToEvents() {
    _eventsSubscription = _eventRepository.watchEvents().listen(
      (events) {
        _events = _visibleEvents(events);
        _errorMessage = null;
        _isLoading = false;
        _publishEvents();
        _notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        final mapped = ErrorMapper.fromObject(
          error,
          fallbackType: AppErrorType.database,
          stackTrace: stackTrace,
        );
        _errorMessage = mapped.userMessage;
        _events = [];
        _isLoading = false;
        _logError(
          mapped,
          stackTrace: stackTrace,
          operation: 'watch_events',
          fallbackType: AppErrorType.database,
        );
        _notifyListeners();
      },
    );
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    _errorMessage = null;
    _notifyListeners();

    try {
      final events = await _eventRepository.getEvents();
      _events = _visibleEvents(events);
      _publishEvents();
    } catch (error, stackTrace) {
      final mapped = ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.database,
        stackTrace: stackTrace,
      );
      _errorMessage = mapped.userMessage;
      _events = [];
      _logError(
        mapped,
        stackTrace: stackTrace,
        operation: 'load_events',
        fallbackType: AppErrorType.database,
      );
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  Future<bool> deleteEvent(String id) async {
    try {
      await _eventRepository.deleteEvent(id);
      _events = [
        for (final event in _events)
          if (event.id != id) event,
      ];
      _errorMessage = null;
      _publishEvents();
      _notifyListeners();
      return true;
    } catch (error, stackTrace) {
      final mapped = ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.database,
        stackTrace: stackTrace,
      );
      _errorMessage = mapped.userMessage;
      _logError(
        mapped,
        stackTrace: stackTrace,
        operation: 'delete_event',
        fallbackType: AppErrorType.database,
        context: {'eventId': id},
      );
      _notifyListeners();
      return false;
    }
  }

  Future<EventLikeState?> getEventLikeState(String id) async {
    try {
      final likeState = await _eventRepository.getEventLikeState(id);
      _likeErrorMessage = null;
      _replaceEventLikeState(id, likeState);
      return likeState;
    } catch (error, stackTrace) {
      final mapped = ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.database,
        stackTrace: stackTrace,
      );
      _likeErrorMessage = mapped.userMessage;
      _logError(
        mapped,
        stackTrace: stackTrace,
        operation: 'load_like_state',
        fallbackType: AppErrorType.database,
        context: {'eventId': id},
      );
      return null;
    }
  }

  Stream<EventLikeState> watchEventLikeState(String id) {
    return _eventRepository.watchEventLikeState(id).handleError(
      (Object error, StackTrace stackTrace) {
        final mapped = ErrorMapper.fromObject(
          error,
          fallbackType: AppErrorType.database,
          stackTrace: stackTrace,
        );
        _likeErrorMessage = mapped.userMessage;
        _logError(
          mapped,
          stackTrace: stackTrace,
          operation: 'watch_like_state',
          fallbackType: AppErrorType.database,
          context: {'eventId': id},
        );
        _notifyListeners();
        throw mapped;
      },
    );
  }

  Stream<Event?> watchEvent(String id) {
    return Stream<Event?>.multi((controller) {
      final subscription = _eventUpdates.stream.listen(
        (events) => controller.add(_findEvent(events, id)),
      );
      controller.onCancel = subscription.cancel;

      if (!_isLoading && !hasError) {
        controller.add(_findEvent(_events, id));
      }
    });
  }

  Future<EventLikeState?> setEventLiked(String id, bool isLiked) async {
    try {
      final likeState = await _eventRepository.setEventLiked(
        eventId: id,
        isLiked: isLiked,
      );
      _likeErrorMessage = null;
      _replaceEventLikeState(id, likeState);
      return likeState;
    } catch (error, stackTrace) {
      final mapped = ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.database,
        stackTrace: stackTrace,
      );
      _likeErrorMessage = mapped.userMessage;
      _logError(
        mapped,
        stackTrace: stackTrace,
        operation: isLiked ? 'like_event' : 'unlike_event',
        fallbackType: AppErrorType.database,
        context: {'eventId': id},
      );
      return null;
    }
  }

  void _logError(
    Object error, {
    required StackTrace stackTrace,
    required String operation,
    required AppErrorType fallbackType,
    Map<String, Object?> context = const {},
  }) {
    unawaited(
      _errorLogger.log(
        error,
        stackTrace: stackTrace,
        feature: 'event_feed',
        operation: operation,
        fallbackType: fallbackType,
        context: context,
      ),
    );
  }

  void _replaceEventLikeState(String id, EventLikeState likeState) {
    _events = [
      for (final event in _events)
        if (event.id == id)
          event.copyWith(
            likesCount: likeState.likesCount,
            isLiked: likeState.isLiked,
          )
        else
          event,
    ];
    _publishEvents();
    _notifyListeners();
  }

  Event? _findEvent(List<Event> events, String id) {
    for (final event in events) {
      if (event.id == id) {
        return event;
      }
    }

    return null;
  }

  void _publishEvents() {
    if (!_eventUpdates.isClosed) {
      _eventUpdates.add(List.unmodifiable(_events));
    }
  }

  List<Event> _mergeLocalLikeState(List<Event> incomingEvents) {
    final localLikedStates = {
      for (final event in _events) event.id: event.isLiked,
    };

    return [
      for (final event in incomingEvents)
        if (localLikedStates.containsKey(event.id))
          event.copyWith(isLiked: localLikedStates[event.id])
        else
          event,
    ];
  }

  List<Event> _visibleEvents(List<Event> incomingEvents) {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final eventsFromToday = incomingEvents.where((event) {
      final eventDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );
      return !eventDate.isBefore(today);
    }).toList();

    return _mergeLocalLikeState(eventsFromToday);
  }

  void _notifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_eventsSubscription?.cancel());
    unawaited(_eventUpdates.close());
    super.dispose();
  }
}
