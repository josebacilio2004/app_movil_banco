import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/cuenta.dart';
import '../models/user.dart';
import '../utils/constants.dart';
import '../widgets/meta_ahorro_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaccion.dart';

class AhorroScreen extends StatefulWidget {
  const AhorroScreen({super.key});

  @override
  State<AhorroScreen> createState() => _AhorroScreenState();
}

class _AhorroScreenState extends State<AhorroScreen> {
  final TextEditingController _depositoController = TextEditingController();
  
  @override
  void dispose() {
    _depositoController.dispose();
    super.dispose();
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Cuenta de Ahorro',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<UserModel?>(
        stream: firestore.getUser(currentUser.uid),
        builder: (context, userSnap) {
          if (!userSnap.hasData || userSnap.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final user = userSnap.data!;
          
          return StreamBuilder<List<CuentaModel>>(
            stream: firestore.getCuentas(currentUser.uid),
            builder: (context, snap) {
              if (!snap.hasData || snap.data!.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              
              // Buscar cuenta de ahorro
              final cuentaAhorro = snap.data!.firstWhere(
                (c) => c.tipo == 'ahorro',
                orElse: () => snap.data!.first,
              );
              
              // Si no tiene meta de ahorro, usar valores por defecto
              final meta = cuentaAhorro.metaAhorro ?? 20000.0;
              final saldo = cuentaAhorro.saldo;
              final porcentaje = (saldo / meta).clamp(0.0, 1.0);
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta de progreso
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: AppColors.bcpGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryRed.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Meta Viaje Francia',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Dic 2025',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                children: [
                                  const Text(
                                    'Ahorrado',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  Text(
                                    'S/ ${saldo.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                children: [
                                  const Text(
                                    'Meta',
                                    style: TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  Text(
                                    'S/ ${meta.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: porcentaje,
                              backgroundColor: Colors.white24,
                              color: AppColors.successGreen,
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(porcentaje * 100).toStringAsFixed(1)}% completado',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                'Faltan S/ ${(meta - saldo).toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '¡Sigue asii! ',
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                ),
                                const Text(
                                  '🎉',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Proyección
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Alcanzarás tu meta en',
                            style: TextStyle(color: AppColors.textGray, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '14 meses',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryRed,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Aprox. Jun 2027',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondaryBlue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.containerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Depósito mensual: S/ 500 + interés 3.5% anual'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tabla de proyección
                    const Text(
                      'PROYECCIÓN PRÓXIMOS 6 MESES',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: AppColors.secondaryBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 20,
                          headingRowColor: WidgetStateProperty.resolveWith(
                            (states) => AppColors.containerLow,
                          ),
                          columns: const [
                            DataColumn(label: Text('Mes', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Depósito', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Interés', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Saldo', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: [
                            DataRow(cells: [
                              DataCell(const Text('1')),
                              DataCell(Text('S/ 500')),
                              DataCell(Text('S/ 38')),
                              DataCell(Text('S/ 13,413')),
                            ]),
                            DataRow(cells: [
                              DataCell(const Text('2')),
                              DataCell(Text('S/ 500')),
                              DataCell(Text('S/ 39')),
                              DataCell(Text('S/ 13,952')),
                            ]),
                            DataRow(cells: [
                              DataCell(const Text('3')),
                              DataCell(Text('S/ 500')),
                              DataCell(Text('S/ 41')),
                              DataCell(Text('S/ 14,492')),
                            ]),
                            DataRow(cells: [
                              DataCell(const Text('4')),
                              DataCell(Text('S/ 500')),
                              DataCell(Text('S/ 42')),
                              DataCell(Text('S/ 15,035')),
                            ]),
                            DataRow(cells: [
                              DataCell(const Text('5')),
                              DataCell(Text('S/ 500')),
                              DataCell(Text('S/ 44')),
                              DataCell(Text('S/ 15,578')),
                            ]),
                            DataRow(cells: [
                              DataCell(const Text('6')),
                              DataCell(Text('S/ 500')),
                              DataCell(Text('S/ 45')),
                              DataCell(Text('S/ 16,124')),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Abonar a la meta
                    const Text(
                      'ABONAR A LA META',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                        color: AppColors.secondaryBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Monto a depositar (S/)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textGray,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _depositoController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '0.00',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primaryRed),
                              ),
                              prefixIcon: const Icon(Icons.attach_money),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_depositoController.text.isNotEmpty) {
                                  _confirmarDeposito(context, cuentaAhorro, double.parse(_depositoController.text), firestore, currentUser.uid);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                '+ DEPOSITAR',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmarDeposito(BuildContext context, CuentaModel cuenta, double monto, FirestoreService firestore, String userId) {
  // Verificar que el monto sea válido
  if (monto <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ingrese un monto válido'),
        backgroundColor: AppColors.errorRed,
      ),
    );
    return;
  }

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Confirmar depósito'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConfirmRow('Meta:', 'Meta Viaje Europa'),
          const SizedBox(height: 8),
          _buildConfirmRow('Depósito:', 'S/ ${monto.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _buildConfirmRow('Nuevo saldo:', 'S/ ${(cuenta.saldo + monto).toStringAsFixed(2)}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            
            try {
              // Actualizar saldo en Firestore usando el método correcto
              await firestore.registrarTransaccion(
                TransaccionModel(
                  transaccionId: '',
                  userId: userId,
                  cuentaId: cuenta.cuentaId,
                  descripcion: 'Depósito a meta de ahorro - Viaje Europa',
                  monto: monto,
                  tipo: 'credito',
                  fecha: DateTime.now(),
                ),
              );
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Depósito realizado exitosamente'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
                _depositoController.clear();
                // Recargar la pantalla para mostrar el nuevo saldo
                setState(() {});
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al realizar depósito: $e'),
                    backgroundColor: AppColors.errorRed,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryRed,
            foregroundColor: Colors.white,
          ),
          child: const Text('CONFIRMAR'),
        ),
      ],
    ),
  );
}

  Widget _buildConfirmRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textGray)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}