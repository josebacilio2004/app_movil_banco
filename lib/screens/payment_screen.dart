import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/transaccion.dart';
import '../models/cuenta.dart';
import '../utils/constants.dart';
import '../utils/contract_validator.dart';
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
  bool _verifying = false;
  ContractInfo? _contractInfo;


  final List<String> _servicios = ['Agua', 'Luz', 'Cable', 'Internet'];


  @override
  void dispose() {
    _contratoController.dispose();
    _montoController.dispose();
    super.dispose();
  }


  Future<void> _verifyContract() async {
    final contrato = _contratoController.text.trim();
    if (contrato.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un número de contrato')),
      );
      return;
    }


    final formatError = ContractValidator.validateContract(_servicio, contrato);
    if (formatError != null) {
      setState(() {
        _contractInfo = ContractInfo(
          isValid: false,
          message: formatError,
          consumerName: null,
          amountDue: null,
          dueDate: null,
        );
      });
      return;
    }


    setState(() => _verifying = true);


    try {
      final info = await ContractValidator.verifyWithProvider(_servicio, contrato);
      setState(() {
        _contractInfo = info;
        _verifying = false;
      });


      if (info.isValid && info.amountDue != null) {
        _montoController.text = info.amountDue!.toStringAsFixed(2);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${info.message}'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      } else if (!info.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(info.message),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e) {
      setState(() => _verifying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al verificar: ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }


  void _confirmarPago() async {
    if (!_formKey.currentState!.validate()) return;


    if (_cuentaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione una cuenta')),
      );
      return;
    }


    final monto = double.parse(_montoController.text);
    final contrato = _contratoController.text.trim();


    final contractError = ContractValidator.validateContract(_servicio, contrato);
    if (contractError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(contractError), backgroundColor: AppColors.errorRed),
      );
      return;
    }


    if (_contractInfo == null || !_contractInfo!.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, verifique el número de contrato primero'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }


    if (_cuentaSeleccionada!.saldo < monto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saldo insuficiente. Disponible: S/ ${_cuentaSeleccionada!.saldo.toStringAsFixed(2)}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }


    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmar Pago', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfirmRow('Servicio:', _servicio),
            const SizedBox(height: 8),
            _buildConfirmRow('Contrato:', contrato),
            if (_contractInfo?.consumerName != null) ...[
              const SizedBox(height: 8),
              _buildConfirmRow('Titular:', _contractInfo!.consumerName!),
            ],
            const SizedBox(height: 8),
            _buildConfirmRow('Monto:', 'S/ ${monto.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            _buildConfirmRow(
              'Cuenta origen:',
              '${_cuentaSeleccionada!.tipo.toUpperCase()} (${_cuentaSeleccionada!.numero})',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('PAGAR'),
          ),
        ],
      ),
    );


    if (confirmed != true) return;


    setState(() => _loading = true);


    final firestore = context.read<FirestoreService>();
    final auth = context.read<AuthService>();
    final currentUser = auth.user;
    if (currentUser == null) return;


    final transaccion = TransaccionModel(
      transaccionId: '',
      userId: currentUser.uid,
      cuentaId: _cuentaSeleccionada!.cuentaId,
      descripcion: 'Pago $_servicio - Contrato: $contrato - ${_contractInfo?.consumerName ?? ''}',
      monto: monto,
      tipo: 'debito',
      fecha: DateTime.now(),
    );


    try {
      await firestore.registrarTransaccion(transaccion);


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Pago procesado exitosamente'),
            backgroundColor: AppColors.successGreen,
          ),
        );


        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmationScreen(
              servicio: _servicio,
              monto: monto,
              contrato: contrato,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar pago: ${e.toString()}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  Widget _buildConfirmRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGray, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final firestore = context.read<FirestoreService>();
    final currentUser = auth.user;


    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }


    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pagar Servicios', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<CuentaModel>>(
        stream: firestore.getCuentas(currentUser.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }


          final cuentas = snap.data ?? [];
          if (_cuentaSeleccionada == null && cuentas.isNotEmpty) {
            _cuentaSeleccionada = cuentas.firstWhere(
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
                  const Text('¿Qué servicio deseas pagar?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondaryBlue)),
                  const SizedBox(height: 20),


                  DropdownButtonFormField<String>(
                    value: _servicio,
                    decoration: InputDecoration(
                      labelText: 'Selecciona Servicio',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.electrical_services),
                    ),
                    items: _servicios.map((servicio) {
                      return DropdownMenuItem(
                        value: servicio,
                        child: Row(
                          children: [
                            Icon(_getServiceIcon(servicio), color: AppColors.primaryRed, size: 20),
                            const SizedBox(width: 12),
                            Text(servicio),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _servicio = value!;
                        _contratoController.clear();
                        _montoController.clear();
                        _contractInfo = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),


                  TextFormField(
                    controller: _contratoController,
                    decoration: InputDecoration(
                      labelText: 'Número de Contrato',
                      hintText: _getHintText(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.numbers),
                      suffixIcon: _verifying
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : (_contractInfo?.isValid == true
                              ? const Icon(Icons.check_circle, color: AppColors.successGreen)
                              : null),
                    ),
                    onChanged: (_) {
                      if (_contractInfo != null) setState(() => _contractInfo = null);
                    },
                    validator: (value) => ContractValidator.validateContract(_servicio, value ?? ''),
                  ),
                  const SizedBox(height: 12),


                  if (!_verifying)
                    TextButton.icon(
                      onPressed: _verifyContract,
                      icon: const Icon(Icons.verified, size: 18),
                      label: const Text('Verificar Contrato'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.secondaryBlue),
                    ),


                  if (_contractInfo != null && _contractInfo!.isValid) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.verified, color: AppColors.successGreen, size: 20),
                              const SizedBox(width: 8),
                              const Text('Contrato Verificado', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.successGreen)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_contractInfo!.consumerName != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text('Titular: ${_contractInfo!.consumerName}', style: const TextStyle(fontSize: 14)),
                            ),
                          if (_contractInfo!.dueDate != null)
                            Text('Fecha límite: ${_formatDate(_contractInfo!.dueDate!)}', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],


                  const SizedBox(height: 16),


                  TextFormField(
                    controller: _montoController,
                    decoration: InputDecoration(
                      labelText: 'Monto a Pagar (S/)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.attach_money),
                      hintText: '0.00',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ingrese un monto';
                      final monto = double.tryParse(value);
                      if (monto == null || monto <= 0) return 'Monto inválido';
                      if (_cuentaSeleccionada != null && monto > _cuentaSeleccionada!.saldo) {
                        return 'Saldo insuficiente';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),


                  const Text('Origen del pago', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGray)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CuentaModel>(
                    value: _cuentaSeleccionada,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.account_balance_wallet),
                    ),
                    items: cuentas.map((cuenta) {
                      return DropdownMenuItem(
                        value: cuenta,
                        child: Text('${cuenta.tipo.toUpperCase()} (${cuenta.numero}) - S/ ${cuenta.saldo.toStringAsFixed(2)}'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _cuentaSeleccionada = value),
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
                          : const Text('PROCEDER AL PAGO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
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


  IconData _getServiceIcon(String servicio) {
    switch (servicio) {
      case 'Agua': return Icons.water_drop;
      case 'Luz': return Icons.flash_on;
      case 'Cable': return Icons.tv;
      case 'Internet': return Icons.wifi;
      default: return Icons.receipt;
    }
  }


  String _getHintText() {
    switch (_servicio) {
      case 'Agua': return 'Ej: 12345678';
      case 'Luz': return 'Ej: EN12345678';
      case 'Cable': return 'Ej: 123456789';
      case 'Internet': return 'Ej: 1234567890';
      default: return 'Ingrese número de contrato';
    }
  }


  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
