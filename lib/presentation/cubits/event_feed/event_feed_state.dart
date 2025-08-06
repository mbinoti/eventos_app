part of 'event_feed_cubit.dart';

/// Classe base abstrata para os estados do [EventFeedCubit].
///
/// Define os possíveis estados do feed de eventos.
abstract class EventFeedState extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Estado que indica que os eventos estão sendo carregados.
class EventFeedLoading extends EventFeedState {}

/// Estado que indica que os eventos foram carregados com sucesso.
///
/// [events] Lista de eventos carregados.
class EventFeedLoaded extends EventFeedState {
  /// Lista de eventos carregados.
  final List<Event> events;

  /// Construtor do [EventFeedLoaded].
  EventFeedLoaded(this.events);

  @override
  List<Object?> get props => [events];
}

/// Estado que indica que não há eventos disponíveis.
class EventFeedEmpty extends EventFeedState {}

/// Estado que indica que ocorreu um erro ao carregar os eventos.
///
/// [message] Mensagem de erro.
class EventFeedError extends EventFeedState {
  /// Mensagem de erro.
  final String message;

  /// Construtor do [EventFeedError].
  EventFeedError(this.message);

  @override
  List<Object?> get props => [message];
}
