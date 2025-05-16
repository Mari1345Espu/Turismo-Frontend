import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../../services/logger_service.dart';
import '../../widgets/menu_drawer.dart';
import '../../widgets/custom_app_bar.dart';
import '../../routes/app_routes.dart';

class UsuarioHome extends StatefulWidget {
  const UsuarioHome({super.key});

  @override
  State<UsuarioHome> createState() => _UsuarioHomeState();
}

class _UsuarioHomeState extends State<UsuarioHome> {
  List lugares = [];
  bool loading = true;
  String selectedCategoria = 'todas';
  String ordenarPor = 'nombre';
  Position? userLocation;
  String? error;

  final List<Map<String, String>> categorias = [
    {'value': 'todas', 'label': 'Todas'},
    {'value': 'restaurante', 'label': 'Restaurantes'},
    {'value': 'atraccion', 'label': 'Atracciones'},
    {'value': 'hospedaje', 'label': 'Hospedajes'},
  ];

  @override
  void initState() {
    super.initState();
    LoggerService.info('Iniciando UsuarioHome');
    fetchLugares();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LoggerService.info('Obteniendo ubicación del usuario');
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        LoggerService.warning('Servicios de ubicación desactivados');
        setState(() => error = 'Los servicios de ubicación están desactivados');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        LoggerService.warning('Permiso de ubicación denegado, solicitando...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          LoggerService.warning('Permiso de ubicación denegado nuevamente');
          setState(() => error = 'Permisos de ubicación denegados');
          return;
        }
      }

      LoggerService.info('Obteniendo posición actual');
      Position position = await Geolocator.getCurrentPosition();
      LoggerService.info('Posición obtenida: ${position.latitude}, ${position.longitude}');
      
