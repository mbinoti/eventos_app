import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventos_app/models/event_like_state.dart';
import 'package:eventos_app/models/event.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../core/errors/error_logger.dart';
import '../core/errors/error_mapper.dart';
import '../services/device_identity_service.dart';

class EventRepository {
  EventRepository({
    FirebaseFirestore? firestore,
    DeviceIdentityService? deviceIdentityService,
    AppErrorLogger? errorLogger,
    Future<void> Function(String imageUrl)? deleteStorageImageFromUrl,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _deviceIdentityService =
            deviceIdentityService ?? DeviceIdentityService(),
        _errorLogger = errorLogger ?? const NoopErrorLogger(),
        _deleteStorageImageFromUrl =
            deleteStorageImageFromUrl ?? _deleteFirebaseStorageImageFromUrl;

  final FirebaseFirestore _firestore;
  final DeviceIdentityService _deviceIdentityService;
  final AppErrorLogger _errorLogger;
  final Future<void> Function(String imageUrl) _deleteStorageImageFromUrl;

  static Future<void> _deleteFirebaseStorageImageFromUrl(
    String imageUrl,
  ) async {
    await FirebaseStorage.instance.refFromURL(imageUrl).delete();
  }

  Stream<List<Event>> watchEvents() {
    try {
      return _firestore
          .collection('eventos')
          .orderBy('dataEvento', descending: false)
          .snapshots()
          .map(_eventsFromSnapshot)
          .handleError((Object error, StackTrace stackTrace) {
        throw _mapRepositoryError(error, stackTrace);
      });
    } catch (error, stackTrace) {
      return Stream.error(_mapRepositoryError(error, stackTrace), stackTrace);
    }
  }

  Stream<Event?> watchEvent(String eventId) {
    try {
      return _firestore
          .collection('eventos')
          .doc(eventId)
          .snapshots()
          .map((doc) {
        if (!doc.exists) {
          return null;
        }

        return Event.fromFirestore(doc);
      }).handleError((Object error, StackTrace stackTrace) {
        throw _mapRepositoryError(error, stackTrace);
      });
    } catch (error, stackTrace) {
      return Stream.error(_mapRepositoryError(error, stackTrace), stackTrace);
    }
  }

  Future<List<Event>> getEvents() async {
    try {
      final snapshot = await _firestore
          .collection('eventos')
          .orderBy('dataEvento', descending: false)
          .get();

      return _eventsFromSnapshot(snapshot);
    } on FirebaseException catch (exception, stackTrace) {
      throw ErrorMapper.fromFirebaseException(
        exception,
        fallbackType: AppErrorType.database,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.database,
        stackTrace: stackTrace,
      );
    }
  }

  List<Event> _eventsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final List<Event> events = [];
    for (final doc in snapshot.docs) {
      try {
        events.add(Event.fromFirestore(doc));
      } catch (error, stackTrace) {
        // Mantem o carregamento de lista resiliente, ignorando documentos invalidos.
        // Isso evita derrubar a tela por um unico registro com dados corrompidos.
        _logIgnoredEvent(doc.id, error, stackTrace);
      }
    }

    return events;
  }

  void _logIgnoredEvent(
    String eventId,
    Object error,
    StackTrace stackTrace,
  ) {
    final mapped = ErrorMapper.fromObject(
      error,
      fallbackType: AppErrorType.database,
      stackTrace: stackTrace,
    );
    final technicalDetails = mapped.technicalMessage ?? mapped.toString();
    debugPrint('Evento ignorado ($eventId): $technicalDetails');
    unawaited(
      _errorLogger.log(
        mapped,
        stackTrace: stackTrace,
        feature: 'event_repository',
        operation: 'parse_event_document',
        fallbackType: AppErrorType.database,
        context: {'eventId': eventId},
      ),
    );
  }

  AppException _mapRepositoryError(Object error, StackTrace stackTrace) {
    if (error is FirebaseException) {
      return ErrorMapper.fromFirebaseException(
        error,
        fallbackType: AppErrorType.database,
        stackTrace: stackTrace,
      );
    }

    return ErrorMapper.fromObject(
      error,
      fallbackType: AppErrorType.database,
      stackTrace: stackTrace,
    );
  }

  Future<void> addEvent(Event event) async {
    try {
      await _firestore.collection('eventos').add(event.toMap());
    } on FirebaseException catch (exception, stackTrace) {
      throw ErrorMapper.fromFirebaseException(
        exception,
        fallbackType: AppErrorType.database,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.database,
        stackTrace: stackTrace,
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
    } on FirebaseException catch (exception, stackTrace) {
      throw ErrorMapper.fromFirebaseException(
        exception,
        fallbackType: AppErrorType.database,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.database,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> updateEvent(Event event) async {
    try {
      await _firestore.collection('eventos').doc(event.id).update({
        'titulo': event.name,
        'descricao': event.description,
        'dataEvento': event.date,
        'dataFimEvento': event.endDate,
        'cidade': event.location,
        'imagemUrls': event.imageUrl.isEmpty ? <String>[] : [event.imageUrl],
      });
    } on FirebaseException catch (exception, stackTrace) {
      throw ErrorMapper.fromFirebaseException(
        exception,
        fallbackType: AppErrorType.database,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.database,
        stackTrace: stackTrace,
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
    } on FirebaseException catch (exception, stackTrace) {
      throw ErrorMapper.fromFirebaseException(
        exception,
        fallbackType: AppErrorType.database,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.database,
        stackTrace: stackTrace,
      );
    }
  }

  Stream<EventLikeState> watchEventLikeState(String eventId) async* {
    try {
      final deviceId = await _deviceIdentityService.getOrCreateDeviceId();
      final eventRef = _firestore.collection('eventos').doc(eventId);
      final likeRef = eventRef.collection('curtidas').doc(deviceId);

      yield* eventRef.snapshots().asyncMap((eventDoc) async {
        if (!eventDoc.exists) {
          throw AppException.notFound('Evento nao encontrado.');
        }

        final likeDoc = await likeRef.get();
        return _likeStateFromEventDoc(eventDoc, isLiked: likeDoc.exists);
      }).handleError((Object error, StackTrace stackTrace) {
        throw _mapRepositoryError(error, stackTrace);
      });
    } catch (error, stackTrace) {
      throw _mapRepositoryError(error, stackTrace);
    }
  }

  EventLikeState _likeStateFromEventDoc(
    DocumentSnapshot<Map<String, dynamic>> eventDoc, {
    required bool isLiked,
  }) {
    final data = eventDoc.data();
    final rawLikes = data?['curtidas'];
    final likesCount = rawLikes is num ? rawLikes.toInt() : 0;

    return EventLikeState(
      likesCount: likesCount,
      isLiked: isLiked,
    );
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
    } on FirebaseException catch (exception, stackTrace) {
      throw ErrorMapper.fromFirebaseException(
        exception,
        fallbackType: AppErrorType.database,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.database,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      final eventRef = _firestore.collection('eventos').doc(id);
      final doc = await eventRef.get();
      if (!doc.exists) {
        throw AppException.notFound('Evento nao encontrado para exclusao.');
      }

      final imageUrls = _imageUrlsFromEventData(doc.data());
      await eventRef.delete();
      await _deleteEventImages(id, imageUrls);
    } on FirebaseException catch (exception, stackTrace) {
      throw ErrorMapper.fromFirebaseException(
        exception,
        fallbackType: AppErrorType.database,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.fromObject(
        error,
        fallbackType: AppErrorType.database,
        stackTrace: stackTrace,
      );
    }
  }

  List<String> _imageUrlsFromEventData(Map<String, dynamic>? data) {
    final urls = <String>{};
    final rawImageUrls = data?['imagemUrls'];

    if (rawImageUrls is Iterable) {
      for (final rawUrl in rawImageUrls) {
        final url = rawUrl.toString().trim();
        if (url.isNotEmpty) {
          urls.add(url);
        }
      }
    } else if (rawImageUrls is String) {
      final url = rawImageUrls.trim();
      if (url.isNotEmpty) {
        urls.add(url);
      }
    }

    for (final key in ['imagemUrl', 'imageUrl']) {
      final url = data?[key]?.toString().trim() ?? '';
      if (url.isNotEmpty) {
        urls.add(url);
      }
    }

    return urls.toList(growable: false);
  }

  Future<void> _deleteEventImages(
    String eventId,
    List<String> imageUrls,
  ) async {
    await Future.wait([
      for (final imageUrl in imageUrls) _deleteEventImage(eventId, imageUrl),
    ]);
  }

  Future<void> _deleteEventImage(String eventId, String imageUrl) async {
    try {
      await _deleteStorageImageFromUrl(imageUrl);
    } on FirebaseException catch (exception, stackTrace) {
      if (exception.code == 'object-not-found' ||
          exception.code == 'not-found') {
        return;
      }

      _logImageDeleteFailure(eventId, imageUrl, exception, stackTrace);
    } catch (error, stackTrace) {
      _logImageDeleteFailure(eventId, imageUrl, error, stackTrace);
    }
  }

  void _logImageDeleteFailure(
    String eventId,
    String imageUrl,
    Object error,
    StackTrace stackTrace,
  ) {
    unawaited(
      _errorLogger.log(
        error,
        stackTrace: stackTrace,
        feature: 'event_repository',
        operation: 'delete_event_image',
        fallbackType: AppErrorType.storage,
        context: {
          'eventId': eventId,
          'imageUrl': imageUrl,
        },
      ),
    );
  }
}
