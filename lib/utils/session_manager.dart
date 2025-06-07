// lib/utils/session_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
// Corrija o import: precisa subir um nível na hierarquia de pastas
import '../JsonModels/users.dart'; // <<< CORREÇÃO AQUI: De 'package:app_planejamentos_viagens/JsonModels/users.dart' para '../JsonModels/users.dart'

class SessionManager {
  static const String _keyLoggedInUserId = 'loggedInUserId';
  static const String _keyLoggedInUserName =
      'loggedInUserName'; // Opcional, para exibir nome

  static Future<void> saveLoggedInUser(Users user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user.usrId != null) {
      await prefs.setInt(_keyLoggedInUserId, user.usrId!);
      await prefs.setString(_keyLoggedInUserName, user.usrName);
    }
  }

  static Future<int?> getLoggedInUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyLoggedInUserId);
  }

  static Future<String?> getLoggedInUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLoggedInUserName);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedInUserId);
    await prefs.remove(_keyLoggedInUserName);
  }
}
