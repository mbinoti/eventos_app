import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventos_app/models/event.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Event>> getEvents() async {
    try {
      final snapshot = await _firestore
          .collection('eventos')
          .orderBy('dataEvento', descending: true)
          .get();

      print('Snapshot retornado, quantidade de docs: ${snapshot.docs.length}');

      final List<Event> events = [];
      final List<String> erros = [];
      for (final doc in snapshot.docs) {
        print('Processando doc: ${doc.id}');
        try {
          events.add(Event.fromFirestore(doc));
        } catch (e) {
          erros.add('Evento ignorado: ${doc.id} - $e');
        }
      }
      if (erros.isNotEmpty) {
        print(erros.join('\n'));
      }
      // Retorna eventos normalmente
      return events;
    } catch (e) {
      print('❌ Erro ao buscar eventos do Firestore: $e');
      return [];
    }
  }

  Future<void> addEvent(Event event) async {
    try {
      await _firestore.collection('events').add(event.toMap());
    } catch (e) {
      print(e);
    }
  }

  Future<void> updateEvent(Event event) async {
    try {
      await _firestore.collection('events').doc(event.id).update(event.toMap());
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await _firestore.collection('events').doc(id).delete();
    } catch (e) {
      print(e);
    }
  }
}
