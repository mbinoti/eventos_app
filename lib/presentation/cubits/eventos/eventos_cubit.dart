import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/event.dart';
import 'eventos_state.dart';

// lib/presentation/cubits/eventos/eventos_state.dart

import 'package:equatable/equatable.dart';

abstract class EventosState extends Equatable {
  const EventosState();

  @override
  List<Object> get props => [];
}

class EventosInitial extends EventosState {}

class EventosLoading extends EventosState {}

class EventosLoaded extends EventosState {
  final List<Event> eventos; // <- Usar a entidade de domínio

  const EventosLoaded(this.eventos);

  @override
  List<Object> get props => [eventos];
}

class EventosError extends EventosState {
  final String message;

  const EventosError(this.message);

  @override
  List<Object> get props => [message];
}
