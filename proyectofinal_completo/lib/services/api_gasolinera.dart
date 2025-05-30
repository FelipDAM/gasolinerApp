import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gasolinera_model.dart';

class ApiService {
  static const String apiUrl =
      'https://sedeaplicaciones.minetur.gob.es/ServiciosRESTCarburantes/PreciosCarburantes/EstacionesTerrestres';

  static Future<List<Gasolinera>> fetchGasolineras() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded['ListaEESSPrecio'] != null) {
          final List estaciones = decoded['ListaEESSPrecio'];
          
          if (estaciones.isEmpty) {
            return [];
          }

          return estaciones.map((jsonItem) => Gasolinera.fromJson(jsonItem)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Error al cargar los datos: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }
}
