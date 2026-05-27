import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../repositories/event_repository.dart';
import '../../repositories/storage_repository.dart';
import '../viewmodels/cadastro_evento_view_model.dart';
import '../viewmodels/event_feed_view_model.dart';
import '../widgets/event_card.dart';
import 'admin_login_screen.dart';
import 'cadastro_evento_screen.dart';

const String _appTitle = 'app Acontece Aqui';

/// Tela principal do feed de eventos.
///
/// Exibe uma lista de eventos carregados do [EventFeedViewModel].
/// Permite recarregar eventos em caso de erro ou lista vazia.
/// Se [isAdmin] for verdadeiro, exibe o acesso administrativo por login.
class EventFeedScreen extends StatelessWidget {
  final bool isAdmin;

  const EventFeedScreen({super.key, required this.isAdmin});

  Future<void> _openCadastro(
    BuildContext context,
    EventFeedViewModel feedViewModel,
    EventRepository eventRepository,
    StorageRepository storageRepository,
  ) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final page = ChangeNotifierProvider(
      create: (_) => CadastroEventoViewModel(
        storageRepository: storageRepository,
        eventRepository: eventRepository,
      ),
      child: const CadastroEventoScreen(),
    );

    final result = await Navigator.push(
      context,
      isIOS
          ? CupertinoPageRoute(builder: (_) => page)
          : MaterialPageRoute(builder: (_) => page),
    );

    if (result == true) {
      feedViewModel.loadEvents();
    }
  }

  Future<void> _openAdminLoginAndCadastro(
    BuildContext context,
    EventFeedViewModel feedViewModel,
    EventRepository eventRepository,
    StorageRepository storageRepository,
  ) async {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;

    final isAuthenticated = await Navigator.push<bool>(
      context,
      isIOS
          ? CupertinoPageRoute(builder: (_) => const AdminLoginScreen())
          : MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );

    if (isAuthenticated == true && context.mounted) {
      await _openCadastro(
        context,
        feedViewModel,
        eventRepository,
        storageRepository,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    final feedViewModel = context.read<EventFeedViewModel>();
    final eventRepository = context.read<EventRepository>();
    final storageRepository = context.read<StorageRepository>();

    return Consumer<EventFeedViewModel>(
      builder: (context, viewModel, _) {
        final content = _FeedContent(
          viewModel: viewModel,
          isAdmin: isAdmin,
          isIOS: isIOS,
        );

        if (isIOS) {
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text(_appTitle),
              trailing: isAdmin
                  ? CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      onPressed: () => _openAdminLoginAndCadastro(
                        context,
                        feedViewModel,
                        eventRepository,
                        storageRepository,
                      ),
                      child: const Icon(CupertinoIcons.person_circle),
                    )
                  : null,
            ),
            child: SafeArea(child: content),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _appTitle,
              style: const TextStyle(
                fontFamily: 'EduNSWACTHand',
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                fontSize: 20,
              ),
            ),
            actions: isAdmin
                ? [
                    IconButton(
                      tooltip: 'Login administrativo',
                      icon: const Icon(FontAwesomeIcons.user),
                      onPressed: () => _openAdminLoginAndCadastro(
                        context,
                        feedViewModel,
                        eventRepository,
                        storageRepository,
                      ),
                    ),
                  ]
                : null,
          ),
          body: content,
        );
      },
    );
  }
}

class _FeedContent extends StatelessWidget {
  final EventFeedViewModel viewModel;
  final bool isAdmin;
  final bool isIOS;

  const _FeedContent({
    required this.viewModel,
    required this.isAdmin,
    required this.isIOS,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return Center(
        child: isIOS
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator(),
      );
    }

    if (viewModel.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Erro ao carregar eventos: ${viewModel.errorMessage ?? 'Erro desconhecido'}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            isIOS
                ? CupertinoButton.filled(
                    onPressed: viewModel.loadEvents,
                    child: const Text('Tentar novamente'),
                  )
                : ElevatedButton(
                    onPressed: viewModel.loadEvents,
                    child: const Text('Tentar novamente'),
                  ),
          ],
        ),
      );
    }

    if (viewModel.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Nenhum evento encontrado.'),
            const SizedBox(height: 16),
            isIOS
                ? CupertinoButton.filled(
                    onPressed: viewModel.loadEvents,
                    child: const Text('Recarregar'),
                  )
                : ElevatedButton(
                    onPressed: viewModel.loadEvents,
                    child: const Text('Recarregar'),
                  ),
          ],
        ),
      );
    }

    final eventos = viewModel.events;
    return ListView.builder(
      itemCount: eventos.length,
      itemBuilder: (context, index) => EventCard(
        evento: eventos[index],
        isAdmin: isAdmin,
        onDelete: () => viewModel.deleteEvent(eventos[index].id),
      ),
    );
  }
}
