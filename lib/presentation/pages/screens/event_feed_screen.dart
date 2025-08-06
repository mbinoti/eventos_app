import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/constants/constants.dart';

import '../../../presentation/cubits/cadastro_evento/cadastro_evento_cubit.dart';
import '../../../presentation/cubits/event_feed/event_feed_cubit.dart';
import '../../../presentation/pages/screens/cadastro_evento_screen.dart';
import '../../../presentation/widgets/event_card.dart';
import '../../../repositories/event_repository.dart';
import '../../../repositories/storage_repository.dart';

/// Tela principal do feed de eventos.
///
/// Exibe uma lista de eventos carregados do [EventFeedCubit].
/// Permite recarregar eventos em caso de erro ou lista vazia.
/// Se [isAdmin] for verdadeiro, exibe um botão para adicionar novos eventos.
///
/// Parâmetros:
/// - [isAdmin]: Indica se o usuário tem permissões administrativas para criar eventos.
class EventFeedScreen extends StatelessWidget {
  /// Indica se o usuário é administrador.
  final bool isAdmin;

  /// Construtor do [EventFeedScreen].
  const EventFeedScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final feedCubit = context.read<EventFeedCubit>(); // Usa o Cubit do MainApp

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<EventFeedCubit, EventFeedState>(
          builder: (context, state) {
            // Estado de carregamento dos eventos
            if (state is EventFeedLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            // Estado de erro ao carregar eventos
            if (state is EventFeedError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Erro ao carregar eventos: ${state.message}',
                        style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: feedCubit.loadEvents,
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              );
            }
            // Estado de lista vazia
            if (state is EventFeedEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Nenhum evento encontrado.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: feedCubit.loadEvents,
                      child: const Text('Recarregar'),
                    ),
                  ],
                ),
              );
            }
            // Estado de eventos carregados com sucesso
            if (state is EventFeedLoaded) {
              final eventos = state.events;
              return Column(
                children: [
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          backgroundColor: Colors.black,
                          title: Text(
                            appTitle,
                            style: const TextStyle(
                              fontFamily: 'EduNSWACTHand',
                              fontWeight: FontWeight.w400,
                              fontStyle: FontStyle.italic,
                              fontSize: 20,
                            ),
                          ),
                          actions: [
                            IconButton(
                              icon: const Icon(FontAwesomeIcons.user),
                              onPressed: () {
                                // Ação do botão de perfil
                                print('Perfil clicado');
                              },
                            ),
                          ],
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => EventCard(
                              evento: eventos[index],
                              isAdmin: isAdmin,
                              repository: EventRepository(),
                            ),
                            childCount: eventos.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            // Estado padrão (vazio)
            return const SizedBox.shrink();
          },
        ),
      ),
      // Botão flutuante para adicionar eventos (apenas para admin)
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => CadastroEventoCubit(StorageRepository()),
                      child: CadastroEventoScreen(),
                    ),
                  ),
                );
                if (result == true) {
                  feedCubit.loadEvents();
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
