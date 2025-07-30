import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  final String id;
  final String name;
  final String description;
  final DateTime date;
  final String location;
  final String imageUrl;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.location,
    required this.imageUrl,
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
    return Event(
      id: doc.id,
      name: data['titulo'] ?? '',
      description: '',
      date: date,
      location: data['cidade'] ?? '',
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'date': date,
      'location': location,
      'imageUrl': imageUrl,
    };
  }
}
