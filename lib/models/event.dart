import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String name;
  final String description;
  final DateTime date;
  final String location;
  final String imageUrl;
  final int likesCount;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.location,
    required this.imageUrl,
    this.likesCount = 0,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    DateTime? date;
    if (data['dataEvento'] is Timestamp) {
      date = (data['dataEvento'] as Timestamp).toDate();
    } else if (data['dataEvento'] is String) {
      try {
        date = DateTime.parse(data['dataEvento']);
      } catch (_) {
        date = null;
      }
    }
    date ??= DateTime(2000, 1, 1);
    String imageUrl = '';
    if (data['imagemUrls'] is List && (data['imagemUrls'] as List).isNotEmpty) {
      imageUrl = (data['imagemUrls'] as List).first.toString();
    } else if (data['imagemUrls'] is String) {
      imageUrl = data['imagemUrls'];
    }
    final rawLikes = data['curtidas'];
    final likesCount = rawLikes is num ? rawLikes.toInt() : 0;
    final descricao =
        (data['descricao'] ?? data['description'] ?? '').toString();
    return Event(
      id: doc.id,
      name: data['titulo'] ?? '',
      description: descricao,
      date: date,
      location: data['cidade'] ?? '',
      imageUrl: imageUrl,
      likesCount: likesCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': name,
      'descricao': description,
      'dataEvento': date,
      'cidade': location,
      'imagemUrls': imageUrl.isEmpty ? <String>[] : [imageUrl],
      'curtidas': likesCount,
    };
  }

  Event copyWith({
    String? id,
    String? name,
    String? location,
    DateTime? date,
    String? imageUrl,
    int? likesCount,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      likesCount: likesCount ?? this.likesCount,
      description: '',
    );
  }
}
