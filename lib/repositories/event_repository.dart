import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventos_app/models/event.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Event>> getEvents() async {
    try {
      final snapshot = await _firestore
          .collection('eventos')
          .orderBy('dataEvento', descending: false)
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
      await _firestore.collection('eventos').add(event.toMap());
    } catch (e) {
      print(e);
    }
  }

  Future<void> updateEvent(Event event) async {
    try {
      await _firestore
          .collection('eventos')
          .doc(event.id)
          .update(event.toMap());
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      print('Tentando deletar evento com id: $id');
      final doc = await _firestore.collection('eventos').doc(id).get();
      if (!doc.exists) {
        print('Documento não existe!');
        return;
      }
      await _firestore.collection('eventos').doc(id).delete();
      print('Evento deletado!');
    } catch (e) {
      print('Erro ao deletar: $e');
    }
  }
}
