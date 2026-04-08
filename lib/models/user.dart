import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String nombre;
  final String email;
  final DateTime fechaRegistro;

  UserModel({
    required this.userId,
    required this.nombre,
    required this.email,
    required this.fechaRegistro,
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      userId: data['userId'] ?? '',
      nombre: data['nombre'] ?? '',
      email: data['email'] ?? '',
      fechaRegistro: (data['fechaRegistro'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nombre': nombre,
      'email': email,
      'fechaRegistro': Timestamp.fromDate(fechaRegistro),
    };
  }
}
