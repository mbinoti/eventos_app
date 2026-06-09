import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventos_app/models/event_like_state.dart';
import 'package:eventos_app/models/event.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/error_mapper.dart';
import '../services/device_identity_service.dart';

class EventRepository {
  EventRepository({
    FirebaseFirestore? firestore,
    DeviceIdentityService? deviceIdentityService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _deviceIdentityService =
            deviceIdentityService ?? DeviceIdentityService();

  final FirebaseFirestore _firestore;
  final DeviceIdentityService _deviceIdentityService;

  Future<List<Event>> getEvents() async {
    try {
      final snapshot = await _firestore
          .collection('eventos')
          .orderBy('dataEvento', descending: false)
          .get();

      final List<Event> events = [];
      for (final doc in snapshot.docs) {
        try {
          events.add(Event.fromFirestore(doc));
        } catch (error, stackTrace) {
          // Mantem o carregamento de lista resiliente, ignorando documentos invalidos.
          // Isso evita derrubar a tela por um unico registro com dados corrompidos.
          final mapped = ErrorMapper.fromObject(
            error,
            fallbackType: AppErrorType.database,
          );
          final technicalDetails = mapped.technicalMessage ?? mapped.toString();
          print('Evento ignorado (${doc.id}): $technicalDetails\n$stackTrace');
        }
      }

      return events;
    } on FirebaseException catch (exception) {
      throw ErrorMapper.fromFirebaseException(
        exception,
        fallbackType: AppErrorType.database,
      );
    } catch (error) {
      throw ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.database,
      );
    }
  }

  Future<void> addEvent(Event event) async {
    try {
      await _firestore.collection('eventos').add(event.toMap());
    } on FirebaseException catch (exception) {
      throw ErrorMapper.fromFirebaseException(
        exception,
        fallbackType: AppErrorType.database,
      );
    } catch (error) {
      throw ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.database,
      );
    }
  }

  Future<void> createEvent({
    required String titulo,
    required String cidade,
    required DateTime dataEvento,
    DateTime? dataFimEvento,
    required List<String> imagemUrls,
    String? descricao,
  }) async {
    try {
      await _firestore.collection('eventos').add({
        'titulo': titulo,
        'cidade': cidade,
        'imagemUrls': imagemUrls,
        'descricao': descricao ?? '',
        'dataEvento': dataEvento,
        'dataFimEvento': dataFimEvento,
        'criadoEm': DateTime.now(),
        'curtidas': 0,
      });
    } on FirebaseException catch (exception) {
      throw ErrorMapper.fromFirebaseException(
        exception,
        fallbackType: AppErrorType.database,
      );
    } catch (error) {
      throw ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.database,
      );
    }
  }

  Future<void> updateEvent(Event event) async {
    try {
      await _firestore
          .collection('eventos')
          .doc(event.id)
          .update(event.toMap());
    } on FirebaseException catch (exception) {
      throw ErrorMapper.fromFirebaseException(
        exception,
        fallbackType: AppErrorType.database,
      );
    } catch (error) {
      throw ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.database,
      );
    }
  }

  Future<EventLikeState> getEventLikeState(String eventId) async {
    try {
      final deviceId = await _deviceIdentityService.getOrCreateDeviceId();
      final eventRef = _firestore.collection('eventos').doc(eventId);
      final eventDoc = await eventRef.get();
      if (!eventDoc.exists) {
        throw AppException.notFound('Evento nao encontrado.');
      }

      final likeDoc = await eventRef.collection('curtidas').doc(deviceId).get();
      final data = eventDoc.data();
      final rawLikes = data?['curtidas'];
      final likesCount = rawLikes is num ? rawLikes.toInt() : 0;

      return EventLikeState(
        likesCount: likesCount,
        isLiked: likeDoc.exists,
      );
    } on FirebaseException catch (exception) {
      throw ErrorMapper.fromFirebaseException(
        exception,
        fallbackType: AppErrorType.database,
      );
    } catch (error) {
      throw ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.database,
      );
    }
  }

  Future<EventLikeState> setEventLiked({
    required String eventId,
    required bool isLiked,
  }) async {
    try {
      final deviceId = await _deviceIdentityService.getOrCreateDeviceId();
      final eventRef = _firestore.collection('eventos').doc(eventId);
      final likeRef = eventRef.collection('curtidas').doc(deviceId);

      return _firestore.runTransaction<EventLikeState>((transaction) async {
        final eventDoc = await transaction.get(eventRef);
        if (!eventDoc.exists) {
          throw AppException.notFound('Evento nao encontrado.');
        }

        final likeDoc = await transaction.get(likeRef);
        final eventData = eventDoc.data();
        final rawLikes = eventData?['curtidas'];
        final currentLikes = rawLikes is num ? rawLikes.toInt() : 0;
        final alreadyLiked = likeDoc.exists;

        if (isLiked == alreadyLiked) {
          return EventLikeState(
            likesCount: currentLikes,
            isLiked: alreadyLiked,
          );
        }

        final updatedLikes = isLiked
            ? currentLikes + 1
            : (currentLikes > 0 ? currentLikes - 1 : 0);

        transaction.update(eventRef, {'curtidas': updatedLikes});
        if (isLiked) {
          transaction.set(likeRef, {
            'deviceId': deviceId,
            'criadoEm': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.delete(likeRef);
        }

        return EventLikeState(
          likesCount: updatedLikes,
          isLiked: isLiked,
        );
      });
    } on FirebaseException catch (exception) {
      throw ErrorMapper.fromFirebaseException(
        exception,
        fallbackType: AppErrorType.database,
      );
    } catch (error) {
      throw ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.database,
      );
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      final doc = await _firestore.collection('eventos').doc(id).get();
      if (!doc.exists) {
        throw AppException.notFound('Evento nao encontrado para exclusao.');
      }

      await _firestore.collection('eventos').doc(id).delete();
    } on FirebaseException catch (exception) {
      throw ErrorMapper.fromFirebaseException(
        exception,
        fallbackType: AppErrorType.database,
      );
    } catch (error) {
      throw ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.database,
      );
    }
  }
}
