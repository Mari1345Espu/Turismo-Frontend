import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../../services/logger_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/menu_drawer.dart';
import '../../routes/app_routes.dart';
import 'lugar_detalle.dart';

class MapaLugares extends StatefulWidget {
  const MapaLugares({super.key});

  @override
  State<MapaLugares> createState() => _MapaLugaresState();
}

class _MapaLugaresState extends State<MapaLugares> {
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  Position? userLocation;
  bool loading = true;
  String? error;
  String selectedCategoria = 'todas';

  final List<Map<String, String>> categorias = [
    {'value': 'todas', 'label': 'Todas'},
    {'value': 'restaurante', 'label': 'Restaurantes'},
    {'value': 'atraccion', 'label': 'Atracciones'},
    {'value': 'hospedaje', 'label': 'Hospedajes'},
  ];

  @override
  void initState() {
    super.initState();
    LoggerService.info('Iniciando pantalla de mapa');
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      LoggerService.info('Cargando datos del mapa');
      setState(() {
        loading = true;
        error = null;
      });
      
      await _getCurrentLocation();
      await _loadPlaces();
      
      LoggerService.info('Datos del mapa cargados exitosamente');
    } catch (e) {
      LoggerService.error('Error al cargar datos del mapa', e);
      if (!mounted) return;
      setState(() => error = e.toString());
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LoggerService.info('Obteniendo ubicación del usuario para el mapa');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        LoggerService.warning('Servicios de ubicación desactivados');
        throw Exception('Los servicios de ubicación están desactivados');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        LoggerService.warning('Permiso de ubicación denegado, solicitando...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          LoggerService.warning('Permiso de ubicación denegado después de solicitar');
          throw Exception('Permisos de ubicación denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        LoggerService.warning('Permiso de ubicación denegado permanentemente');
        throw Exception('Los permisos de ubicación están permanentemente denegados. Por favor, actívalos en la configuración de tu dispositivo.');
      }

      LoggerService.info('Obteniendo posición actual');
      userLocation = await Geolocator.getCurrentPosition();
      LoggerService.info('Posición actual obtenida: ${userLocation?.latitude}, ${userLocation?.longitude}');
    } catch (e) {
      LoggerService.error('Error al obtener ubicación', e);
      throw Exception('Error al obtener ubicación: $e');
    }
  }

  Future<void> _loadPlaces() async {
    try {
      LoggerService.info('Cargando lugares para el mapa, categoría: $selectedCategoria');
      final lugares = await ApiService.getLugares(categoria: selectedCategoria);
      LoggerService.info('Lugares cargados: ${lugares.length}');
      
      if (!mounted) return;
      
      setState(() {
        markers = lugares.map((lugar) {
          // Validar que latitud y longitud sean números válidos
          double lat = 0.0;
          double lng = 0.0;
          
          try {
            lat = lugar['latitud'] is String 
                ? double.parse(lugar['latitud']) 
                : (lugar['latitud'] as num).toDouble();
            lng = lugar['longitud'] is String 
                ? double.parse(lugar['longitud']) 
                : (lugar['longitud'] as num).toDouble();
          } catch (e) {
            LoggerService.error('Error al parsear coordenadas para el lugar ${lugar['id']}', e);
            return null; // Este marker será filtrado después
          }
          
          final iconHue = _getCategoryHue(lugar['categoria']);
          
          return Marker(
            markerId: MarkerId(lugar['id'].toString()),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(iconHue),
            infoWindow: InfoWindow(
              title: lugar['nombre'],
              snippet: lugar['categoria'],
              onTap: () {
                LoggerService.info('Navegando a detalle de lugar desde mapa: ${lugar['id']}');
                Navigator.pushNamed(
                  context,
                  AppRoutes.lugarDetalle,
                  arguments: lugar['id'],
                ).then((_) => _loadPlaces());
              },
            ),
          );
        })
        .whereType<Marker>() // Filtrar nulls
        .toSet();
      });
    } catch (e) {
      LoggerService.error('Error al cargar lugares para el mapa', e);
      throw Exception('Error al cargar lugares: $e');
    }
  }
  
  double _getCategoryHue(String categoria) {
    switch (categoria) {
      case 'restaurante':
        return BitmapDescriptor.hueRed;
      case 'atraccion':
        return BitmapDescriptor.hueGreen;
      case 'hospedaje':
        return BitmapDescriptor.hueBlue;
      default:
        return BitmapDescriptor.hueYellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Cargando mapa...', showDrawer: false),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando mapa y ubicaciones...'),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Mapa de Lugares', showDrawer: false),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[300], size: 64),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar el mapa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  error!,
                  style: TextStyle(color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadData(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Mapa de Lugares', 
        showDrawer: true,
      ),
      drawer: const MenuDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Filtrar por categoría',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 8),
                        ),
                        value: selectedCategoria,
                        items: categorias.map((cat) => DropdownMenuItem(
                          value: cat['value'],
                          child: Text(cat['label']!),
                        )).toList(),
                        onChanged: (value) {
                          if (value != null && value != selectedCategoria) {
                            LoggerService.info('Cambiando categoría de mapa a: $value');
                            setState(() => selectedCategoria = value);
                            _loadPlaces();
                          }
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Actualizar mapa',
                      onPressed: _loadPlaces,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                LoggerService.info('Mapa creado');
                setState(() => mapController = controller);
              },
              initialCameraPosition: CameraPosition(
                target: userLocation != null
                    ? LatLng(userLocation!.latitude, userLocation!.longitude)
                    : const LatLng(4.8126, -74.3539), // Facatativá
                zoom: 13,
              ),
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapToolbarEnabled: true,
              compassEnabled: true,
              onTap: (_) {
                // Cerrar cualquier ventana de información que esté abierta
                FocusScope.of(context).unfocus();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        child: const Icon(Icons.my_location),
        onPressed: () {
          if (userLocation != null && mapController != null) {
            LoggerService.info('Centrando mapa en la ubicación del usuario');
            mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(
                LatLng(userLocation!.latitude, userLocation!.longitude), 
                15
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo obtener tu ubicación'),
              ),
            );
          }
        },
      ),
    );
  }
} 