import 'package:eventos_app/models/event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Event', () {
    test('cria evento com data de inicio e fim a partir do mapa', () {
      final event = Event.fromMap('evento-1', {
        'titulo': 'Festival de Inverno',
        'descricao': 'Programacao de fim de semana',
        'dataEvento': '2026-07-18',
        'dataFimEvento': '2026-07-20',
        'cidade': 'Sao Joao del-Rei, MG',
        'imagemUrls': ['https://fake.storage/festival.jpg'],
        'curtidas': 12,
        'curtido': true,
      });

      expect(event.id, 'evento-1');
      expect(event.name, 'Festival de Inverno');
      expect(event.date, DateTime(2026, 7, 18));
      expect(event.endDate, DateTime(2026, 7, 20));
      expect(event.location, 'Sao Joao del-Rei, MG');
      expect(event.imageUrl, 'https://fake.storage/festival.jpg');
      expect(event.likesCount, 12);
      expect(event.isLiked, isTrue);
    });

    test('serializa data de fim opcional', () {
      final event = Event(
        id: 'evento-2',
        name: 'Mostra Cultural',
        description: '',
        date: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 3),
        location: 'Ouro Preto, MG',
        imageUrl: '',
      );

      final map = event.toMap();

      expect(map['dataEvento'], DateTime(2026, 8, 1));
      expect(map['dataFimEvento'], DateTime(2026, 8, 3));
    });

    test('ignora data de fim anterior ao inicio', () {
      final event = Event.fromMap('evento-3', {
        'titulo': 'Evento com data invalida',
        'dataEvento': DateTime(2026, 9, 10),
        'dataFimEvento': DateTime(2026, 9, 9),
      });

      expect(event.date, DateTime(2026, 9, 10));
      expect(event.endDate, isNull);
    });
  });
}
