import 'package:eventos_app/core/constants/constants.dart';
import 'package:eventos_app/models/event.dart';
import 'package:eventos_app/presentation/cubits/cadastro_evento/cadastro_evento_cubit.dart';
import 'package:eventos_app/presentation/pages/screens/cadastro_evento_screen.dart';
import 'package:eventos_app/presentation/widgets/event_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../repositories/event_repository.dart';
import '../../../repositories/storage_repository.dart';
import '../../cubits/event_feed/event_feed_cubit.dart';

class EventFeedScreen extends StatelessWidget {
  final bool isAdmin;

  const EventFeedScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EventFeedCubit(EventRepository()),
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<EventFeedCubit, EventFeedState>(
            builder: (context, state) {
              if (state is EventFeedLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is EventFeedError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Erro ao carregar eventos: ${state.message}',
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<EventFeedCubit>().loadEvents();
                        },
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                );
              }
              if (state is EventFeedEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Nenhum evento encontrado.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          context.read<EventFeedCubit>().loadEvents();
                        },
                        child: const Text('Recarregar'),
                      ),
                    ],
                  ),
                );
              }
              if (state is EventFeedLoaded) {
                final eventos = state.events;
                return Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverAppBar(
                            pinned: false,
                            floating: false,
                            snap: false,
                            expandedHeight: 0,
                            centerTitle: false,
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
              return const SizedBox.shrink();
            },
          ),
        ),
        floatingActionButton: isAdmin
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => CadastroEventoCubit(StorageRepository()),
                        child: const CadastroEventoScreen(),
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.add),
              )
            : null,
      ),
    );
  }
}
