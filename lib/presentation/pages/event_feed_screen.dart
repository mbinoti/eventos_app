import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/event.dart';
import '../../models/event_like_state.dart';
import '../../repositories/event_repository.dart';
import '../../repositories/storage_repository.dart';
import '../../services/platform_info.dart';
import '../viewmodels/cadastro_evento_view_model.dart';
import '../viewmodels/event_feed_view_model.dart';
import '../widgets/event_card.dart';
import 'admin_login_screen.dart';
import 'cadastro_evento_screen.dart';

const String _appTitle = 'Acontece Aqui';

/// Tela principal do feed de eventos.
///
/// Exibe uma lista de eventos carregados do [EventFeedViewModel].
/// Permite recarregar eventos em caso de erro ou lista vazia.
/// Se [isAdmin] for verdadeiro, inicia com acesso administrativo liberado.
class EventFeedScreen extends StatefulWidget {
  final bool isAdmin;

  const EventFeedScreen({super.key, required this.isAdmin});

  @override
  State<EventFeedScreen> createState() => _EventFeedScreenState();
}

class _EventFeedScreenState extends State<EventFeedScreen> {
  late bool _hasAdminAccess;

  @override
  void initState() {
    super.initState();
    _hasAdminAccess = widget.isAdmin;
  }

  @override
  void didUpdateWidget(covariant EventFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAdmin != widget.isAdmin && widget.isAdmin) {
      _hasAdminAccess = true;
    }
  }

  Future<void> _showMessage(BuildContext context, String message) async {
    if (isCupertinoPlatform) {
      await showCupertinoDialog<void>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCadastro(
    BuildContext context,
    EventFeedViewModel feedViewModel,
    EventRepository eventRepository,
    StorageRepository storageRepository,
  ) async {
    final isIOS = isCupertinoPlatform;
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

  Future<bool> _authenticateIfNeeded(BuildContext context) async {
    if (_hasAdminAccess) {
      return true;
    }

    final isIOS = isCupertinoPlatform;

    final isAuthenticated = await Navigator.push<bool>(
      context,
      isIOS
          ? CupertinoPageRoute(builder: (_) => const AdminLoginScreen())
          : MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
    );

    if (isAuthenticated == true && mounted) {
      setState(() => _hasAdminAccess = true);
      return true;
    }

    return false;
  }

  Future<void> _openAdminAccess(
    BuildContext context,
    EventFeedViewModel feedViewModel,
    EventRepository eventRepository,
    StorageRepository storageRepository,
  ) async {
    final canManageEvents = await _authenticateIfNeeded(context);
    if (canManageEvents && context.mounted) {
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
    final isIOS = isCupertinoPlatform;
    final feedViewModel = context.read<EventFeedViewModel>();
    final eventRepository = context.read<EventRepository>();
    final storageRepository = context.read<StorageRepository>();

    return Consumer<EventFeedViewModel>(
      builder: (context, viewModel, _) {
        Future<bool> handleDelete(String eventId) async {
          final success = await viewModel.deleteEvent(eventId);
          if (!success && context.mounted) {
            final message = viewModel.errorMessage ??
                'Não foi possível excluir o evento. Tente novamente.';
            await _showMessage(context, message);
          }

          return success;
        }

        final content = _FeedContent(
          viewModel: viewModel,
          isAdmin: _hasAdminAccess,
          isIOS: isIOS,
          onDeleteEvent: handleDelete,
          onLoadLikeState: viewModel.getEventLikeState,
          onLikeEvent: viewModel.setEventLiked,
        );

        if (isIOS) {
          return CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: Text(_appTitle),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _openAdminAccess(
                  context,
                  feedViewModel,
                  eventRepository,
                  storageRepository,
                ),
                child: Text(_hasAdminAccess ? 'Novo' : 'Login'),
              ),
            ),
            child: SafeArea(child: content),
          );
        }

        return Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: Text(
              _appTitle,
              style: const TextStyle(
                fontFamily: 'EduNSWACTHand',
                fontWeight: FontWeight.w600,
                fontSize: 22,
              ),
            ),
            actions: [
              Tooltip(
                message: _hasAdminAccess
                    ? 'Cadastrar evento'
                    : 'Entrar para cadastrar eventos',
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).appBarTheme.foregroundColor,
                  ),
                  onPressed: () => _openAdminAccess(
                    context,
                    feedViewModel,
                    eventRepository,
                    storageRepository,
                  ),
                  icon: Icon(
                    _hasAdminAccess ? Icons.add : Icons.login,
                  ),
                  label: Text(_hasAdminAccess ? 'Novo' : 'Login'),
                ),
              ),
            ],
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
  final Future<bool> Function(String eventId) onDeleteEvent;
  final Future<EventLikeState?> Function(String eventId) onLoadLikeState;
  final Future<EventLikeState?> Function(String eventId, bool isLiked)
      onLikeEvent;

  const _FeedContent({
    required this.viewModel,
    required this.isAdmin,
    required this.isIOS,
    required this.onDeleteEvent,
    required this.onLoadLikeState,
    required this.onLikeEvent,
  });

  @override
  Widget build(BuildContext context) {
    if (viewModel.isLoading) {
      return _LoadingFeedState(
        isIOS: isIOS,
      );
    }

    if (viewModel.hasError) {
      return _RefreshableFeedState(
        isIOS: isIOS,
        title: 'Não foi possível carregar a agenda',
        message: viewModel.errorMessage ?? 'Tente novamente em instantes.',
        actionLabel: 'Tentar novamente',
        onRefresh: viewModel.loadEvents,
      );
    }

    if (viewModel.isEmpty) {
      return _RefreshableFeedState(
        isIOS: isIOS,
        title: 'Nenhum evento publicado ainda',
        message:
            'Quando novos eventos forem adicionados, eles aparecerão aqui.',
        actionLabel: 'Atualizar agenda',
        onRefresh: viewModel.loadEvents,
      );
    }

    return EventFeedList(
      events: viewModel.events,
      isAdmin: isAdmin,
      isIOS: isIOS,
      onRefresh: viewModel.loadEvents,
      onDeleteEvent: onDeleteEvent,
      onLoadLikeState: onLoadLikeState,
      onLikeEvent: onLikeEvent,
    );
  }
}

