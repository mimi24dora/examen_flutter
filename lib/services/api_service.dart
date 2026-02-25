import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Cette fonction cherche des noms de produits via l'API REST
  Future<List<String>> searchMedicationNames(String query) async {
    // On commence la recherche seulement à partir de 3 caractères pour économiser l'API
    if (query.length < 3) return [];

    // URL de l'API Open Food Facts (Filtre simplifié)
    final url = Uri.parse(
      'https://world.openfoodfacts.org/cgi/search.pl?search_terms=$query&search_simple=1&action=process&json=1&page_size=8'
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List products = data['products'];
        
        // On récupère les noms, on enlève les vides et les doublons
        return products
            .map((p) => p['product_name'] as String? ?? "")
            .where((name) => name.isNotEmpty && name.length > 2)
            .toSet() 
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Erreur de connexion API : $e");
      return [];
    }
  }
}