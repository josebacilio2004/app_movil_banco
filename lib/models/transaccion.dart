import 'package:cloud_firestore/cloud_firestore.dart';

class TransaccionModel {
  final String transaccionId;
  final String userId;
  final String cuentaId;
  final String descripcion;
  final double monto;
  final String tipo; // debito | credito
  final DateTime fecha;

  TransaccionModel({
    required this.transaccionId,
    required this.userId,
    required this.cuentaId,
    required this.descripcion,
    required this.monto,
    required this.tipo,
    required this.fecha,
  });

  factory TransaccionModel.fromMap(Map<String, dynamic> data, String id) {
    return TransaccionModel(
      transaccionId: id,
      userId: data['userId'] ?? '',
      cuentaId: data['cuentaId'] ?? '',
      descripcion: data['descripcion'] ?? '',
      monto: (data['monto'] ?? 0).toDouble(),
      tipo: data['tipo'] ?? 'debito',
      fecha: (data['fecha'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'cuentaId': cuentaId,
      'descripcion': descripcion,
      'monto': monto,
      'tipo': tipo,
      'fecha': Timestamp.fromDate(fecha),
    };
  }
}
