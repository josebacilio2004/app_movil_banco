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
  bool _submitted = false;

  final List<String> _servicios = ['Agua', 'Luz', 'Cable', 'Internet'];

  // ✓ CRITERIO 2: Validación en tiempo real para habilitar botón
  bool get _isFormValid {
    // Validar servicio
    if (_servicio.isEmpty) return false;
    
    // Validar contrato
    final contrato = _contratoController.text.trim();
    final contractError = ContractValidator.validateContract(_servicio, contrato);
    if (contractError != null) return false;
    if (contrato.isEmpty) return false;
    
    // Validar monto
    final montoText = _montoController.text.trim();
    if (montoText.isEmpty) return false;
    final monto = double.tryParse(montoText);
    if (monto == null || monto <= 0) return false;
    
    // Validar cuenta seleccionada
    if (_cuentaSeleccionada == null) return false;
    
    // Validar saldo suficiente
    if (monto > _cuentaSeleccionada!.saldo) return false;
    
    return true;
  }

  // ✓ CRITERIO 4: Obtener texto del resumen
  String get _resumenServicio => _servicio;
  String get _resumenContrato => _contratoController.text.trim();
  String get _resumenMonto {
    final monto = double.tryParse(_montoController.text.trim());
    if (monto == null) return 'S/ 0.00';
    return 'S/ ${monto.toStringAsFixed(2)}';
  }

  @override
  void dispose() {
    _contratoController.dispose();
    _montoController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    setState(() => _submitted = true);
    
    // Validar formulario
    if (!_formKey.currentState!.validate()) return;
    
    // ✓ CRITERIO 5: SnackBar de confirmación (BONUS)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Listo para confirmar'),
        backgroundColor: AppColors.successGreen,
        duration: Duration(seconds: 2),
      ),
    );
    
    _confirmarPago();
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
    final monto = double.parse(_montoController.text);
    final contrato = _contratoController.text.trim();

    if (_cuentaSeleccionada!.saldo < monto) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saldo insuficiente. Disponible: S/ ${_cuentaSeleccionada!.saldo.toStringAsFixed(2)}'),
          backgroundColor: AppColors.errorRed,
        ),
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
      descripcion: 'Pago $_servicio - Contrato: $contrato - ${_contractInfo?.consumerName ?? ''}',
      monto: monto,
      tipo: 'debito',
      fecha: DateTime.now(),
    );

    try {
      await firestore.registrarTransaccion(transaccion);

      if (mounted) {
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
              autovalidateMode: _submitted 
                  ? AutovalidateMode.onUserInteraction 
                  : AutovalidateMode.disabled,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Servicio
                  const Text('¿Qué servicio deseas pagar?', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondaryBlue)),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _servicio,
                    decoration: InputDecoration(
                      labelText: 'Selecciona Servicio',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.electrical_services),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
                      ),
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
                    validator: (value) {
                      if (_submitted && (value == null || value.isEmpty)) {
                        return 'Seleccione un servicio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Contrato
                  TextFormField(
                    controller: _contratoController,
                    decoration: InputDecoration(
                      labelText: 'Número de Contrato',
                      hintText: _getHintText(),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.numbers),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
                      ),
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
                    validator: (value) {
                      if (_submitted) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese un número de contrato';
                        }
                        return ContractValidator.validateContract(_servicio, value);
                      }
                      return null;
                    },
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
                              const Text('Contrato Verificado', 
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.successGreen)),
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

                  // Monto
                  TextFormField(
                    controller: _montoController,
                    decoration: InputDecoration(
                      labelText: 'Monto a Pagar (S/)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.attach_money),
                      hintText: '0.00',
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (_submitted) {
                        if (value == null || value.isEmpty) {
                          return 'Ingrese un monto';
                        }
                        final monto = double.tryParse(value);
                        if (monto == null || monto <= 0) {
                          return 'Monto inválido';
                        }
                        if (_cuentaSeleccionada != null && monto > _cuentaSeleccionada!.saldo) {
                          return 'Saldo insuficiente';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Origen del pago
                  const Text('Origen del pago', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGray)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<CuentaModel>(
                    value: _cuentaSeleccionada,
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.account_balance_wallet),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
                      ),
                    ),
                    items: cuentas.map((cuenta) {
                      return DropdownMenuItem(
                        value: cuenta,
                        child: Text('${cuenta.tipo.toUpperCase()} (${cuenta.numero}) - S/ ${cuenta.saldo.toStringAsFixed(2)}'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _cuentaSeleccionada = value),
                    validator: (value) {
                      if (_submitted && value == null) {
                        return 'Seleccione una cuenta';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // ✓ CRITERIO 4: Card de resumen (aparece SOLO cuando formulario es válido)
                  if (_isFormValid) ...[
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: AppColors.secondaryBlue.withOpacity(0.05),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('RESUMEN DEL PAGO',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.secondaryBlue)),
                            const SizedBox(height: 12),
                            _buildConfirmRow('Servicio:', _resumenServicio),
                            const SizedBox(height: 8),
                            _buildConfirmRow('Contrato:', _resumenContrato),
                            const SizedBox(height: 8),
                            _buildConfirmRow('Monto:', _resumenMonto),
                            if (_cuentaSeleccionada != null) ...[
                              const SizedBox(height: 8),
                              _buildConfirmRow('Cuenta origen:', 
                                '${_cuentaSeleccionada!.tipo.toUpperCase()} (${_cuentaSeleccionada!.numero})'),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ✓ CRITERIO 2: Botón deshabilitado hasta que formulario sea válido
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isFormValid && !_loading ? _onSubmit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 4,
                        disabledBackgroundColor: AppColors.primaryRed.withOpacity(0.4),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('PAGAR', 
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
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