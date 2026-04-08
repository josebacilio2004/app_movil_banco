class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'El correo es obligatorio';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Correo inválido';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) return 'Ingrese un monto';
    final n = double.tryParse(value);
    if (n == null || n <= 0) return 'Monto inválido';
    return null;
  }

  static String? validateContract(String? value) {
    if (value == null || value.isEmpty) return 'Ingrese nro de contrato';
    if (value.length < 6) return 'Mínimo 6 dígitos';
    return null;
  }
}
