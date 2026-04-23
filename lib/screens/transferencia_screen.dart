import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/cuenta.dart';
import '../models/transaccion.dart';
import '../utils/constants.dart';

class TransferenciaScreen extends StatefulWidget {
  const TransferenciaScreen({super.key});

  @override
  State<TransferenciaScreen> createState() => _TransferenciaScreenState();
}

class _TransferenciaScreenState extends State<TransferenciaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cuentaController = TextEditingController();
  final _montoController = TextEditingController();
  final _nombreController = TextEditingController();
  CuentaModel? _cuentaSeleccionada;
  bool _loading = false;

  Future<void> _realizarTransferencia() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cuentaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una cuenta origen')),
      );
      return;
    }

    final monto = double.parse(_montoController.text);
    if (_cuentaSeleccionada!.saldo < monto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saldo insuficiente'), backgroundColor: AppColors.errorRed),
      );
      return;
    }

    setState(() => _loading = true);
    final firestore = context.read<FirestoreService>();
    final auth = context.read<AuthService>();
    final currentUser = auth.user;
    if (currentUser == null) return;

    final transaccion = TransaccionModel(
      transaccionId: '',
      userId: currentUser.uid,
      cuentaId: _cuentaSeleccionada!.cuentaId,
      descripcion: 'Transferencia a ${_nombreController.text} - Cuenta: ${_cuentaController.text}',
      monto: monto,
      tipo: 'debito',
      fecha: DateTime.now(),
    );

    try {
      await firestore.registrarTransaccion(transaccion);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Transferencia exitosa'), backgroundColor: AppColors.successGreen),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.errorRed),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final firestore = context.read<FirestoreService>();
    final currentUser = auth.user;
    if (currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transferencias', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<CuentaModel>>(
        stream: firestore.getCuentas(currentUser.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final cuentas = snap.data ?? [];
          if (_cuentaSeleccionada == null && cuentas.isNotEmpty) {
            _cuentaSeleccionada = cuentas.firstWhere((c) => c.tipo == 'corriente', orElse: () => cuentas.first);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _cuentaController,
                    decoration: const InputDecoration(labelText: 'Número de cuenta', prefixIcon: Icon(Icons.account_balance)),
                    validator: (v) => (v == null || v.isEmpty) ? 'Ingrese cuenta' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre del titular', prefixIcon: Icon(Icons.person)),
                    validator: (v) => (v == null || v.isEmpty) ? 'Ingrese nombre' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _montoController,
                    decoration: const InputDecoration(labelText: 'Monto (S/)', prefixIcon: Icon(Icons.attach_money)),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingrese monto';
                      if (double.tryParse(v) == null) return 'Monto inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<CuentaModel>(
                    value: _cuentaSeleccionada,
                    items: cuentas.map((c) => DropdownMenuItem(value: c, child: Text('${c.tipo} - S/ ${c.saldo}'))).toList(),
                    onChanged: (v) => setState(() => _cuentaSeleccionada = v),
                    decoration: const InputDecoration(labelText: 'Cuenta origen'),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _loading ? null : _realizarTransferencia,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed, minimumSize: const Size(double.infinity, 50)),
                    child: _loading ? const CircularProgressIndicator() : const Text('TRANSFERIR', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}