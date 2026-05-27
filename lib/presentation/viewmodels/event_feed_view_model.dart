import 'package:flutter/foundation.dart';

import '../../models/event.dart';
import '../../repositories/event_repository.dart';

class EventFeedViewModel extends ChangeNotifier {
  EventFeedViewModel(this._eventRepository) {
    loadEvents();
  }

  final EventRepository _eventRepository;

  bool _isLoading = true;
  List<Event> _events = [];
  String? _errorMessage;

  bool get isLoading => _isLoading;
  List<Event> get events => List.unmodifiable(_events);
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isEmpty => !_isLoading && !hasError && _events.isEmpty;

  Future<void> loadEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _events = await _eventRepository.getEvents();
    } catch (e) {
      _errorMessage = e.toString();
      _events = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteEvent(String id) async {
    await _eventRepository.deleteEvent(id);
    await loadEvents();
  }
}
