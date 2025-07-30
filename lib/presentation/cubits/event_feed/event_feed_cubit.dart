import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/event.dart';
import '../../../repositories/event_repository.dart';

part 'event_feed_state.dart';

class EventFeedCubit extends Cubit<EventFeedState> {
  final EventRepository repository;

  EventFeedCubit(this.repository) : super(EventFeedLoading()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    emit(EventFeedLoading());
    try {
      final events = await repository.getEvents();
      if (events.isEmpty) {
        emit(EventFeedEmpty());
      } else {
        emit(EventFeedLoaded(events));
      }
    } catch (e) {
      emit(EventFeedError(e.toString()));
    }
  }
}
