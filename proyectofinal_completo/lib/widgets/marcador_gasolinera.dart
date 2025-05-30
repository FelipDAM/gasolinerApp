import 'package:flutter/material.dart';
import '../models/gasolinera_model.dart';

class MarcadorGasolinera extends StatelessWidget {
  final Gasolinera gasolinera;
  final String tipoCombustible;

  const MarcadorGasolinera({
    required this.gasolinera,
    required this.tipoCombustible,
  });

  static double? obtenerPrecioGasolinera(
      Gasolinera g, String tipoCombustibleSeleccionado) {
    double? precio;
    switch (tipoCombustibleSeleccionado) {
      case 'Gasóleo A':
        precio = g.precioGasoleoA;
        break;
      case 'Gasóleo B':
        precio = g.precioGasoleoB;
        break;
      case 'Gasóleo Premium':
        precio = g.precioGasoleoPremium;
        break;
      case 'Gasolina 95 E5':
        precio = g.precioGasolina95E5;
        break;
      case 'Gasolina 95 E10':
        precio = g.precioGasolina95E10;
        break;
      case 'Gasolina 95 E5 Premium':
        precio = g.precioGasolina95E5Premium;
        break;
      case 'Gasolina 98 E5':
        precio = g.precioGasolina98E5;
        break;
      case 'Gasolina 98 E10':
        precio = g.precioGasolina98E10;
        break;
      case 'Biodiésel':
        precio = g.precioBiodiesel;
        break;
      case 'Bioetanol':
        precio = g.precioBioetanol;
        break;
    }
    return precio;
  }

  @override
  Widget build(BuildContext context) {
    final precio = obtenerPrecioGasolinera(gasolinera, tipoCombustible);

    return Container(
      width: 90,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.local_gas_station_rounded,
            color: Colors.blue,
            size: 22.0,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  precio != null ? '${precio.toStringAsFixed(2)} €' : '--',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: precio != null ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
