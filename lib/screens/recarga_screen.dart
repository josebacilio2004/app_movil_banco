import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/cuenta.dart';
import '../models/transaccion.dart';
import '../models/operador.dart';
import '../utils/constants.dart';

class RecargaScreen extends StatefulWidget {
  const RecargaScreen({super.key});

  @override
  State<RecargaScreen> createState() => _RecargaScreenState();
}

class _RecargaScreenState extends State<RecargaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroController = TextEditingController();
  final _montoController = TextEditingController();
  CuentaModel? _cuentaSeleccionada;
  OperadorModel? _operadorSeleccionado;
  bool _loading = false;

  final List<double> _montosRecarga = [5, 10, 20, 30, 50, 100];

  void _detectarOperador() {
    final numero = _numeroController.text.trim();
    if (numero.length >= 3) {
      setState(() {
        _operadorSeleccionado = OperadorModel.identificarOperador(numero);
      });
    }
  }

  Future<void> _realizarRecarga() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cuentaSeleccionada == null) return;

    final monto = double.parse(_montoController.text);
    if (_cuentaSeleccionada!.saldo < monto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saldo insuficiente'), backgroundColor: AppColors.errorRed),
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
      descripcion: 'Recarga ${_operadorSeleccionado?.nombre} - ${_numeroController.text}',
      monto: monto,
      tipo: 'debito',
      fecha: DateTime.now(),
    );

    try {
      await firestore.registrarTransaccion(transaccion);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Recarga exitosa'), backgroundColor: AppColors.successGreen),
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
        title: const Text('Recarga de Celular', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    controller: _numeroController,
                    decoration: InputDecoration(
                      labelText: 'Número de celular (9 dígitos)',
                      prefixIcon: const Icon(Icons.phone_android),
                      suffixIcon: _operadorSeleccionado != null
                          ? Text('${_operadorSeleccionado!.icono} ${_operadorSeleccionado!.nombre}')
                          : null,
                    ),
                    keyboardType: TextInputType.phone,
                    maxLength: 9,
                    onChanged: (_) => _detectarOperador(),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Ingrese número';
                      if (v.length != 9) return 'Debe tener 9 dígitos';
                      if (OperadorModel.identificarOperador(v) == null) return 'Operador no reconocido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    children: _montosRecarga.map((monto) {
                      return ChoiceChip(
                        label: Text('S/ $monto'),
                        selected: _montoController.text == monto.toString(),
                        onSelected: (_) => setState(() => _montoController.text = monto.toString()),
                        backgroundColor: AppColors.containerLow,
                        selectedColor: AppColors.primaryRed,
                        labelStyle: TextStyle(color: _montoController.text == monto.toString() ? Colors.white : null),
                      );
                    }).toList(),
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
                    onPressed: _loading ? null : _realizarRecarga,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed, minimumSize: const Size(double.infinity, 50)),
                    child: _loading ? const CircularProgressIndicator() : const Text('RECARGAR', style: TextStyle(color: Colors.white)),
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