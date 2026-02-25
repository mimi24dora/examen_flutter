import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medication_model.dart';
import '../controllers/medication_controller.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class AddMedicationView extends StatefulWidget {
  const AddMedicationView({super.key});

  @override
  _AddMedicationViewState createState() => _AddMedicationViewState();
}

class _AddMedicationViewState extends State<AddMedicationView> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  String name = '';
  String dosage = '';
  TimeOfDay selectedTime = TimeOfDay.now();
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final medController = Provider.of<MedicationController>(context, listen: false);
    final notifService = Provider.of<NotificationService>(context, listen: false);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nouveau Rappel"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Détails du Traitement", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
              const SizedBox(height: 20),
              
              // Med Name with Search icon
              _buildModernField(
                child: Autocomplete<String>(
                  optionsBuilder: (textValue) async => await _apiService.searchMedicationNames(textValue.text),
                  onSelected: (selection) => setState(() => name = selection),
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white,
                        child: Container(
                          width: MediaQuery.of(context).size.width - 48,
                          constraints: const BoxConstraints(maxHeight: 250),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: AppColors.navyBlue.withOpacity(0.1)),
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(option, style: const TextStyle(color: AppColors.navyBlue, fontWeight: FontWeight.w500)),
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.navyBlue),
                      decoration: _modernInputDecoration("Nom du médicament", Icons.search_rounded),
                      onChanged: (val) => name = val,
                      validator: (val) => val!.isEmpty ? "Le nom est requis" : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              
              // Dosage
              _buildModernField(
                child: TextFormField(
                  style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.navyBlue),
                  decoration: _modernInputDecoration("Dosage (ex: 1 comprimé)", Icons.medication_rounded),
                  onChanged: (val) => dosage = val,
                ),
              ),
              
              const SizedBox(height: 40),
              const Text("Planification", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
              const SizedBox(height: 20),

              _buildModernPickerTile(
                label: "Date",
                value: "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                icon: Icons.calendar_today_rounded,
                color: AppColors.navyBlue,
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => selectedDate = picked);
                },
              ),
              const SizedBox(height: 15),

              _buildModernPickerTile(
                label: "Heure",
                value: selectedTime.format(context),
                icon: Icons.access_time_rounded,
                color: AppColors.vibrantRed,
                onTap: () async {
                  TimeOfDay? picked = await showTimePicker(context: context, initialTime: selectedTime);
                  if (picked != null) setState(() => selectedTime = picked);
                },
              ),

              const SizedBox(height: 60),

              // Gradient Save Button
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppColors.blueGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.navyBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate() && userId != null) {
                      await notifService.init();
                      final String uniqueId = DateTime.now().millisecondsSinceEpoch.toString();
                      final newMed = Medication(
                        id: uniqueId,
                        name: name,
                        dosage: dosage,
                        frequency: "Ponctuel",
                        timeToTake: "${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}",
                        dateToTake: "${selectedDate.year}-${selectedDate.month}-${selectedDate.day}",
                        userId: userId,
                      );
                      DateTime scheduledDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
                      if (scheduledDate.isAfter(DateTime.now())) {
                        await medController.addMedication(userId, newMed);
                        int notifId = int.parse(uniqueId.substring(uniqueId.length - 6));
                        await notifService.scheduleNotification(id: notifId, title: "💊 Rappel : $name", body: "Dose : $dosage", scheduledDate: scheduledDate);
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("L'heure est déjà passée !")));
                      }
                    }
                  },
                  child: const Text("ENREGISTRER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernField({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }

  Widget _buildModernPickerTile({required String label, required String value, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navyBlue)),
              ],
            ),
            const Spacer(),
            const Icon(Icons.edit_rounded, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  InputDecoration _modernInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: AppColors.navyBlue),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
    );
  }
}