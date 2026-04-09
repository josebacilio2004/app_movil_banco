import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cuenta.dart';
import '../models/transaccion.dart';
import '../models/user.dart';
import '../models/prestamo.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Crear perfil de usuario y cuentas demo
  Future<void> createUserProfile(UserModel user, {String? customNumber}) async {
    await _db.collection('usuarios').doc(user.userId).set(user.toMap());
    
    // Crear cuentas demo
    final batch = _db.batch();
    
    final cuentaCorrienteRef = _db.collection('cuentas').doc();
    batch.set(cuentaCorrienteRef, {
      'userId': user.userId,
      'tipo': 'corriente',
      'numero': customNumber ?? '****4521',
      'saldo': 4250.00,
    });

    final cuentaAhorroRef = _db.collection('cuentas').doc();
    batch.set(cuentaAhorroRef, {
      'userId': user.userId,
      'tipo': 'ahorro',
      'numero': '****7890',
      'saldo': 2800.00,
      'metaAhorro': 20000.00,
      'progresoAhorro': 2800.00,
    });

    // Agregar 5 movimientos iniciales
    final movements = [
      {'descripcion': 'Pago Agua SEDAPAL', 'monto': 120.0, 'tipo': 'debito', 'fecha': DateTime.now()},
      {'descripcion': 'Transferencia Recibida', 'monto': 500.0, 'tipo': 'credito', 'fecha': DateTime.now().subtract(const Duration(days: 1))},
      {'descripcion': 'Compra Supermercado', 'monto': 250.0, 'tipo': 'debito', 'fecha': DateTime.now().subtract(const Duration(days: 2))},
      {'descripcion': 'Pago Celular', 'monto': 80.0, 'tipo': 'debito', 'fecha': DateTime.now().subtract(const Duration(days: 3))},
      {'descripcion': 'Abono de Sueldo', 'monto': 4000.0, 'tipo': 'credito', 'fecha': DateTime.now().subtract(const Duration(days: 5))},
    ];

    for (var m in movements) {
      final txRef = _db.collection('transacciones').doc();
      batch.set(txRef, {
        'userId': user.userId,
        'cuentaId': cuentaCorrienteRef.id,
        'descripcion': m['descripcion'],
        'monto': m['monto'],
        'tipo': m['tipo'],
        'fecha': Timestamp.fromDate(m['fecha'] as DateTime),
      });
    }

    await batch.commit();
  }

  Stream<UserModel?> getUser(String uid) {
    return _db.collection('usuarios').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return UserModel.fromMap(snap.data()!);
    });
  }

  Stream<List<CuentaModel>> getCuentas(String uid) {
    return _db.collection('cuentas').where('userId', isEqualTo: uid).snapshots().map((snap) =>
        snap.docs.map((doc) => CuentaModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<TransaccionModel>> getTransacciones(String uid) {
    return _db.collection('transacciones')
        .where('userId', isEqualTo: uid)
        .orderBy('fecha', descending: true)
        .snapshots().map((snap) =>
            snap.docs.map((doc) => TransaccionModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<PrestamoModel>> getPrestamos(String uid) {
    return _db.collection('prestamos').where('userId', isEqualTo: uid).snapshots().map((snap) =>
        snap.docs.map((doc) => PrestamoModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> registrarTransaccion(TransaccionModel tx) async {
    final batch = _db.batch();
    
    // Registrar transaccion
    final txRef = _db.collection('transacciones').doc();
    batch.set(txRef, tx.toMap());

    // Actualizar saldo de la cuenta
    final cuentaRef = _db.collection('cuentas').doc(tx.cuentaId);
    final montoMod = tx.tipo == 'debito' ? -tx.monto : tx.monto;
    batch.update(cuentaRef, {'saldo': FieldValue.increment(montoMod)});

    await batch.commit();
  }

  Future<void> solicitarPrestamo(PrestamoModel prestamo) async {
    await _db.collection('prestamos').add(prestamo.toMap());
  }

  // Buscar email por número de tarjeta/cuenta
  Future<String?> getEmailByCardNumber(String cardNumber) async {
    try {
      final querySnapshot = await _db.collection('cuentas')
          .where('numero', isEqualTo: cardNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final userId = querySnapshot.docs.first.data()['userId'];
      final userDoc = await _db.collection('usuarios').doc(userId).get();
      
      return userDoc.data()?['email'] as String?;
    } catch (e) {
      print("Error searching email by card: $e");
      return null;
    }
  }
}