      if (!mounted) return;
      setState(() => userLocation = position);
      ordenarLugares();
    } catch (e) {
      LoggerService.error('Error al obtener la ubicación', e);
      if (!mounted) return;
      setState(() => error = 'Error al obtener la ubicación: $e');
    }
  }

  double _calculateDistance(dynamic lat1, dynamic lon1) {
    if (userLocation == null) return double.infinity;
    
    try {
      // Convertir a double si los valores son String
      final latitude = lat1 is String ? double.tryParse(lat1) ?? 0.0 : lat1.toDouble();
      final longitude = lon1 is String ? double.tryParse(lon1) ?? 0.0 : lon1.toDouble();
      
      return Geolocator.distanceBetween(
        latitude,
        longitude,
        userLocation!.latitude,
        userLocation!.longitude,
      );
    } catch (e) {
      LoggerService.error('Error al calcular distancia', e);
      return double.infinity;
    }
  }

  void ordenarLugares() {
    LoggerService.info('Ordenando lugares por: $ordenarPor');
    
    setState(() {
      try {
        switch (ordenarPor) {
          case 'nombre':
            lugares.sort((a, b) => a['nombre'].toString().compareTo(b['nombre'].toString()));
            break;
            
          case 'calificacion':
            lugares.sort((a, b) {
              final calA = a['calificacion_promedio'] ?? 0.0;
              final calB = b['calificacion_promedio'] ?? 0.0;
              return calB.compareTo(calA);
            });
            break;
            
          case 'distancia':
            if (userLocation != null) {
              lugares.sort((a, b) {
                try {
                  double distA = _calculateDistance(
                      a['latitud'], a['longitud']);
                  double distB = _calculateDistance(
                      b['latitud'], b['longitud']);
                  return distA.compareTo(distB);
                } catch (e) {
                  LoggerService.error('Error al ordenar por distancia', e);
                  return 0; 
                }
              });
            }
            break;
        }
      } catch (e) {
        LoggerService.error('Error general al ordenar lugares', e);
      }
    });
  }

  Future<void> fetchLugares() async {
    if (!mounted) return;
    
    setState(() {
      loading = true;
      error = null;
    });
    
    try {
      LoggerService.info('Cargando lugares, categoría: $selectedCategoria');
      final lugaresData = await ApiService.getLugares(categoria: selectedCategoria);
      
      if (!mounted) return;
      
      LoggerService.info('Lugares cargados: ${lugaresData.length}');
      setState(() {
        lugares = lugaresData;
      });
      
      ordenarLugares();
    } catch (e) {
      LoggerService.error('Error al cargar lugares', e);
      if (!mounted) return;
      setState(() => error = 'Error al cargar lugares: $e');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar lugares: $e'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: fetchLugares,
            textColor: Colors.white,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Widget buildCategoriaChip(String categoria) {
    Color color;
    switch (categoria) {
      case 'restaurante':
        color = Colors.redAccent;
        break;
      case 'atraccion':
        color = Colors.teal;
        break;
      case 'hospedaje':
        color = Colors.indigo;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(categoria, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }

  Widget buildStars(double rating) {
    return Row(
      children: List.generate(5, (i) {
        return Icon(
          i < rating.round() ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Lugares Turísticos',
        showDrawer: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              LoggerService.info('Navegando a mapa');
              Navigator.pushNamed(context, AppRoutes.mapa);
            },
            tooltip: 'Ver en mapa',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordenar lugares',
            onSelected: (value) {
              LoggerService.info('Cambiando orden a: $value');
              setState(() => ordenarPor = value);
              ordenarLugares();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'nombre',
                child: Text('Ordenar por nombre'),
              ),
              const PopupMenuItem(
                value: 'calificacion',
                child: Text('Ordenar por calificación'),
              ),
              if (userLocation != null)
                const PopupMenuItem(
                  value: 'distancia',
                  child: Text('Ordenar por cercanía'),
                ),
            ],
          ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: selectedCategoria,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Categoría',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: categorias
                  .map((cat) => DropdownMenuItem(
                        value: cat['value'],
                        child: Text(cat['label']!),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null && value != selectedCategoria) {
                  LoggerService.info('Cambiando categoría a: $value');
                  setState(() => selectedCategoria = value);
                  fetchLugares();
                }
              },
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(8),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Text(
                  error!,
                  style: TextStyle(color: Colors.red[700]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : lugares.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.place, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No hay lugares disponibles en la categoría "$selectedCategoria"',
                              style: const TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: fetchLugares,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchLugares,
                        child: ListView.builder(
                          itemCount: lugares.length,
                          padding: const EdgeInsets.all(8),
                          itemBuilder: (context, index) {
                            final lugar = lugares[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  try {
                                    LoggerService.info('Navegando a detalle de lugar ID: ${lugar['id']}');
                                    await Navigator.pushNamed(
                                      context, 
                                      AppRoutes.lugarDetalle,
                                      arguments: lugar['id'],
                                    );
                                    // Recargar después de ver detalles por si hay cambios
                                    await fetchLugares();
                                  } catch (e) {
                                    LoggerService.error('Error al abrir el lugar', e);
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error al abrir el lugar: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: lugar['imagen_principal'] != null
                                                ? Image.network(
                                                    lugar['imagen_principal'],
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) =>
                                                        Container(
                                                          width: 80,
                                                          height: 80,
                                                          color: Colors.grey[200],
                                                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                                        ),
                                                  )
                                                : Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey[200],
                                                    child: const Icon(Icons.place, color: Colors.grey),
                                                  ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  lugar['nombre'] ?? 'Sin nombre',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  lugar['descripcion'] ?? 'Sin descripción',
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          buildCategoriaChip(lugar['categoria']),
                                          const Spacer(),
                                          buildStars(lugar['calificacion_promedio'] ?? 0),
                                        ],
                                      ),
                                      if (userLocation != null) 
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Distancia: ${(_calculateDistance(lugar['latitud'], lugar['longitud']) / 1000).toStringAsFixed(1)} km',
                                                style: TextStyle(color: Colors.grey[700], fontSize: 14),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

