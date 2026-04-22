import 'package:flutter/material.dart';


class ContractValidator {
  // Reglas de validación por tipo de servicio
  static String? validateContract(String servicio, String contrato) {
    if (contrato.isEmpty) {
      return 'Número de contrato requerido';
    }


    switch (servicio) {
      case 'Agua':
        // Formato SEDAPAL: 8-10 dígitos numéricos
        if (!RegExp(r'^\d{8,10}$').hasMatch(contrato)) {
          return 'Contrato de agua debe tener 8-10 dígitos numéricos';
        }
        break;


      case 'Luz':
        // Formato: 2 letras + 8-10 dígitos (ej: EN12345678)
        if (!RegExp(r'^[A-Z]{2}\d{8,10}$', caseSensitive: false).hasMatch(contrato)) {
          return 'Formato inválido: 2 letras + 8-10 dígitos (ej: EN12345678)';
        }
        break;


      case 'Cable':
        // Formato: 9-12 dígitos numéricos
        if (!RegExp(r'^\d{9,12}$').hasMatch(contrato)) {
          return 'Contrato de cable debe tener 9-12 dígitos numéricos';
        }
        break;


      case 'Internet':
        // Formato: 10-15 dígitos numéricos
        if (!RegExp(r'^\d{10,15}$').hasMatch(contrato)) {
          return 'Contrato de internet debe tener 10-15 dígitos numéricos';
        }
        break;


      default:
        return null;
    }
    return null;
  }


  // Verificar contrato con el proveedor (simulación)
  static Future<ContractInfo> verifyWithProvider(
    String servicio,
    String contrato,
  ) async {
    await Future.delayed(const Duration(milliseconds: 600));


    final formatError = validateContract(servicio, contrato);
    if (formatError != null) {
      return ContractInfo(
        isValid: false,
        message: formatError,
        consumerName: null,
        amountDue: null,
        dueDate: null,
      );
    }


    // Contratos de prueba válidos
    final testContracts = {
      'Agua': ['12345678', '87654321', '1122334455'],
      'Luz': ['EN12345678', 'ED12345678', 'LN11223344'],
      'Cable': ['123456789', '987654321', '555666777888'],
      'Internet': ['1234567890', '0987654321', '111222333444'],
    };


    final validContracts = testContracts[servicio] ?? [];
    final isValid = validContracts.contains(contrato.toUpperCase());


    if (isValid) {
      return ContractInfo(
        isValid: true,
        message: 'Contrato verificado correctamente',
        consumerName: _generateConsumerName(servicio),
        amountDue: _generateAmountDue(servicio),
        dueDate: DateTime.now().add(const Duration(days: 7)),
      );
    } else {
      return ContractInfo(
        isValid: false,
        message: 'Número de contrato no encontrado o inactivo',
        consumerName: null,
        amountDue: null,
        dueDate: null,
      );
    }
  }


  static String _generateConsumerName(String servicio) {
    final names = {
      'Agua': 'JUAN CARLOS PEREZ GARCIA',
      'Luz': 'MARIA ELENA LOPEZ TORRES',
      'Cable': 'CARLOS ANDRES RAMIREZ MENDOZA',
      'Internet': 'ANA CECILIA GONZALES FLORES',
    };
    return names[servicio] ?? 'TITULAR DEL SERVICIO';
  }


  static double _generateAmountDue(String servicio) {
    final amounts = {
      'Agua': 85.50,
      'Luz': 124.30,
      'Cable': 89.90,
      'Internet': 99.00,
    };
    return amounts[servicio] ?? 100.00;
  }
}


class ContractInfo {
  final bool isValid;
  final String message;
  final String? consumerName;
  final double? amountDue;
  final DateTime? dueDate;


  ContractInfo({
    required this.isValid,
    required this.message,
    this.consumerName,
    this.amountDue,
    this.dueDate,
  });
}
