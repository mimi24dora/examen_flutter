import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../controllers/medication_controller.dart';
import '../controllers/auth_controller.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'add_medication_view.dart';
import 'history_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  StreamSubscription? _notificationSubscription;
  
  String _formatDisplayName(String? email) {
    if (email == null || email.isEmpty) return "Utilisateur";
    String name = email.split('@')[0].replaceAll(RegExp(r'[0-9]'), '').replaceAll(RegExp(r'[._-]'), ' ');
    return name.split(' ').map((str) => str.isEmpty ? "" : str[0].toUpperCase() + str.substring(1).toLowerCase()).join(' ').trim();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final notifService = Provider.of<NotificationService>(context, listen: false);

      if (userId != null) {
        Provider.of<MedicationController>(context, listen: false).fetchMedications(userId);
      }

      // Écouter les notifications internes
      _notificationSubscription = notifService.onNotificationReceived.listen((data) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['title'] ?? "Rappel", style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(data['content'] ?? "", style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.vibrantRed,
            duration: const Duration(seconds: 10),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            action: SnackBarAction(
              label: "OK",
              textColor: Colors.white,
              onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            ),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final medController = Provider.of<MedicationController>(context);
    final authController = Provider.of<AuthController>(context, listen: false);
    final notifService = Provider.of<NotificationService>(context, listen: false);
    final String displayName = _formatDisplayName(user?.email);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Elegant Header with Gradient
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 60, left: 25, right: 25, bottom: 40),
              decoration: const BoxDecoration(
                gradient: AppColors.blueRedGradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Bonjour,", style: TextStyle(fontSize: 16, color: Colors.white70, fontWeight: FontWeight.w500)),
                          Text(displayName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              final status = await notifService.showTestNotification();
                              if (!mounted) return;
                              
                              String message = "";
                              if (status == 'granted') {
                                message = "🚀 Notification de test envoyée !";
                              } else if (status == 'denied') {
                                message = "🚫 Accès refusé. Veuillez activer les notifications dans les paramètres de votre navigateur.";
                              } else if (status == 'default') {
                                message = "⚠️ Permission en attente. Veuillez autoriser les notifications dans la fenêtre qui s'affiche.";
                              } else if (status == 'error') {
                                message = "❌ Erreur lors de l'envoi. Essayez de recharger la page.";
                              }

                              if (message.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(message),
                                    backgroundColor: status == 'granted' ? Colors.green : Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () async => await authController.signOut(context),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 24),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  // Glassmorphic Summary Card
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.medication_rounded, color: AppColors.navyBlue, size: 30),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Progression Today", style: TextStyle(color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 5),
                              Text(
                                "${medController.takenMedications.length} / ${medController.medications.length} prises",
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(25, 30, 25, 15),
              child: Text("Vos Rappels (+ À venir)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
            ),
          ),

          medController.pendingMedications.isEmpty
              ? const SliverFillRemaining(child: Center(child: Text("Aucun rappel à venir.", style: TextStyle(color: Colors.grey))))
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final med = medController.pendingMedications[index];
                        return TweenAnimationBuilder(
                          duration: Duration(milliseconds: 400 + (index * 100)),
                          tween: Tween<double>(begin: 0, end: 1),
                          builder: (context, double value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 30 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5)),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: med.isTaken 
                                    ? AppColors.blueGradient 
                                    : LinearGradient(colors: [Colors.grey.shade100, Colors.grey.shade200]),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Icon(
                                  Icons.medication_rounded,
                                  color: med.isTaken ? Colors.white : Colors.grey.shade400,
                                ),
                              ),
                              title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.navyBlue)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text("Prévu le ${med.dateToTake} à ${med.timeToTake}", style: TextStyle(color: Colors.grey.shade600)),
                              ),
                              trailing: Checkbox(
                                value: med.isTaken,
                                activeColor: AppColors.vibrantRed,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                onChanged: (val) => medController.updateMedication(user!.uid, med, notifService),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: medController.pendingMedications.length,
                    ),
                  ),
                ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryView())),
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.navyBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.bar_chart_rounded, color: AppColors.navyBlue),
                      SizedBox(width: 10),
                      Text("Historique", style: TextStyle(color: AppColors.navyBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            FloatingActionButton(
              backgroundColor: AppColors.vibrantRed,
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddMedicationView())),
              child: const Icon(Icons.add_rounded, size: 35, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}