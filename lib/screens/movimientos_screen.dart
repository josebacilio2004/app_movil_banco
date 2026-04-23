import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/transaccion.dart';
import '../utils/constants.dart';

class MovimientosScreen extends StatefulWidget {
  const MovimientosScreen({super.key});

  @override
  State<MovimientosScreen> createState() => _MovimientosScreenState();
}

class _MovimientosScreenState extends State<MovimientosScreen> {
  String _filtroActual = 'todos'; // 'todos', 'debito', 'credito'

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
          'Movimientos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<TransaccionModel>>(
        stream: firestore.getTransacciones(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 64,
                    color: AppColors.outline.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay movimientos',
                    style: TextStyle(
                      color: AppColors.textGray,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final transacciones = snapshot.data!;
          
          // Calcular contadores (sin setState)
          final totalDebitos = transacciones.where((t) => t.tipo == 'debito').length;
          final totalCreditos = transacciones.where((t) => t.tipo == 'credito').length;
          
          // Filtrar según selección
          List<TransaccionModel> movimientosFiltrados = [];
          if (_filtroActual == 'debito') {
            movimientosFiltrados = transacciones.where((t) => t.tipo == 'debito').toList();
          } else if (_filtroActual == 'credito') {
            movimientosFiltrados = transacciones.where((t) => t.tipo == 'credito').toList();
          } else {
            movimientosFiltrados = transacciones;
          }

          return Column(
            children: [
              // Contador de débitos y créditos
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildContadorItem(
                      label: 'Débitos',
                      cantidad: totalDebitos,
                      color: AppColors.primaryRed,
                      icon: Icons.arrow_downward,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: AppColors.outline.withOpacity(0.3),
                    ),
                    _buildContadorItem(
                      label: 'Créditos',
                      cantidad: totalCreditos,
                      color: AppColors.successGreen,
                      icon: Icons.arrow_upward,
                    ),
                  ],
                ),
              ),
              
              // Filtros
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFiltroChip('Todos', 'todos'),
                    const SizedBox(width: 12),
                    _buildFiltroChip('Débitos', 'debito'),
                    const SizedBox(width: 12),
                    _buildFiltroChip('Créditos', 'credito'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Lista de movimientos
              Expanded(
                child: movimientosFiltrados.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history_toggle_off,
                              size: 64,
                              color: AppColors.outline.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay movimientos de este tipo',
                              style: TextStyle(
                                color: AppColors.textGray,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: movimientosFiltrados.length,
                        itemBuilder: (context, index) {
                          final movimiento = movimientosFiltrados[index];
                          return Column(
                            children: [
                              _buildItemMovimiento(movimiento),
                              if (index < movimientosFiltrados.length - 1)
                                Divider(
                                  color: AppColors.outline.withOpacity(0.2),
                                  height: 1,
                                ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContadorItem({
    required String label,
    required int cantidad,
    required Color color,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textGray,
              ),
            ),
            Text(
              cantidad.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFiltroChip(String label, String filtro) {
    final isSelected = _filtroActual == filtro;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filtroActual = filtro;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryRed : AppColors.containerLow,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.secondaryBlue,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemMovimiento(TransaccionModel transaccion) {
    final isDebito = transaccion.tipo == 'debito';
    final colorMonto = isDebito ? AppColors.primaryRed : AppColors.successGreen;
    final prefijo = isDebito ? '- S/ ' : '+ S/ ';
    final icono = isDebito ? Icons.arrow_downward : Icons.arrow_upward;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Icono circular
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorMonto.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icono,
              color: colorMonto,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // Descripción y fecha
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaccion.descripcion,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryBlue,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatearFecha(transaccion.fecha),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGray.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          
          // Monto coloreado con prefijo
          Text(
            '$prefijo${transaccion.monto.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorMonto,
            ),
          ),
        ],
      ),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final fechaComparar = DateTime(fecha.year, fecha.month, fecha.day);

    if (fechaComparar == today) {
      return 'Hoy';
    } else if (fechaComparar == yesterday) {
      return 'Ayer';
    } else {
      return DateFormat('dd/MM/yyyy').format(fecha);
    }
  }
}