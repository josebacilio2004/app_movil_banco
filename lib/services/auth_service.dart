import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  String? _enrolledEmail;

  bool _isLoggingOut = false;

  User? get user => _user;
  String? get enrolledEmail => _enrolledEmail;
  bool get isAuthenticated => _user != null;
  bool get isLoggingOut => _isLoggingOut;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      if (_isLoggingOut) return; // Ignorar eventos durante el proceso de logout manual
      
      if (_user?.uid != user?.uid) {
        print("AUTH: Cambio de estado detectado: ${user?.email ?? 'Sesión cerrada'}");
        _user = user;
        notifyListeners();
      }
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
    print("AUTH: Logout v1.0.6 (Persistent Enrollment) Iniciado");
    
    _isLoggingOut = true;
    _user = null;
    // NO limpiamos _enrolledEmail aquí para permitir que regrese a la pantalla de PIN
    notifyListeners(); 

    _performBackgroundCleanup();
  }

  Future<void> _performBackgroundCleanup() async {
    try {
      // En un logout NORMAL, no queremos borrar el enrolamiento (comportamiento BCP)
      // Solo cerramos la sesión en Firebase.
      await _auth.signOut();
      print("AUTH: Cleanup de segundo plano (Firebase) completado");
    } catch (e) {
      print("AUTH ERROR en cleanup: $e");
    } finally {
      _isLoggingOut = false;
      notifyListeners(); // IMPORTANTE: Notificar para salir del estado de bloqueo en AuthWrapper
    }
  }
}
