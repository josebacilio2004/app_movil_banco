class OperadorModel {
  final String nombre;
  final String icono;
  final List<String> rangosNumeros;

  const OperadorModel({
    required this.nombre,
    required this.icono,
    required this.rangosNumeros,
  });

  static List<OperadorModel> getOperadores() {
    return [
      const OperadorModel(
        nombre: 'Movistar',
        icono: '📱',
        rangosNumeros: ['912', '913', '914', '915', '916', '917', '918', '919', '920'],
      ),
      const OperadorModel(
        nombre: 'Claro',
        icono: '📱',
        rangosNumeros: ['922', '923', '924', '925', '926', '927', '928', '929'],
      ),
      const OperadorModel(
        nombre: 'Entel',
        icono: '📱',
        rangosNumeros: ['950', '951', '952', '953', '954', '955', '956', '957', '958', '959'],
      ),
      const OperadorModel(
        nombre: 'Bitel',
        icono: '📱',
        rangosNumeros: ['970', '971', '972', '973', '974', '975', '976', '977', '978', '979'],
      ),
    ];
  }

  static OperadorModel? identificarOperador(String numero) {
    if (numero.length < 3) return null;
    final prefijo = numero.substring(0, 3);
    for (var operador in getOperadores()) {
      if (operador.rangosNumeros.contains(prefijo)) {
        return operador;
      }
    }
    return null;
  }
}