class EventFeedList extends StatelessWidget {
  const EventFeedList({
    super.key,
    required this.events,
    required this.isAdmin,
    required this.isIOS,
    required this.onRefresh,
    required this.onDeleteEvent,
    required this.onLoadLikeState,
    required this.onLikeEvent,
  });

  final List<Event> events;
  final bool isAdmin;
  final bool isIOS;
  final Future<void> Function() onRefresh;
  final Future<bool> Function(String eventId) onDeleteEvent;
  final Future<EventLikeState?> Function(String eventId) onLoadLikeState;
  final Future<EventLikeState?> Function(String eventId, bool isLiked)
      onLikeEvent;

  @override
  Widget build(BuildContext context) {
    void openEventDetail(Event event) {
      final page = EventDetailPage(
        evento: event,
        isAdmin: isAdmin,
        onDelete: () => onDeleteEvent(event.id),
        onLoadLikeState: () => onLoadLikeState(event.id),
        onLikeChanged: (isLiked) => onLikeEvent(event.id, isLiked),
        likeErrorMessage: () =>
            context.read<EventFeedViewModel>().likeErrorMessage,
      );

      Navigator.push(
        context,
        isIOS
            ? CupertinoPageRoute(builder: (_) => page)
            : MaterialPageRoute(builder: (_) => page),
      );
    }

    final scrollView = CustomScrollView(
      physics: isIOS
          ? const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            )
          : const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (isIOS)
          CupertinoSliverRefreshControl(
            onRefresh: onRefresh,
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          sliver: SliverToBoxAdapter(
            child: _FeedHeader(
              eventCount: events.length,
              isIOS: isIOS,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final event = events[index];
                return EventCard(
                  evento: event,
                  isAdmin: isAdmin,
                  onTap: () => openEventDetail(event),
                );
              },
              childCount: events.length,
            ),
          ),
        ),
      ],
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: isIOS
            ? scrollView
            : RefreshIndicator(
                onRefresh: onRefresh,
                child: scrollView,
              ),
      ),
    );
  }
}

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({
    required this.eventCount,
    required this.isIOS,
  });

  final int eventCount;
  final bool isIOS;

  @override
  Widget build(BuildContext context) {
    final styles = _FeedTextStyles.resolve(context, isIOS: isIOS);
    final countLabel = eventCount == 1
        ? '1 evento publicado, em ordem de data.'
        : '$eventCount eventos publicados, em ordem de data.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AGENDA LOCAL', style: styles.eyebrow),
        const SizedBox(height: 8),
        Text('Eventos para descobrir', style: styles.heading),
        const SizedBox(height: 8),
        Text(countLabel, style: styles.body),
      ],
    );
  }
}

