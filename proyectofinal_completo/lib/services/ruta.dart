import 'package:google_maps_webservice/directions.dart' as gmaps;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/gasolinera_model.dart';

class RutaService {
  final gmaps.GoogleMapsDirections _directions;

  RutaService(String apiKey)
      : _directions = gmaps.GoogleMapsDirections(apiKey: apiKey);

  Future<Position> obtenerUbicacionActual() async {
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      throw Exception('El servicio de ubicación está deshabilitado.');
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        throw Exception('Los permisos de ubicación están denegados.');
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      throw Exception('Los permisos están denegados permanentemente.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  Future<List<LatLng>> obtenerPuntosRuta(LatLng origen, LatLng destino) async {
    try {
      // <-- Usamos directionsWithLocation para pasar Location
      final response = await _directions.directionsWithLocation(
        gmaps.Location(lat: origen.latitude, lng: origen.longitude),
        gmaps.Location(lat: destino.latitude, lng: destino.longitude),
        travelMode: gmaps.TravelMode.driving,
      );

      if (!response.isOkay || response.routes.isEmpty) {
        throw Exception('No se pudo obtener la ruta: ${response.errorMessage}');
      }

      // Decodificar la polyline overview en puntos LatLng
      final encoded = response.routes.first.overviewPolyline.points;
      final rawPoints = PolylinePoints().decodePolyline(encoded);
      return rawPoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
    } catch (e) {
      throw Exception('Error al obtener los puntos de la ruta: $e');
    }
  }

  Future<Map<String, String>> calcularDistanciaYTiempoSolo(
      Gasolinera gasolinera) async {
    if (gasolinera.latitud == null || gasolinera.longitud == null) {
      throw Exception('Gasolinera sin coordenadas válidas');
    }

    try {
      final posicion = await obtenerUbicacionActual();
      final origen =
          gmaps.Location(lat: posicion.latitude, lng: posicion.longitude);
      final destino =
          gmaps.Location(lat: gasolinera.latitud!, lng: gasolinera.longitud!);

      final response = await _directions.directionsWithLocation(
        origen,
        destino,
        travelMode: gmaps.TravelMode.driving,
      );

      if (!response.isOkay || response.routes.isEmpty) {
        throw Exception(
            'No se pudo calcular distancia y tiempo: ${response.errorMessage}');
      }

      final leg = response.routes.first.legs.first;
      return {
        'distancia': leg.distance.text,
        'duracion': leg.duration.text,
      };
    } catch (e) {
      throw Exception('Error al calcular distancia y tiempo: $e');
    }
  }

  Future<void> mostrarRutaHaciaGasolinera(Gasolinera gasolinera) async {
    final lat = gasolinera.latitud;
    final lng = gasolinera.longitud;

    if (lat == null || lng == null) return;

    final googleMapsUrl = Uri.parse("google.navigation:q=$lat,$lng&mode=d");

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'No se pudo abrir la navegación en Google Maps';
    }
  }
}
