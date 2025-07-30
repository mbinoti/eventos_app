part of 'event_feed_cubit.dart';

abstract class EventFeedState extends Equatable {
  @override
  List<Object?> get props => [];
}

class EventFeedLoading extends EventFeedState {}

class EventFeedLoaded extends EventFeedState {
  final List<Event> events;
  EventFeedLoaded(this.events);

  @override
  List<Object?> get props => [events];
}

class EventFeedEmpty extends EventFeedState {}

class EventFeedError extends EventFeedState {
  final String message;
  EventFeedError(this.message);

  @override
  List<Object?> get props => [message];
}
