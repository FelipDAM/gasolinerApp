import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../models/gasolinera_model.dart';

class Distancia {
  static List<Gasolinera> filtrarGasolineras({
    required List<Gasolinera> lista,
    required gmaps.LatLng centro,
    required double radioKm,
  }) {
    final List<Gasolinera> gasolinerasCercanas = [];

    for (var g in lista) {
      if (g.latitud != null && g.longitud != null) {
        final double distancia = Geolocator.distanceBetween(
          centro.latitude,
          centro.longitude,
          g.latitud!,
          g.longitud!,
        );

        if (distancia <= radioKm * 1000) {
          gasolinerasCercanas.add(g);
        }
      }
    }

    return gasolinerasCercanas;
  }
  
}
