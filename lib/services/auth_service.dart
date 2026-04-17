import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String? _enrolledEmail;

  User? get user => _user;
  String? get enrolledEmail => _enrolledEmail;
  bool get isAuthenticated => _user != null;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
    _loadEnrolledEmail();
  }

  Future<void> _loadEnrolledEmail() async {
    final prefs = await SharedPreferences.getInstance();
    _enrolledEmail = prefs.getString('enrolled_email');
    notifyListeners();
  }

  Future<void> setEnrolledEmail(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    if (email != null) {
      await prefs.setString('enrolled_email', email);
    } else {
      await prefs.remove('enrolled_email');
      // También podríamos querer limpiar nombre y tarjeta si existen
      await prefs.remove('enrolled_name');
      await prefs.remove('enrolled_card');
    }
    _enrolledEmail = email;
    notifyListeners();
  }

  Future<String?> login(String email, String password) async {
// ... existing login code ...
    try {
      print("AUTH: Intentando login para $email (timeout 15s)");
      await _auth.signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));
      print("AUTH: Login exitoso para $email");
      
      _user = _auth.currentUser;
      notifyListeners();
      
      return null;
    } on FirebaseAuthException catch (e) {
      print("AUTH ERROR: ${e.code} - ${e.message}");
      return e.message;
    } catch (e) {
      print("AUTH UNKNOWN ERROR: $e");
      return "Error de conexión o clave incorrecta";
    }
  }

// ... existing methods ...
  Future<void> signInAnonymously() async {
    try {
      if (_auth.currentUser == null) {
        print("AUTH: Iniciando sesión anónima para búsqueda...");
        await _auth.signInAnonymously();
      }
    } catch (e) {
      print("AUTH ERROR anónimo: $e");
    }
  }

  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('enrolled_email');
      await prefs.remove('enrolled_name');
      await prefs.remove('enrolled_card');
      _enrolledEmail = null;
      print("AUTH: Enrolamiento local eliminado");
    } catch (e) {
      print("AUTH ERROR clearing prefs: $e");
    }
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}
