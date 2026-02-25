import 'package:flutter/material.dart';
import '../models/medication_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';

class MedicationController extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  List<Medication> _medications = [];

  List<Medication> get medications => _medications;

  // --- LOGIQUE FILTREE (Séparée par état et temps) ---
  
  DateTime _getScheduledDateTime(Medication med) {
    try {
      final dateParts = med.dateToTake.split('-');
      final timeParts = med.timeToTake.split(':');
      int hour = int.parse(timeParts[0].trim());
      int minute = int.parse(timeParts[1].replaceAll(RegExp(r'[^0-9]'), '').trim());
      
      // Gestion robuste du format AM/PM
      if (med.timeToTake.toUpperCase().contains('PM') && hour < 12) {
        hour += 12;
      } else if (med.timeToTake.toUpperCase().contains('AM') && hour == 12) {
        hour = 0;
      }

      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        hour,
        minute,
      );
    } catch (e) {
      return DateTime.now().subtract(const Duration(days: 1)); // Fallback
    }
  }

  List<Medication> get pendingMedications {
    final now = DateTime.now();
    return _medications.where((med) {
      if (med.isTaken) return false;
      final scheduled = _getScheduledDateTime(med);
      // On affiche si c'est aujourd'hui (même si passé) ou dans le futur
      return scheduled.isAfter(now.subtract(const Duration(hours: 12))) || 
             (scheduled.year == now.year && scheduled.month == now.month && scheduled.day == now.day);
    }).toList();
  }

  List<Medication> get takenMedications => 
      _medications.where((med) => med.isTaken).toList();

  List<Medication> get missedMedications => 
      _medications.where((med) => !med.isTaken && _getScheduledDateTime(med).isBefore(DateTime.now())).toList();

  void fetchMedications(String userId) {
    listenToMedications(userId);
  }

  void listenToMedications(String userId) {
    _firestoreService.getMedications(userId).listen((meds) {
      _medications = meds;
      notifyListeners(); 
    });
  }

  Future<void> addMedication(String userId, Medication med) async {
    try {
      await _firestoreService.addMedication(userId, med);
    } catch (e) {
      debugPrint("Erreur ajout: $e");
    }
  }

  // UPDATE : Intègre la suppression automatique de la notification
  Future<void> updateMedication(String userId, Medication med, NotificationService notifService) async {
    try {
      med.isTaken = !med.isTaken; 
      await _firestoreService.updateMedication(userId, med);

      // Si le médicament est marqué comme PRIS, on nettoie la notification
      if (med.isTaken) {
        notifService.removeNotificationByTitle(med.name);
      }
    } catch (e) {
      debugPrint("Erreur mise à jour: $e");
    }
  }

  Future<void> deleteMedication(String userId, String medId) async {
    try {
      await _firestoreService.deleteMedication(userId, medId);
    } catch (e) {
      debugPrint("Erreur suppression: $e");
    }
  }
}