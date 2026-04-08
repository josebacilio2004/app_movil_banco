import 'package:cloud_firestore/cloud_firestore.dart';

class PrestamoModel {
  final String prestamoId;
  final String userId;
  final double monto;
  final int plazo;
  final double cuotaMensual;
  final String estado; // pendiente | aprobado | rechazado | pagado
  final DateTime fechaSolicitud;

  PrestamoModel({
    required this.prestamoId,
    required this.userId,
    required this.monto,
    required this.plazo,
    required this.cuotaMensual,
    required this.estado,
    required this.fechaSolicitud,
  });

  factory PrestamoModel.fromMap(Map<String, dynamic> data, String id) {
    return PrestamoModel(
      prestamoId: id,
      userId: data['userId'] ?? '',
      monto: (data['monto'] ?? 0).toDouble(),
      plazo: (data['plazo'] ?? 0).toInt(),
      cuotaMensual: (data['cuotaMensual'] ?? 0).toDouble(),
      estado: data['estado'] ?? 'pendiente',
      fechaSolicitud: (data['fechaSolicitud'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'monto': monto,
      'plazo': plazo,
      'cuotaMensual': cuotaMensual,
      'estado': estado,
      'fechaSolicitud': Timestamp.fromDate(fechaSolicitud),
    };
  }
}
