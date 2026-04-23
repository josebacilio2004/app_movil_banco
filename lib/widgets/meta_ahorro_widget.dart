import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class MetaAhorroWidget extends StatefulWidget {
  final double saldoActual;
  final double metaAhorro;
  final double tasaInteres; // Tasa anual (ej: 4.5 = 4.5%)
  final double depositoMensual;

  const MetaAhorroWidget({
    super.key,
    required this.saldoActual,
    required this.metaAhorro,
    required this.tasaInteres,
    required this.depositoMensual,
  });

  @override
  State<MetaAhorroWidget> createState() => _MetaAhorroWidgetState();
}

class _MetaAhorroWidgetState extends State<MetaAhorroWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  double _animatedProgress = 0.0;

  // Cálculo del porcentaje de avance
  double get _porcentaje {
    double pct = widget.saldoActual / widget.metaAhorro;
    return pct.clamp(0.0, 1.0);
  }

  // Cuánto falta para la meta
  double get _cuantoFalta {
    return (widget.metaAhorro - widget.saldoActual).clamp(0.0, double.infinity);
  }

  // Tasa de interés mensual
  double get _tasaMensual {
    return (widget.tasaInteres / 100) / 12;
  }

  // Calcular meses para alcanzar la meta
  int get _mesesParaMeta {
    if (_cuantoFalta <= 0) return 0;
    
    double saldo = widget.saldoActual;
    int meses = 0;
    int maxMeses = 120; // Máximo 10 años para evitar loops infinitos
    
    while (saldo < widget.metaAhorro && meses < maxMeses) {
      // Interés del mes
      double interes = saldo * _tasaMensual;
      // Nuevo saldo = saldo + interés + depósito mensual
      saldo = saldo + interes + widget.depositoMensual;
      meses++;
    }
    
    return meses;
  }

  // Tabla de proyección para los próximos 6 meses
  List<Map<String, dynamic>> get _tablaProyeccion {
    List<Map<String, dynamic>> tabla = [];
    double saldo = widget.saldoActual;
    int mesesMostrar = 6;
    
    for (int i = 1; i <= mesesMostrar; i++) {
      double interes = saldo * _tasaMensual;
      double deposito = widget.depositoMensual;
      double nuevoSaldo = saldo + interes + deposito;
      
      tabla.add({
        'mes': i,
        'deposito': deposito,
        'interes': interes,
        'saldoProyectado': nuevoSaldo,
      });
      
      saldo = nuevoSaldo;
    }
    
    return tabla;
  }

  // Mensaje motivacional según porcentaje
  String get _mensajeMotivacional {
    double pct = _porcentaje * 100;
    if (pct >= 75) {
      return '🎉 ¡Casi lo logras! Sigue así';
    } else if (pct >= 50) {
      return '🚀 ¡Vas muy bien! No pares';
    } else if (pct >= 25) {
      return '💪 ¡Buen comienzo! Cada sol cuenta';
    } else {
      return '💰 ¡Cada sol cuenta! Empieza hoy';
    }
  }

  String get _emojiMotivacional {
    double pct = _porcentaje * 100;
    if (pct >= 75) {
      return '🎉';
    } else if (pct >= 50) {
      return '🚀';
    } else if (pct >= 25) {
      return '💪';
    } else {
      return '💰';
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0, end: _porcentaje).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _animatedProgress = _progressAnimation.value;
        });
      });
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con emoji motivacional
          Row(
            children: [
              Text(
                _emojiMotivacional,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _mensajeMotivacional,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Porcentaje actual
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progreso de Meta',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                ),
              ),
              Text(
                '${(_porcentaje * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Barra de progreso animada (LinearProgressIndicator)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: LinearProgressIndicator(
              value: _animatedProgress,
              backgroundColor: AppColors.containerLow,
              color: AppColors.successGreen,
              minHeight: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Saldo actual vs Meta
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saldo actual',
                    style: TextStyle(fontSize: 12, color: AppColors.textGray),
                  ),
                  Text(
                    'S/ ${widget.saldoActual.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryRed,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Meta',
                    style: TextStyle(fontSize: 12, color: AppColors.textGray),
                  ),
                  Text(
                    'S/ ${widget.metaAhorro.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondaryBlue,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cuánto falta
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Te faltan',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  'S/ ${_cuantoFalta.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryRed,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Proyección de meses
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondaryBlue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📊 Proyección',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Alcanzarás tu meta en ${_mesesParaMeta} meses',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryBlue,
                  ),
                ),
                if (_mesesParaMeta > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '(aproximadamente: ${_calcularFechaEstimada(_mesesParaMeta)})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Tabla de proyección para los próximos 6 meses
          const Text(
            'TABLA DE PROYECCIÓN',
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
                columnSpacing: 16,
                headingRowColor: WidgetStateProperty.resolveWith(
                  (states) => AppColors.containerLow,
                ),
                columns: const [
                  DataColumn(label: Text('Mes', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Depósito', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Interés', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Saldo', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _tablaProyeccion.map((item) {
                  return DataRow(cells: [
                    DataCell(Text('${item['mes']}')),
                    DataCell(Text('S/ ${item['deposito']!.toStringAsFixed(2)}')),
                    DataCell(Text('S/ ${item['interes']!.toStringAsFixed(2)}')),
                    DataCell(Text('S/ ${item['saldoProyectado']!.toStringAsFixed(2)}')),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calcularFechaEstimada(int meses) {
    final ahora = DateTime.now();
    final fechaEstimada = DateTime(ahora.year, ahora.month + meses, ahora.day);
    return '${_nombreMes(fechaEstimada.month)} ${fechaEstimada.year}';
  }

  String _nombreMes(int mes) {
    const meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return meses[mes - 1];
  }
}