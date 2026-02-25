import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notification_service.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final notifService = Provider.of<NotificationService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF), // Cohérence avec les autres vues
      appBar: AppBar(
        title: const Text(
          "Mes Alertes",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: notifService.activeNotifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: notifService.activeNotifications.length,
              itemBuilder: (context, index) {
                final notif = notifService.activeNotifications[index];
                return _buildNotificationCard(notif);
              },
            ),
    );
  }

  // Design d'une carte de notification moderne
  Widget _buildNotificationCard(Map<String, String> notif) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orangeAccent.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.orangeAccent.withOpacity(0.1), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.notifications_active_rounded,
            color: Colors.orangeAccent,
            size: 24,
          ),
        ),
        title: Text(
          notif['title'] ?? "Rappel",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            notif['content'] ?? "Il est l'heure de votre prise.",
            style: TextStyle(color: Colors.grey.shade600, height: 1.3),
          ),
        ),
      ),
    );
  }

  // État vide stylisé
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: Colors.blueAccent.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Tout est à jour !",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          const Text(
            "Aucune alerte pour le moment.",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}