class _LoadingFeedState extends StatelessWidget {
  const _LoadingFeedState({
    required this.isIOS,
  });

  final bool isIOS;

  @override
  Widget build(BuildContext context) {
    final styles = _FeedTextStyles.resolve(context, isIOS: isIOS);

    return Semantics(
      liveRegion: true,
      label: 'Carregando agenda de eventos',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isIOS
                ? const CupertinoActivityIndicator()
                : const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Carregando agenda...', style: styles.body),
          ],
        ),
      ),
    );
  }
}

class _RefreshableFeedState extends StatelessWidget {
  const _RefreshableFeedState({
    required this.isIOS,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onRefresh,
  });

  final bool isIOS;
  final String title;
  final String message;
  final String actionLabel;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final styles = _FeedTextStyles.resolve(context, isIOS: isIOS);
    final stateContent = Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: styles.stateTitle),
              const SizedBox(height: 10),
              Text(message, style: styles.body),
              const SizedBox(height: 20),
              isIOS
                  ? CupertinoButton.filled(
                      onPressed: onRefresh,
                      child: Text(actionLabel),
                    )
                  : FilledButton(
                      onPressed: onRefresh,
                      child: Text(actionLabel),
                    ),
            ],
          ),
        ),
      ),
    );

    final scrollView = CustomScrollView(
      physics: isIOS
          ? const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            )
          : const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (isIOS) CupertinoSliverRefreshControl(onRefresh: onRefresh),
        SliverFillRemaining(
          hasScrollBody: false,
          child: stateContent,
        ),
      ],
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: isIOS
            ? scrollView
            : RefreshIndicator(
                onRefresh: onRefresh,
                child: scrollView,
              ),
      ),
    );
  }
}

class _FeedTextStyles {
  const _FeedTextStyles({
    required this.eyebrow,
    required this.heading,
    required this.body,
    required this.stateTitle,
  });

  final TextStyle eyebrow;
  final TextStyle heading;
  final TextStyle body;
  final TextStyle stateTitle;

  factory _FeedTextStyles.resolve(
    BuildContext context, {
    required bool isIOS,
  }) {
    if (isIOS) {
      final textTheme = CupertinoTheme.of(context).textTheme;
      final labelColor = CupertinoColors.label.resolveFrom(context);
      final secondaryLabelColor =
          CupertinoColors.secondaryLabel.resolveFrom(context);
      final accentColor = CupertinoColors.activeBlue.resolveFrom(context);

      return _FeedTextStyles(
        eyebrow: textTheme.textStyle.copyWith(
          color: accentColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
        heading: textTheme.navLargeTitleTextStyle.copyWith(
          color: labelColor,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          height: 1.15,
        ),
        body: textTheme.textStyle.copyWith(
          color: secondaryLabelColor,
          fontSize: 16,
          height: 1.4,
        ),
        stateTitle: textTheme.navTitleTextStyle.copyWith(
          color: labelColor,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      );
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return _FeedTextStyles(
      eyebrow: textTheme.labelMedium!.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
      heading: textTheme.headlineMedium!.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
      body: textTheme.bodyLarge!.copyWith(
        color: colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
      stateTitle: textTheme.titleLarge!.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }
}
