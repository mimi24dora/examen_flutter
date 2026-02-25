import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/medication_controller.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final notificationService = Provider.of<NotificationService>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Suivi & Historique"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.vibrantRed,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: AppColors.navyBlue,
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            tabs: [
              Tab(text: "Pris"),
              Tab(text: "Manqués"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            Consumer<MedicationController>(
              builder: (context, controller, child) {
                return _buildMedList(context, controller.takenMedications, user?.uid, notificationService, isTakenTab: true);
              },
            ),
            Consumer<MedicationController>(
              builder: (context, controller, child) {
                return _buildMedList(context, controller.missedMedications, user?.uid, notificationService, isTakenTab: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedList(BuildContext context, List meds, String? userId, NotificationService notifService, {required bool isTakenTab}) {
    if (meds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 80, color: Colors.grey.withOpacity(0.2)),
            const SizedBox(height: 20),
            const Text("Aucun historique pour le moment", style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: meds.length,
      itemBuilder: (context, index) {
        final med = meds[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isTakenTab ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTakenTab ? Icons.check_rounded : Icons.close_rounded,
                color: isTakenTab ? Colors.green : Colors.redAccent,
                size: 24,
              ),
            ),
            title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.navyBlue)),
            subtitle: Text(
              "Le ${med.dateToTake} à ${med.timeToTake}",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: Colors.grey.shade300, size: 28),
              onPressed: () async {
                if (userId != null) {
                  await Provider.of<MedicationController>(context, listen: false).deleteMedication(userId, med.id);
                  final notificationId = int.parse(med.id.substring(med.id.length - 6));
                  await notifService.cancelNotification(notificationId);
                }
              },
            ),
          ),
        );
      },
    );
  }
}