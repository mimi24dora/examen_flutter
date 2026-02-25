class Medication {
  String id;
  String name;
  String dosage;
  String frequency;
  String timeToTake;
  String dateToTake; // Nouveau champ pour la date
  String userId;
  bool isTaken; 
  DateTime? lastTaken;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.timeToTake,
    required this.dateToTake,
    required this.userId,
    this.isTaken = false,
    this.lastTaken,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'timeToTake': timeToTake,
      'dateToTake': dateToTake,
      'userId': userId,
      'isTaken': isTaken,
      'lastTaken': lastTaken?.toIso8601String(),
    };
  }

  factory Medication.fromFirestore(Map<String, dynamic> firestore, String id) {
    return Medication(
      id: id,
      name: firestore['name'] ?? '',
      dosage: firestore['dosage'] ?? '',
      frequency: firestore['frequency'] ?? '',
      timeToTake: firestore['timeToTake'] ?? '',
      dateToTake: firestore['dateToTake'] ?? '',
      userId: firestore['userId'] ?? '',
      isTaken: firestore['isTaken'] ?? false,
      lastTaken: firestore['lastTaken'] != null 
          ? DateTime.parse(firestore['lastTaken']) 
          : null,
    );
  }
}