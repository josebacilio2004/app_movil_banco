import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cuenta.dart';
import '../models/transaccion.dart';
import '../models/user.dart';
import '../models/prestamo.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
 
  String _normalize(String value) => value.replaceAll(RegExp(r'\D'), '');

  // Reparación inteligente: Crea el perfil solo si las cuentas ya existen
  Future<void> checkAndRepairUserProfile(UserModel user) async {
    final accountsQuery = await _db.collection('cuentas').where('userId', isEqualTo: user.userId).limit(1).get();
    
    if (accountsQuery.docs.isNotEmpty) {
      // Las cuentas ya existen, solo creamos el documento de usuario
      print("REPAIR: Cuentas detectadas, vinculando perfil para ${user.userId}");
      await saveUserProfile(user);
    } else {
      // No hay nada, creamos todo desde cero
      print("REPAIR: No se detectaron cuentas, realizando creación completa");
      await createUserProfile(user);
    }
  }

  // Guardar perfil de usuario (sin tocar cuentas)
  Future<void> saveUserProfile(UserModel user) async {
    await _db.collection('usuarios').doc(user.userId).set(user.toMap());
  }

  // Generar datos iniciales para una nueva cuenta
  Future<void> generateInitialData(String userId, {String? customNumber}) async {
    final normalizedNumber = customNumber != null ? _normalize(customNumber) : '4521890123456789';
    
    // Verificar si ya tiene cuentas para no duplicar
    final existing = await _db.collection('cuentas').where('userId', isEqualTo: userId).limit(1).get();
    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();
    
    final cuentaCorrienteRef = _db.collection('cuentas').doc();
    batch.set(cuentaCorrienteRef, {
      'userId': userId,
      'tipo': 'corriente',
      'numero': normalizedNumber,
      'saldo': 4250.00,
    });

    final cuentaAhorroRef = _db.collection('cuentas').doc();
    batch.set(cuentaAhorroRef, {
      'userId': userId,
      'tipo': 'ahorro',
      'numero': '7890123456781234',
      'saldo': 2800.00,
      'metaAhorro': 20000.00,
      'progresoAhorro': 2800.00,
    });

    // Movimientos iniciales
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
        'userId': userId,
        'cuentaId': cuentaCorrienteRef.id,
        'descripcion': m['descripcion'],
        'monto': m['monto'],
        'tipo': m['tipo'],
        'fecha': Timestamp.fromDate(m['fecha'] as DateTime),
      });
    }

    await batch.commit();
  }

  // Crear perfil de usuario y cuentas demo
  Future<void> createUserProfile(UserModel user, {String? customNumber}) async {
    await saveUserProfile(user);
    await generateInitialData(user.userId, customNumber: customNumber);
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
      final normalized = _normalize(cardNumber);
      final querySnapshot = await _db.collection('cuentas')
          .where('numero', isEqualTo: normalized)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Fallback: Try searching with exact input if normalization changed it
        if (normalized != cardNumber) {
          final exactQuery = await _db.collection('cuentas')
              .where('numero', isEqualTo: cardNumber)
              .limit(1)
              .get();
          if (exactQuery.docs.isNotEmpty) {
            final userId = exactQuery.docs.first.data()['userId'];
            final userDoc = await _db.collection('usuarios').doc(userId).get();
            return userDoc.data()?['email'] as String?;
          }
        }
        return null;
      }

      final userId = querySnapshot.docs.first.data()['userId'];
      final userDoc = await _db.collection('usuarios').doc(userId).get();
      
      return userDoc.data()?['email'] as String?;
    } catch (e) {
      print("Error searching email by card: $e");
      return null;
    }
  }
}
