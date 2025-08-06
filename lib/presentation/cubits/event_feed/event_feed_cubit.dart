import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../models/event.dart';
import '../../../repositories/event_repository.dart';

part 'event_feed_state.dart';

/// Cubit responsável por gerenciar o estado do feed de eventos.
///
/// Utiliza um [EventRepository] para buscar, atualizar e gerenciar a lista de eventos.
/// Os estados possíveis são:
/// - [EventFeedLoading]: indica que os eventos estão sendo carregados.
/// - [EventFeedLoaded]: eventos carregados com sucesso.
/// - [EventFeedEmpty]: nenhum evento encontrado.
/// - [EventFeedError]: erro ao carregar eventos.
class EventFeedCubit extends Cubit<EventFeedState> {
  /// Repositório de eventos utilizado para buscar os dados.
  final EventRepository repository;

  /// Construtor do [EventFeedCubit].
  EventFeedCubit(this.repository) : super(EventFeedLoading()) {
    loadEvents();
  }

  /// Carrega os eventos do repositório.
  ///
  /// Emite [EventFeedLoading] durante o carregamento,
  /// [EventFeedLoaded] se houver eventos,
  /// [EventFeedEmpty] se não houver eventos,
  /// ou [EventFeedError] em caso de falha.
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
