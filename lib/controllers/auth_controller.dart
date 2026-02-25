import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../views/home_view.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Ajoute cet import

class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // --- MÉTHODE DÉCONNEXION RÉPARÉE (VERSION FINALE) ---
  Future<void> signOut(BuildContext context) async {
    try {
      await _authService.signOut();
    } catch (e) {
      if (context.mounted) {
        debugPrint("Erreur technique de déconnexion : $e");
      }
    }
  }

  // --- CONNEXION EMAIL ---
  Future<void> login(String email, String password, BuildContext context) async {
    _setLoading(true);
    try {
      await _authService.signIn(email, password);
    } catch (e) {
      _showError(e.toString(), context);
    } finally {
      _setLoading(false);
    }
  }

  // --- INSCRIPTION (REDIRECTION AJOUTÉE) ---
  Future<void> register(String email, String password, BuildContext context) async {
    _setLoading(true);
    try {
      await _authService.signUp(email, password);
      
      // AJOUT DE LA REDIRECTION IMMÉDIATE
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeView()),
          (route) => false,
        );
      }
    } catch (e) {
      _showError(e.toString(), context);
    } finally {
      _setLoading(false);
    }
  }

  // --- CONNEXION GOOGLE ---
  Future<void> loginWithGoogle(BuildContext context) async {
    _setLoading(true);
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      _showError(e.toString(), context);
    } finally {
      _setLoading(false);
    }
  }

  // --- GESTION DES ERREURS ---
  void _showError(String message, BuildContext context) {
    String cleanMessage = message;
    if (message.contains("too-many-requests")) {
      cleanMessage = "Trop de tentatives. Réessayez plus tard.";
    } else if (message.contains("invalid-credential")) {
      cleanMessage = "Email ou mot de passe incorrect.";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(cleanMessage), backgroundColor: Colors.red),
    );
  }
}