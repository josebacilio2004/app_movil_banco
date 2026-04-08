import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/transaccion.dart';
import '../models/cuenta.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  String _servicio = 'Agua';
  final _contratoController = TextEditingController();
  final _montoController = TextEditingController();
  CuentaModel? _cuentaSeleccionada;
  bool _loading = false;

  void _confirmarPago() async {
    if (!_formKey.currentState!.validate() || _cuentaSeleccionada == null) {
      if (_cuentaSeleccionada == null) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seleccione una cuenta")));
      return;
    }
    
    final monto = double.parse(_montoController.text);
    if (_cuentaSeleccionada!.saldo < monto) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saldo insuficiente en la cuenta seleccionada")));
      return;
    }

    setState(() => _loading = true);
    final firestore = context.read<FirestoreService>();
    final auth = context.read<AuthService>();

    final tx = TransaccionModel(
      transaccionId: '',
      userId: auth.user!.uid,
      cuentaId: _cuentaSeleccionada!.cuentaId,
      descripcion: 'Pago $_servicio - ${_contratoController.text}',
      monto: monto,
      tipo: 'debito',
      fecha: DateTime.now(),
    );

    try {
      await firestore.registrarTransaccion(tx);
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ConfirmationScreen(
          servicio: _servicio,
          monto: monto,
          contrato: _contratoController.text,
        )));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al procesar pago: $e")));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Pagar Servicios", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<CuentaModel>>(
        stream: firestore.getCuentas(auth.user!.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final cuentas = snap.data ?? [];
          if (_cuentaSeleccionada == null && cuentas.isNotEmpty) {
            _cuentaSeleccionada = cuentas.firstWhere((c) => c.tipo == 'corriente', orElse: () => cuentas.first);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("¿Qué servicio deseas pagar?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondaryBlue)),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _servicio,
                    decoration: InputDecoration(
                      labelText: 'Selecciona Servicio', 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.business_outlined),
                    ),
                    items: ['Agua', 'Luz', 'Cable', 'Internet'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => _servicio = val!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contratoController,
                    decoration: InputDecoration(
                      labelText: 'Número de Contrato', 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.numbers_outlined),
                    ),
                    keyboardType: TextInputType.number,
                    validator: Validators.validateContract,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _montoController,
                    decoration: InputDecoration(
                      labelText: 'Monto a Pagar (S/)', 
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.attach_money_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: Validators.validateAmount,
                  ),
                  const SizedBox(height: 24),
                  const Text("Origen del pago", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGray)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CuentaModel>(
                    value: _cuentaSeleccionada,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: cuentas.map((c) => DropdownMenuItem(
                      value: c, 
                      child: Text("${c.tipo.toUpperCase()} (${c.numero}) - S/ ${c.saldo.toStringAsFixed(2)}")
                    )).toList(),
                    onChanged: (val) => setState(() => _cuentaSeleccionada = val!),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _confirmarPago,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                      ),
                      child: _loading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text("PROCEDER AL PAGO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    ),
                  )
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}
