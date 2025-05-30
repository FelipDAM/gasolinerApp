class Gasolinera {
  final String? nombre;
  final String? ciudad;
  final String? horario;
  final double? latitud;
  final double? longitud;
  final double? precioGasoleoA;
  final double? precioGasoleoB;
  final double? precioGasoleoPremium;
  final double? precioGasolina95E5;
  final double? precioGasolina95E10;
  final double? precioGasolina95E5Premium;
  final double? precioGasolina98E5;
  final double? precioGasolina98E10;
  final double? precioBiodiesel;
  final double? precioBioetanol;


  Gasolinera({
    this.nombre,
    this.ciudad,
    this.horario,
    this.latitud,
    this.longitud,
    this.precioGasoleoA,
    this.precioGasoleoB,
    this.precioGasoleoPremium,
    this.precioGasolina95E5,
    this.precioGasolina95E10,
    this.precioGasolina95E5Premium,
    this.precioGasolina98E5,
    this.precioGasolina98E10,
    this.precioBiodiesel,
    this.precioBioetanol,
  });

  factory Gasolinera.fromJson(Map<String, dynamic> json) {
    return Gasolinera(
      nombre: json["Rótulo"],
      ciudad: json["Municipio"],
      horario: json["Horario"],
      latitud: _parseCoordenada(json["Latitud"]),
      longitud: _parseCoordenada(json["Longitud (WGS84)"]),
      precioGasoleoA: _parsePrecio(json["Precio Gasoleo A"]),
      precioGasoleoB: _parsePrecio(json["Precio Gasoleo B"]),
      precioGasoleoPremium: _parsePrecio(json["Precio Gasoleo Premium"]),
      precioGasolina95E5: _parsePrecio(json["Precio Gasolina 95 E5"]),
      precioGasolina95E10: _parsePrecio(json["Precio Gasolina 95 E10"]),
      precioGasolina95E5Premium: _parsePrecio(json["Precio Gasolina 95 E5 Premium"]),
      precioGasolina98E5: _parsePrecio(json["Precio Gasolina 98 E5"]),
      precioGasolina98E10: _parsePrecio(json["Precio Gasolina 98 E10"]),
      precioBiodiesel: _parsePrecio(json["Precio Biodiesel"]),
      precioBioetanol: _parsePrecio(json["Precio Bioetanol"]),

    );
  }

  static double? _parseCoordenada(String? valor) {
    if (valor == null || valor.isEmpty) return null;
    return double.tryParse(valor.replaceAll(',', '.'));
  }

  static double? _parsePrecio(String? valor) {
    if (valor == null || valor.isEmpty) return null;
    return double.tryParse(valor.replaceAll(',', '.'));
  }
}
