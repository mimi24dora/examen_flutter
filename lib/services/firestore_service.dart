import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/medication_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // AJOUTER (Create)
  Future<void> addMedication(String userId, Medication med) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('medications')
        .add(med.toMap());
  }

  // LIRE (Read)
  Stream<List<Medication>> getMedications(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('medications')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Medication.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // MODIFIER (Update)
  Future<void> updateMedication(String userId, Medication med) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('medications')
        .doc(med.id)
        .update(med.toMap());
  }

  // SUPPRIMER (Delete)
  Future<void> deleteMedication(String userId, String medId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('medications')
        .doc(medId)
        .delete();
  }
}