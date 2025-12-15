import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommunity/models/event_model.dart';
import 'package:flutter/foundation.dart';

class CalendarRepository {
  final CollectionReference _eventsCollection = FirebaseFirestore.instance.collection('events');

  Future<void> addEvent(Event event) async {
    try {
      await _eventsCollection.add(event.toMap());
    } catch (e) {
      debugPrint("Erro ao adicionar evento: $e");
      throw Exception('Falha ao criar evento.');
    }
  }

  Stream<List<Event>> getEvents() {
    return _eventsCollection
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    });
  }
}
