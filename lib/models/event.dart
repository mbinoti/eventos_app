import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String name;
  final String description;
  final DateTime date;
  final DateTime? endDate;
  final String location;
  final String imageUrl;
  final int likesCount;
  final bool isLiked;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    this.endDate,
    required this.location,
    required this.imageUrl,
    this.likesCount = 0,
    this.isLiked = false,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event.fromMap(doc.id, data);
  }

  factory Event.fromMap(String id, Map<String, dynamic> data) {
    DateTime? date = _parseDate(data['dataEvento']);
    date ??= DateTime(2000, 1, 1);

    final endDate = _parseDate(
      data['dataFimEvento'] ?? data['fimEvento'] ?? data['endDate'],
    );

    String imageUrl = '';
    if (data['imagemUrls'] is List && (data['imagemUrls'] as List).isNotEmpty) {
      imageUrl = (data['imagemUrls'] as List).first.toString();
    } else if (data['imagemUrls'] is String) {
      imageUrl = data['imagemUrls'];
    }
    final rawLikes = data['curtidas'];
    final likesCount = rawLikes is num ? rawLikes.toInt() : 0;
    final rawIsLiked = data['curtido'];
    final descricao =
        (data['descricao'] ?? data['description'] ?? '').toString();
    return Event(
      id: id,
      name: data['titulo'] ?? '',
      description: descricao,
      date: date,
      endDate: endDate != null && endDate.isAfter(date) ? endDate : null,
      location: data['cidade'] ?? '',
      imageUrl: imageUrl,
      likesCount: likesCount,
      isLiked: rawIsLiked == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'titulo': name,
      'descricao': description,
      'dataEvento': date,
      'dataFimEvento': endDate,
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
    DateTime? endDate,
    String? imageUrl,
    int? likesCount,
    bool? isLiked,
    String? description,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      imageUrl: imageUrl ?? this.imageUrl,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
      description: description ?? this.description,
    );
  }

  static DateTime? _parseDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }

    return null;
  }
}
