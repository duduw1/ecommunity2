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

  Future<void> deleteEvent(String eventId) async {
    try {
      await _eventsCollection.doc(eventId).delete();
    } catch (e) {
      debugPrint("Erro ao excluir evento: $e");
      throw Exception('Falha ao excluir evento.');
    }
  }

  Future<void> toggleAttendance(String eventId, String userId) async {
    try {
      final docRef = _eventsCollection.doc(eventId);
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) return;

      final data = docSnapshot.data() as Map<String, dynamic>;
      final List<String> attendees = List<String>.from(data['attendees'] ?? []);

      if (attendees.contains(userId)) {
        await docRef.update({
          'attendees': FieldValue.arrayRemove([userId])
        });
      } else {
        await docRef.update({
          'attendees': FieldValue.arrayUnion([userId])
        });
      }
    } catch (e) {
      debugPrint("Erro ao atualizar presença: $e");
    }
  }
}
