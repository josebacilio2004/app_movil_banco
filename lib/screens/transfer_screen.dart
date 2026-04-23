import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/cuenta.dart';
import '../utils/constants.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  CuentaModel? _cuentaOrigen;
  final _destinoController = TextEditingController();
  final _montoController = TextEditingController();

  bool _loading = false;
  bool _validandoDestino = false;
  Map<String, dynamic>? _infoDestino;

  @override
  void dispose() {
    _destinoController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _validarDestino() async {
    final destino = _destinoController.text.trim();
    if (destino.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ingrese un número de cuenta destino")),
      );
      return;
    }

    if (_cuentaOrigen != null && destino == _cuentaOrigen!.numero) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No puede transferir a la misma cuenta de origen"), backgroundColor: AppColors.errorRed),
      );
      return;
    }

    setState(() {
      _validandoDestino = true;
      _infoDestino = null;
    });

    final firestore = context.read<FirestoreService>();
    final info = await firestore.validarCuentaDestino(destino);

    if (mounted) {
      setState(() {
        _validandoDestino = false;
        _infoDestino = info;
      });

      if (info == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cuenta destino no encontrada"), backgroundColor: AppColors.errorRed),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cuenta validada correctamente"), backgroundColor: AppColors.successGreen),
        );
      }
    }
  }

  void _procesarTransferencia() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cuentaOrigen == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seleccione cuenta origen")));
      return;
    }
    if (_infoDestino == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Valide la cuenta destino primero")));
      return;
    }

    final monto = double.tryParse(_montoController.text);
    if (monto == null || monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingrese un monto válido")));
      return;
    }
    if (monto > _cuentaOrigen!.saldo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Saldo insuficiente. Disponible: S/ ${_cuentaOrigen!.saldo.toStringAsFixed(2)}"), backgroundColor: AppColors.errorRed),
      );
      return;
    }

    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    
    setState(() => _loading = true);

    try {
      await firestore.procesarTransferencia(
        fromUserId: auth.user!.uid,
        fromCuentaId: _cuentaOrigen!.cuentaId,
        toCuentaId: _infoDestino!['cuentaId'],
        toUserId: _infoDestino!['userId'],
        monto: monto,
        descripcion: 'Transferencia a ${_infoDestino!['titular']}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Transferencia exitosa"), backgroundColor: AppColors.successGreen),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.errorRed),
        );
      }
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
        title: const Text("Transferir", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<CuentaModel>>(
        stream: firestore.getCuentas(auth.user!.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final cuentas = snap.data ?? [];
          if (_cuentaOrigen == null && cuentas.isNotEmpty) {
            _cuentaOrigen = cuentas.firstWhere(
              (c) => c.tipo == 'corriente',
              orElse: () => cuentas.first,
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Cuenta Origen", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGray)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CuentaModel>(
                    initialValue: _cuentaOrigen,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.containerLow,
                      border: OutlineInputBorder(borderRadius: AppStyles.radiusXL, borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.account_balance_wallet, color: AppColors.secondaryBlue),
                    ),
                    items: cuentas.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text("${c.tipo.toUpperCase()} (${c.numero}) - S/ ${c.saldo.toStringAsFixed(2)}")
                    )).toList(),
                    onChanged: (val) => setState(() => _cuentaOrigen = val),
                  ),
                  const SizedBox(height: 24),
                  const Text("Cuenta Destino", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGray)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _destinoController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Número de cuenta o tarjeta",
                      filled: true,
                      fillColor: AppColors.containerLow,
                      border: OutlineInputBorder(borderRadius: AppStyles.radiusXL, borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.person, color: AppColors.secondaryBlue),
                      suffixIcon: _validandoDestino
                          ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                          : (_infoDestino != null
                              ? const Icon(Icons.check_circle, color: AppColors.successGreen)
                              : IconButton(
                                  icon: const Icon(Icons.search, color: AppColors.primaryRed),
                                  onPressed: _validarDestino,
                                )),
                    ),
                    onChanged: (_) {
                      if (_infoDestino != null) setState(() => _infoDestino = null);
                    },
                  ),
                  if (_infoDestino != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withValues(alpha: 0.1),
                        borderRadius: AppStyles.radiusXL,
                        border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, color: AppColors.successGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Titular verificado:", style: TextStyle(fontSize: 12, color: AppColors.successGreen)),
                                Text(_infoDestino!['titular'], style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text("Monto", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGray)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _montoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: "0.00",
                      prefixText: "S/ ",
                      filled: true,
                      fillColor: AppColors.containerLow,
                      border: OutlineInputBorder(borderRadius: AppStyles.radiusXL, borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.attach_money, color: AppColors.secondaryBlue),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Ingrese monto';
                      if (double.tryParse(val) == null) return 'Monto inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _procesarTransferencia,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusFull),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("TRANSFERIR", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.0)),
                    ),
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
