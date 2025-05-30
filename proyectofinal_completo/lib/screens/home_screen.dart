import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/rendering.dart';
import '../services/ruta.dart';
import '../widgets/search_bar.dart' as custom;
import '../widgets/combustible_selector.dart' as combustible;
import '../services/api_gasolinera.dart';
import '../models/gasolinera_model.dart';
import '../utils/distancia.dart';
import '../widgets/marcador_gasolinera.dart';
import '../widgets/filtro_selector.dart';

class MapaScreen extends StatefulWidget {
  @override
  _MapaScreenState createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  late GoogleMapController mapController;
  bool _ordenarPorPrecio = true;
  bool _rutaActiva = false;
  LatLng? _destinoRuta;
  String? _distancia;
  String? _duracion;
  Gasolinera? _gasolineraSeleccionada;
  late RutaService _rutaService;
  bool _hayPredicciones = false;
  String tipoCombustibleSeleccionado = 'Gasóleo A';
  Set<Marker> _marcadores = {};

  List<Gasolinera> _gasolineras = [];
  List<Gasolinera> _gasolinerasRuta = [];
  List<Gasolinera> _gasolinerasRutaOriginal = [];
  Map<String, String> _distancias = {};

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    _rutaService = RutaService(dotenv.env['GOOGLE_MAPS_API_KEY']!);
    _cargarGasolineras();
  }

  Future<void> _cargarGasolineras() async {
    try {
      final posicion = await _rutaService.obtenerUbicacionActual();
      final LatLng ubicacionActual =
          LatLng(posicion.latitude, posicion.longitude);

      final gasolineras = await ApiService.fetchGasolineras();
      final gasolinerasFiltradas = Distancia.filtrarGasolineras(
        lista: gasolineras,
        centro: ubicacionActual,
        radioKm: 20,
      );

      final nuevosMarcadores = await crearMarcadoresGasolineras(
          gasolinerasFiltradas, tipoCombustibleSeleccionado);

      setState(() {
        _gasolineras = gasolinerasFiltradas;
        _marcadores = nuevosMarcadores;
      });
    } catch (e) {
      print('Error al cargar gasolineras con ubicación: $e');
    }
  }

  Future<Set<Marker>> crearMarcadoresGasolineras(
      List<Gasolinera> gasolinerasFiltradas,
      String tipoCombustibleSeleccionado) async {
    final Set<Marker> nuevosMarcadores = {};

    for (var g in gasolinerasFiltradas) {
      if (g.latitud != null && g.longitud != null) {
        double? precio = MarcadorGasolinera.obtenerPrecioGasolinera(
            g, tipoCombustibleSeleccionado);

        if (precio == null) continue;

        final widget = MarcadorGasolinera(
          gasolinera: g,
          tipoCombustible: tipoCombustibleSeleccionado,
        );

        final bytes = await _getBytesFromWidget(widget, width: 130, height: 80);

        nuevosMarcadores.add(
          Marker(
            markerId: MarkerId('${g.latitud},${g.longitud}'),
            position: LatLng(g.latitud!, g.longitud!),
            icon: BitmapDescriptor.fromBytes(bytes),
            onTap: () async {
              setState(() {
                _gasolineraSeleccionada = g;
                _distancia = null;
                _duracion = null;
              });

              WidgetsBinding.instance.addPostFrameCallback((_) {
                _sheetController.animateTo(
                  0.42,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              });

              try {
                final resultado =
                    await _rutaService.calcularDistanciaYTiempoSolo(g);
                setState(() {
                  _distancia = resultado['distancia'];
                  _duracion = resultado['duracion'];
                });
              } catch (e) {
                print('Error al obtener distancia y tiempo: $e');
              }
            },
          ),
        );
      }
    }

    return nuevosMarcadores;
  }

  Future<String> _loadMapStyle() async {
    return await rootBundle.loadString('lib/config/places.json');
  }

  void _onMapCreated(GoogleMapController controller) async {
    mapController = controller;
    try {
      final posicion = await _rutaService.obtenerUbicacionActual();
      final LatLng ubicacion = LatLng(posicion.latitude, posicion.longitude);

      mapController.animateCamera(CameraUpdate.newLatLngZoom(ubicacion, 15));
    } catch (e) {
      print('Error al obtenir la ubicació inicial: $e');
    }

    _loadMapStyle().then((style) {
      mapController.setMapStyle(style);
    }).catchError((e) {
      print("Error al carregar l'estil del mapa: $e");
    });
  }

  Future<Uint8List> _getBytesFromWidget(Widget widget,
      {int width = 150, int height = 100}) async {
    final repaintBoundary = RenderRepaintBoundary();
    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());

    final flutterView = WidgetsBinding.instance.platformDispatcher.views.first;
    final renderView = RenderView(
      view: flutterView,
      child: RenderPositionedBox(
        alignment: Alignment.center,
        child: repaintBoundary,
      ),
      configuration: ViewConfiguration(
        physicalConstraints:
            BoxConstraints.tight(Size(width.toDouble(), height.toDouble())),
        logicalConstraints:
            BoxConstraints.tight(Size(width.toDouble(), height.toDouble())),
        devicePixelRatio: flutterView.devicePixelRatio,
      ),
    );

    pipelineOwner.rootNode = renderView;
    final renderObjectToWidgetAdapter = RenderObjectToWidgetAdapter<RenderBox>(
      container: repaintBoundary,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
    );

    renderView.prepareInitialFrame();
    final rootElement =
        renderObjectToWidgetAdapter.attachToRenderTree(buildOwner);
    buildOwner.buildScope(rootElement);
    buildOwner.finalizeTree();

    pipelineOwner.flushLayout();
    pipelineOwner.flushCompositingBits();
    pipelineOwner.flushPaint();

    final image = await repaintBoundary.toImage(
        pixelRatio: renderView.configuration.devicePixelRatio);
    final byteData = await image.toByteData(format: ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _filtrarGasolinerasPorCombustible() {
    final filtradas = _gasolinerasRutaOriginal.where((g) {
      final precio = MarcadorGasolinera.obtenerPrecioGasolinera(
          g, tipoCombustibleSeleccionado);
      return precio != null;
    }).toList();

    if (_ordenarPorPrecio) {
      filtradas.sort((a, b) {
        final precioA = MarcadorGasolinera.obtenerPrecioGasolinera(
                a, tipoCombustibleSeleccionado) ??
            double.infinity;
        final precioB = MarcadorGasolinera.obtenerPrecioGasolinera(
                b, tipoCombustibleSeleccionado) ??
            double.infinity;
        return precioA.compareTo(precioB);
      });
    } else {
      filtradas.sort((a, b) {
        final keyA = '${a.latitud}_${a.longitud}';
        final keyB = '${b.latitud}_${b.longitud}';
        final distanciaA = _distancias[keyA];
        final distanciaB = _distancias[keyB];

        if (distanciaA == null) return 1;
        if (distanciaB == null) return -1;

        final kmA =
            double.tryParse(distanciaA.split(' ')[0].replaceAll(',', '.')) ??
                double.infinity;
        final kmB =
            double.tryParse(distanciaB.split(' ')[0].replaceAll(',', '.')) ??
                double.infinity;

        return kmA.compareTo(kmB);
      });
    }

    setState(() {
      _gasolinerasRuta = filtradas;
      _rutaActiva = true;
      _gasolineraSeleccionada = null;
    });
  }

  Future<void> _calcularKmLista() async {
    Map<String, String> nuevasDistancias = {};

    for (final gasolinera in _gasolinerasRuta) {
      final key = '${gasolinera.latitud}_${gasolinera.longitud}';

      if (!_distancias.containsKey(key)) {
        try {
          final resultado =
              await _rutaService.calcularDistanciaYTiempoSolo(gasolinera);
          final distancia = resultado['distancia'];

          if (distancia != null) {
            nuevasDistancias[key] = distancia;
          }
        } catch (e) {
          print('Error al calcular distancia para ${gasolinera.nombre}: $e');
        }
      }
    }

    if (nuevasDistancias.isNotEmpty) {
      setState(() {
        _distancias.addAll(nuevasDistancias);
      });
    }
  }

  Future<void> _buscarGasolinerasEnRuta(LatLng origen, LatLng destino) async {
    try {
      final puntosRuta = await _rutaService.obtenerPuntosRuta(origen, destino);

      final gasolinerasEnRuta = _gasolineras.where((g) {
        if (g.latitud == null || g.longitud == null) return false;
        final gasLatLng = LatLng(g.latitud!, g.longitud!);
        return puntosRuta.any((punto) {
          final distancia = Geolocator.distanceBetween(
            punto.latitude,
            punto.longitude,
            gasLatLng.latitude,
            gasLatLng.longitude,
          );
          return distancia <= 100;
        });
      }).toList();

      setState(() {
        _gasolinerasRutaOriginal = gasolinerasEnRuta;
        _ordenarPorPrecio = true;
      });

      _filtrarGasolinerasPorCombustible();
      await _calcularKmLista();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_gasolinerasRuta.isNotEmpty) {
          _sheetController.animateTo(
            0.55,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _sheetController.animateTo(
            0.28,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('Error buscando gasolineras en la ruta: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition:
                CameraPosition(target: LatLng(0, 0), zoom: 15.0),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapType: MapType.normal,
            zoomControlsEnabled: false,
            markers: _marcadores,
            onTap: (LatLng _) async {
              setState(() {
                _gasolinerasRuta = [];
                _gasolineraSeleccionada = null;
                _rutaActiva = false;
                _distancia = null;
                _duracion = null;
              });

              await _sheetController.animateTo(
                0.28,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            },
          ),
          Positioned(
            top: 22,
            left: 16,
            child: FloatingActionButton(
              onPressed: () async {
                try {
                  final posicion = await _rutaService.obtenerUbicacionActual();
                  final LatLng ubicacion =
                      LatLng(posicion.latitude, posicion.longitude);

                  mapController
                      .animateCamera(CameraUpdate.newLatLngZoom(ubicacion, 15));
                } catch (e) {
                  print('No s\'ha pogut obtenir la ubicació: $e');
                }
              },
              child: Icon(Icons.my_location),
            ),
          ),
          Positioned(
            top: 20,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    mapController.animateCamera(CameraUpdate.zoomIn());
                  },
                  child: Icon(Icons.add),
                ),
                SizedBox(height: 8),
                FloatingActionButton(
                  mini: true,
                  onPressed: () {
                    mapController.animateCamera(CameraUpdate.zoomOut());
                  },
                  child: Icon(Icons.remove),
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.28,
            minChildSize: 0.1,
            maxChildSize: _gasolineraSeleccionada != null || _hayPredicciones
                ? 0.55
                : 0.28,
            builder: (context, scrollController) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (_gasolineraSeleccionada != null) ...[
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          children: [
                            ListTile(
                              titleTextStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              title: Text(_gasolineraSeleccionada!.nombre ??
                                  'Gasolinera seleccionada'),
                              leading: Icon(Icons.local_gas_station),
                            ),
                            ListTile(
                              title: Text(_gasolineraSeleccionada!.ciudad ??
                                  'Ciudad no disponible'),
                              leading: Icon(Icons.location_on),
                            ),
                            if (_distancia != null)
                              ListTile(
                                title: Text(_distancia!),
                                leading: Icon(Icons.straighten),
                              ),
                            ListTile(
                              title: Text(_gasolineraSeleccionada!.horario ??
                                  'No disponible'),
                              leading: Icon(Icons.access_time),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.directions),
                        label: Text('Cómo llegar \n $_duracion'),
                        onPressed: () {
                          _rutaService.mostrarRutaHaciaGasolinera(
                              _gasolineraSeleccionada!);
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      SizedBox(height: 16),
                    ] else ...[
                      custom.SearchBar(
                        onSelected: (LatLng coords) async {
                          setState(() {
                            _destinoRuta = coords;
                          });

                          final posicion =
                              await _rutaService.obtenerUbicacionActual();
                          final origen =
                              LatLng(posicion.latitude, posicion.longitude);

                          await _buscarGasolinerasEnRuta(origen, coords);

                          mapController.animateCamera(
                            CameraUpdate.newLatLngZoom(coords, 14),
                          );
                        },
                        onPredictionStateChanged: (bool tienePredicciones) {
                          setState(() {
                            _hayPredicciones = tienePredicciones;
                          });

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_hayPredicciones) {
                              _sheetController.animateTo(
                                0.55,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            } else if (_gasolineraSeleccionada == null) {
                              _sheetController.animateTo(
                                0.28,
                                duration: Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            }
                          });
                        },
                        onChanged: (String texto) {
                          if (texto.isEmpty) {
                            setState(() {
                              _rutaActiva = false;
                              _gasolinerasRuta = [];
                            });
                            _sheetController.animateTo(
                              0.28,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        },
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: combustible.CombustibleSelector(
                              value: tipoCombustibleSeleccionado,
                              onChanged: (nuevoCombustible) {
                                setState(() {
                                  tipoCombustibleSeleccionado =
                                      nuevoCombustible!;
                                });
                                _cargarGasolineras();
                                if (_rutaActiva) {
                                  _filtrarGasolinerasPorCombustible();
                                  _calcularKmLista();
                                }
                              },
                            ),
                          ),
                          if (_rutaActiva)
                            FiltroSelector(
                              onFiltroChanged: (bool isPrecioSelected) {
                                setState(() {
                                  _ordenarPorPrecio = isPrecioSelected;
                                  _filtrarGasolinerasPorCombustible();
                                });
                              },
                            ),
                        ],
                      ),
                      SizedBox(height: 16),
                      if (_gasolinerasRuta.isNotEmpty)
                        ..._gasolinerasRuta
                            .where((g) =>
                                MarcadorGasolinera.obtenerPrecioGasolinera(
                                    g, tipoCombustibleSeleccionado) !=
                                null)
                            .map((g) {
                          final precio =
                              MarcadorGasolinera.obtenerPrecioGasolinera(
                                  g, tipoCombustibleSeleccionado);
                          final key = '${g.latitud}_${g.longitud}';
                          final distancia = _distancias[key];

                          return Card(
                            child: ListTile(
                              leading: Icon(Icons.local_gas_station),
                              title: Text(
                                g.nombre ?? 'Gasolinera',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${g.ciudad ?? ''} - ${precio!.toStringAsFixed(2)} €/L'),
                                  if (distancia != null) Text(distancia),
                                ],
                              ),
                              onTap: () async {
                                setState(() {
                                  _gasolineraSeleccionada = g;
                                });

                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  _sheetController.animateTo(
                                    0.42,
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeOut,
                                  );
                                });

                                try {
                                  final resultado = await _rutaService
                                      .calcularDistanciaYTiempoSolo(g);
                                  setState(() {
                                    _distancia = resultado['distancia'];
                                    _duracion = resultado['duracion'];
                                  });
                                } catch (e) {
                                  print('Error al calcular la distancia: $e');
                                }
                              },
                            ),
                          );
                        }).toList(),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
