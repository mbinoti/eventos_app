import '../../../models/event.dart';

abstract class EventosState {}

class EventosInitial extends EventosState {}

class EventosLoading extends EventosState {}

class EventosLoaded extends EventosState {
  final List<Event> eventos;
  EventosLoaded(this.eventos);
}

class EventosError extends EventosState {
  final String message;
  EventosError(this.message);
}
