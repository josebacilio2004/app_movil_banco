class CuentaModel {
  final String cuentaId;
  final String userId;
  final String tipo; // corriente | ahorro
  final String numero;
  final double saldo;
  final double? metaAhorro;
  final double? progresoAhorro;

  CuentaModel({
    required this.cuentaId,
    required this.userId,
    required this.tipo,
    required this.numero,
    required this.saldo,
    this.metaAhorro,
    this.progresoAhorro,
  });

  factory CuentaModel.fromMap(Map<String, dynamic> data, String id) {
    return CuentaModel(
      cuentaId: id,
      userId: data['userId'] ?? '',
      tipo: data['tipo'] ?? 'corriente',
      numero: data['numero'] ?? '',
      saldo: (data['saldo'] ?? 0).toDouble(),
      metaAhorro: (data['metaAhorro'] != null) ? (data['metaAhorro'] as num).toDouble() : null,
      progresoAhorro: (data['progresoAhorro'] != null) ? (data['progresoAhorro'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'tipo': tipo,
      'numero': numero,
      'saldo': saldo,
      'metaAhorro': metaAhorro,
      'progresoAhorro': progresoAhorro,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CuentaModel &&
          runtimeType == other.runtimeType &&
          cuentaId == other.cuentaId;

  @override
  int get hashCode => cuentaId.hashCode;
}
