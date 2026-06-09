import 'package:eventos_app/app_theme.dart';
import 'package:eventos_app/models/event.dart';
import 'package:eventos_app/models/event_like_state.dart';
import 'package:eventos_app/presentation/widgets/event_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final event = Event(
    id: 'festival-inverno-sao-joao-del-rei-2026',
    name: 'Festival de Inverno de São João del-Rei',
    description:
        'Música, teatro e oficinas ocupam o centro histórico durante todo o fim de semana.',
    date: DateTime(2026, 7, 18),
    location: 'São João del-Rei, MG',
    imageUrl: '',
    likesCount: 12,
  );

  testWidgets('exibe resumo compacto na lista de eventos', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: EventCard(
              evento: event,
              isAdmin: false,
            ),
          ),
        ),
      ),
    );

    expect(
      find.text('Festival de Inverno de São João del-Rei'),
      findsOneWidget,
    );
    expect(find.text('São João del-Rei, MG'), findsOneWidget);
    expect(find.text('18 de julho de 2026'), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    expect(find.text(event.description), findsNothing);
    expect(find.text('JUL'), findsNothing);
    expect(find.text('Imagem indisponível'), findsNothing);
    expect(find.text('Imagem do evento indisponível'), findsNothing);
    expect(find.byIcon(Icons.favorite_rounded), findsNothing);
    expect(find.byIcon(Icons.share_outlined), findsNothing);
  });

  testWidgets('exibe intervalo quando evento da lista tem data de fim',
      (tester) async {
    final rangedEvent = Event(
      id: 'festival-com-intervalo',
      name: event.name,
      description: event.description,
      date: DateTime(2026, 7, 18),
      endDate: DateTime(2026, 7, 20),
      location: event.location,
      imageUrl: event.imageUrl,
      likesCount: event.likesCount,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: EventCard(
              evento: rangedEvent,
              isAdmin: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('18 a 20 de julho de 2026'), findsOneWidget);
    expect(find.text('18 de julho de 2026'), findsNothing);
  });

  testWidgets('abre callback ao tocar no item da lista', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: EventCard(
              evento: event,
              isAdmin: false,
              onTap: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Festival de Inverno de São João del-Rei'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('detalhe concentra imagem grande descricao e acoes',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: EventDetailPage(
          evento: event,
          isAdmin: true,
          onDelete: () async => true,
        ),
      ),
    );

    expect(find.text('Imagem do evento indisponível'), findsOneWidget);
    expect(find.text('9+'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(find.byType(FaIcon), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Sobre o evento'),
      320,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('Sobre o evento'), findsOneWidget);
    expect(find.text(event.description), findsOneWidget);
  });

  testWidgets('carrega curtida persistida ao abrir detalhe', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: EventDetailPage(
          evento: event.copyWith(likesCount: 0, isLiked: false),
          onLoadLikeState: () async => const EventLikeState(
            likesCount: 5,
            isLiked: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('mostra contador somente depois da primeira curtida no detalhe',
      (tester) async {
    final eventWithoutLikes = Event(
      id: 'festival-sem-curtidas',
      name: event.name,
      description: event.description,
      date: event.date,
      location: event.location,
      imageUrl: event.imageUrl,
      likesCount: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: EventDetailPage(evento: eventWithoutLikes),
      ),
    );

    await tester.ensureVisible(find.byIcon(Icons.favorite_border_rounded));
    await tester.pumpAndSettle();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('salva curtida e usa retorno persistido no detalhe',
      (tester) async {
    bool? requestedLikeState;

    final eventWithoutLikes = Event(
      id: 'festival-sem-curtidas',
      name: event.name,
      description: event.description,
      date: event.date,
      location: event.location,
      imageUrl: event.imageUrl,
      likesCount: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: EventDetailPage(
          evento: eventWithoutLikes,
          onLikeChanged: (isLiked) async {
            requestedLikeState = isLiked;
            return EventLikeState(
                likesCount: isLiked ? 8 : 7, isLiked: isLiked);
          },
        ),
      ),
    );

    await tester.ensureVisible(find.byIcon(Icons.favorite_border_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pumpAndSettle();

    expect(requestedLikeState, isTrue);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets('mantem compartilhar parado quando a curtida muda no detalhe',
      (tester) async {
    final eventWithoutLikes = Event(
      id: 'festival-sem-curtidas',
      name: event.name,
      description: event.description,
      date: event.date,
      location: event.location,
      imageUrl: event.imageUrl,
      likesCount: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: EventDetailPage(evento: eventWithoutLikes),
      ),
    );

    await tester.ensureVisible(find.byIcon(Icons.favorite_border_rounded));
    await tester.pumpAndSettle();

    final shareBefore = tester.getTopLeft(find.byType(FaIcon)).dx;
    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pumpAndSettle();

    final shareAfter = tester.getTopLeft(find.byType(FaIcon)).dx;

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(shareAfter, shareBefore);
  });

  testWidgets(
      'mantem as acoes do detalhe utilizaveis em largura estreita e texto ampliado',
      (tester) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.5),
            ),
            child: child!,
          );
        },
        home: EventDetailPage(
          evento: event,
          isAdmin: true,
          onDelete: () async => true,
        ),
      ),
    );

    expect(find.text('Compartilhar'), findsNothing);
    expect(find.text('Excluir'), findsNothing);
    expect(find.text('9+'), findsOneWidget);
    expect(find.byType(FaIcon), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline), findsOneWidget);
  });

  testWidgets('usa controles Cupertino no iOS', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: CupertinoPageScaffold(
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: EventCard(
                  evento: event,
                  isAdmin: false,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CupertinoButton), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.heart_fill), findsNothing);
      expect(find.byIcon(CupertinoIcons.share), findsNothing);
      expect(find.byIcon(CupertinoIcons.photo), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.chevron_forward), findsOneWidget);
      expect(find.text('Imagem indisponível'), findsNothing);

      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: EventDetailPage(evento: event),
        ),
      );

      expect(find.byType(CupertinoButton), findsNWidgets(2));
      expect(find.byIcon(CupertinoIcons.heart), findsOneWidget);
      expect(find.byType(FaIcon), findsOneWidget);
      expect(find.text('9+'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
