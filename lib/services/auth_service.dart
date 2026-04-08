import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  AuthService() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<String?> login(String email, String password) async {
    try {
      print("AUTH: Intentando login para $email (timeout 15s)");
      await _auth.signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15));
      print("AUTH: Login exitoso para $email");
      
      // Forzar actualización de estado por si authStateChanges tarda
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

  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}
