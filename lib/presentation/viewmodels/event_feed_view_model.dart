import 'package:flutter/foundation.dart';

import '../../core/errors/error_mapper.dart';
import '../../models/event.dart';
import '../../models/event_like_state.dart';
import '../../repositories/event_repository.dart';

class EventFeedViewModel extends ChangeNotifier {
  EventFeedViewModel(this._eventRepository) {
    loadEvents();
  }

  final EventRepository _eventRepository;

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

  Future<void> loadEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _eventRepository.getEvents();
    } catch (error) {
      _errorMessage = ErrorMapper.fromObject(error).userMessage;
      _events = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteEvent(String id) async {
    try {
      await _eventRepository.deleteEvent(id);
      await loadEvents();
      return true;
    } catch (error) {
      _errorMessage = ErrorMapper.fromObject(error).userMessage;
      notifyListeners();
      return false;
    }
  }

  Future<EventLikeState?> getEventLikeState(String id) async {
    try {
      final likeState = await _eventRepository.getEventLikeState(id);
      _likeErrorMessage = null;
      _replaceEventLikeState(id, likeState);
      return likeState;
    } catch (error) {
      _likeErrorMessage = ErrorMapper.fromObject(error).userMessage;
      return null;
    }
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
    } catch (error) {
      _likeErrorMessage = ErrorMapper.fromObject(error).userMessage;
      return null;
    }
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
    notifyListeners();
  }
}
