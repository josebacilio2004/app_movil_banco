import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class LoanSimulatorScreen extends StatefulWidget {
  const LoanSimulatorScreen({super.key});

  @override
  State<LoanSimulatorScreen> createState() => _LoanSimulatorScreenState();
}

class _LoanSimulatorScreenState extends State<LoanSimulatorScreen> {
  // Variables del simulador
  double _monto = 5000.0;
  int _plazoMeses = 12;
  double _tasaAnual = 24.0;

  // Opciones
  final List<int> _plazos = [6, 12, 18, 24, 36, 48];
  final List<double> _tasas = [18.0, 24.0, 30.0, 36.0];

  // Resultados
  double _cuotaMensual = 0.0;
  double _totalPagar = 0.0;
  double _interesTotal = 0.0;
  List<Map<String, double>> _tablaAmortizacion = [];

  // ✓ Fórmula de amortización francesa
  double calcularCuota(double monto, int plazoMeses, double tasaAnual) {
    double r = (tasaAnual / 100) / 12;
    if (r == 0) return monto / plazoMeses;
    
    double factor = (r * pow(1 + r, plazoMeses)) / (pow(1 + r, plazoMeses) - 1);
    return monto * factor;
  }

  // ✓ Calcular tabla de amortización (primeras 6 cuotas)
  List<Map<String, double>> calcularTablaAmortizacion(
    double monto, 
    int plazoMeses, 
    double tasaAnual, 
    double cuotaMensual
  ) {
    List<Map<String, double>> tabla = [];
    double saldoRestante = monto;
    double r = (tasaAnual / 100) / 12;
    
    int cuotasMostrar = plazoMeses < 6 ? plazoMeses : 6;
    
    for (int mes = 1; mes <= cuotasMostrar; mes++) {
      double interesMes = saldoRestante * r;
      double capitalAmortizado = cuotaMensual - interesMes;
      saldoRestante -= capitalAmortizado;
      
      tabla.add({
        'mes': mes.toDouble(),
        'cuota': cuotaMensual,
        'capital': capitalAmortizado,
        'interes': interesMes,
      });
    }
    return tabla;
  }

  void _actualizarResultados() {
    setState(() {
      _cuotaMensual = calcularCuota(_monto, _plazoMeses, _tasaAnual);
      _totalPagar = _cuotaMensual * _plazoMeses;
      _interesTotal = _totalPagar - _monto;
      _tablaAmortizacion = calcularTablaAmortizacion(
        _monto, 
        _plazoMeses, 
        _tasaAnual, 
        _cuotaMensual
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _actualizarResultados();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Simulador de Préstamo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✓ Card de Cuota Mensual (como en la imagen)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
                    'CUOTA MENSUAL ESTIMADA',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'S/ ${_cuotaMensual.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'por $_plazoMeses meses',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ✓ Slider de Monto
            const Text(
              'MONTO DEL PRÉSTAMO',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.secondaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'S/ ${_monto.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryRed,
              ),
            ),
            Slider(
              value: _monto,
              min: 1000,
              max: 50000,
              divisions: 49,
              activeColor: AppColors.primaryRed,
              inactiveColor: AppColors.containerLow,
              onChanged: (value) {
                setState(() {
                  _monto = value;
                  _actualizarResultados();
                });
              },
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('S/ 1,000', style: TextStyle(fontSize: 12)),
                Text('S/ 50,000', style: TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 24),

            // ✓ Chips de Plazo (horizontal scroll como en la imagen)
            const Text(
              'PLAZO',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.secondaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _plazos.map((plazo) {
                  bool isSelected = _plazoMeses == plazo;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text('${plazo}m'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _plazoMeses = plazo;
                            _actualizarResultados();
                          });
                        }
                      },
                      backgroundColor: AppColors.containerLow,
                      selectedColor: AppColors.primaryRed,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.secondaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: StadiumBorder(
                        side: isSelected 
                            ? BorderSide.none 
                            : BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // ✓ Chips de Tasa Anual
            const Text(
              'TASA ANUAL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.secondaryBlue,
              ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _tasas.map((tasa) {
                  bool isSelected = _tasaAnual == tasa;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: FilterChip(
                      label: Text('${tasa.toStringAsFixed(0)}%'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _tasaAnual = tasa;
                            _actualizarResultados();
                          });
                        }
                      },
                      backgroundColor: AppColors.containerLow,
                      selectedColor: AppColors.primaryRed,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.secondaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                      shape: StadiumBorder(
                        side: isSelected 
                            ? BorderSide.none 
                            : BorderSide(color: AppColors.outline.withValues(alpha: 0.3)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),

            // ✓ Card de Resumen con tabla (como en la imagen)
            Container(
              width: double.infinity,
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
                  // Encabezado Resumen
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBlue.withValues(alpha: 0.05),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'RESUMEN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.secondaryBlue,
                      ),
                    ),
                  ),
                  
                  // Tabla de amortización
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.all(16),
                    child: DataTable(
                      columnSpacing: 20,
                      headingRowColor: WidgetStateProperty.resolveWith(
                        (states) => AppColors.containerLow,
                      ),
                      columns: const [
                        DataColumn(label: Text('Mes', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Cuota', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Capital', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Interés', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: _tablaAmortizacion.map((fila) {
                        return DataRow(cells: [
                          DataCell(Text(fila['mes']!.toInt().toString())),
                          DataCell(Text('S/ ${fila['cuota']!.toStringAsFixed(0)}')),
                          DataCell(Text('S/ ${fila['capital']!.toStringAsFixed(0)}')),
                          DataCell(Text('S/ ${fila['interes']!.toStringAsFixed(0)}')),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ✓ Botón Solicitar préstamo
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text(
                        'Solicitar Préstamo',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Monto: S/ ${_monto.toStringAsFixed(0)}'),
                          const SizedBox(height: 8),
                          Text('Plazo: $_plazoMeses meses'),
                          const SizedBox(height: 8),
                          Text('Cuota mensual: S/ ${_cuotaMensual.toStringAsFixed(2)}'),
                          const SizedBox(height: 16),
                          const Text(
                            '¿Deseas continuar con la solicitud?',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCELAR'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✓ Solicitud enviada correctamente'),
                                backgroundColor: AppColors.successGreen,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryRed,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('SOLICITAR'),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'SOLICITAR PRÉSTAMO',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}