import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/logger_service.dart';
import '../../widgets/menu_drawer.dart';

class AdminLugaresScreen extends StatefulWidget {
  const AdminLugaresScreen({super.key});

  @override
  State<AdminLugaresScreen> createState() => _AdminLugaresScreenState();
}

class _AdminLugaresScreenState extends State<AdminLugaresScreen> {
  List<dynamic> lugares = [];
  bool loading = true;
  String? error;
  String busqueda = '';
  String filtroCategoria = 'todas';
  final searchController = TextEditingController();

  // Lista de categorías obtenidas de los lugares
  List<String> categorias = ['todas'];

  @override
  void initState() {
    super.initState();
    cargarLugares();
  }

  void filtrarLugares() {
    // Filtrar lugares por búsqueda y categoría
    // Esta función se llama cuando cambia la búsqueda o el filtro
  }

  Future<void> cargarLugares() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await ApiService.getLugares();

      if (mounted) {
        // Extraer categorías únicas de los lugares
        final categoriasSet = <String>{'todas'};
        for (var lugar in data) {
          if (lugar['categoria'] != null &&
              lugar['categoria'].toString().isNotEmpty) {
            categoriasSet.add(lugar['categoria'].toString());
          }
        }

        setState(() {
          lugares = data;
          categorias = categoriasSet.toList()..sort();
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
        LoggerService.error('Error al cargar lugares: $e');
      }
    }
  }

  Future<void> actualizarLugar(int id, Map<String, dynamic> data) async {
    try {
      await ApiService.actualizarLugar(id, data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lugar actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      cargarLugares();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar lugar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> eliminarLugar(int id) async {
    // Mostrar diálogo de confirmación antes de eliminar
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
            '¿Estás seguro de que deseas eliminar este lugar? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ApiService.eliminarLugar(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lugar eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        cargarLugares();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar lugar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar lugares según búsqueda y categoría
    final lugaresFiltered = lugares.where((lugar) {
      final matchBusqueda = lugar['nombre']
              .toString()
              .toLowerCase()
              .contains(busqueda.toLowerCase()) ||
          (lugar['descripcion'] != null &&
              lugar['descripcion']
                  .toString()
                  .toLowerCase()
                  .contains(busqueda.toLowerCase()));

      final matchCategoria =
          filtroCategoria == 'todas' || lugar['categoria'] == filtroCategoria;

      return matchBusqueda && matchCategoria;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Lugares'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cargarLugares,
            tooltip: 'Recargar datos',
          ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: Column(
        children: [
          // Buscador y filtros
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: 'Buscar lugar',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: busqueda.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              setState(() {
                                busqueda = '';
                              });
                            },
                          )
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      busqueda = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: filtroCategoria,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por categoría',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: categorias
                      .map((categoria) => DropdownMenuItem(
                            value: categoria,
                            child: Text(categoria == 'todas'
                                ? 'Todas las categorías'
                                : categoria),
                          ))
                      .toList(),
                  onChanged: (valor) {
                    setState(() {
                      filtroCategoria = valor ?? 'todas';
                    });
                  },
                ),
              ],
            ),
          ),

          // Contador de resultados
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  'Mostrando ${lugaresFiltered.length} de ${lugares.length} lugares',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Lista de lugares
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 48, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              'Error al cargar lugares',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.red[700],
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error!,
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: cargarLugares,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : lugaresFiltered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_off,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  busqueda.isNotEmpty ||
                                          filtroCategoria != 'todas'
                                      ? 'No se encontraron resultados'
                                      : 'No hay lugares disponibles',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        color: Colors.grey[700],
                                      ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: lugaresFiltered.length,
                            itemBuilder: (context, index) {
                              final lugar = lugaresFiltered[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: ExpansionTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue[50],
                                    child: Icon(
                                      Icons.place,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  title: Text(lugar['nombre'] ?? 'Sin nombre'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          'Categoría: ${lugar['categoria'] ?? 'No especificada'}'),
                                      Row(
                                        children: [
                                          Icon(
                                            lugar['aprobado'] == true
                                                ? Icons.check_circle
                                                : Icons.check_circle_outline,
                                            color: lugar['aprobado'] == true
                                                ? Colors.green
                                                : Colors.grey,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            lugar['aprobado'] == true
                                                ? 'Aprobado'
                                                : 'Pendiente',
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            lugar['destacado'] == true
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: lugar['destacado'] == true
                                                ? Colors.amber
                                                : Colors.grey,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            lugar['destacado'] == true
                                                ? 'Destacado'
                                                : 'Normal',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(
                                          lugar['aprobado'] == true
                                              ? Icons.check_circle
                                              : Icons.check_circle_outline,
                                          color: Colors.green,
                                        ),
                                        onPressed: () => actualizarLugar(
                                          lugar['id'],
                                          {
                                            'aprobado':
                                                !(lugar['aprobado'] == true)
                                          },
                                        ),
                                        tooltip: lugar['aprobado'] == true
                                            ? 'Desaprobar lugar'
                                            : 'Aprobar lugar',
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          lugar['destacado'] == true
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: Colors.amber,
                                        ),
                                        onPressed: () => actualizarLugar(
                                          lugar['id'],
                                          {
                                            'destacado':
                                                !(lugar['destacado'] == true)
                                          },
                                        ),
                                        tooltip: lugar['destacado'] == true
                                            ? 'Quitar destacado'
                                            : 'Destacar lugar',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            eliminarLugar(lugar['id']),
                                        tooltip: 'Eliminar lugar',
                                      ),
                                    ],
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Descripción:',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(lugar['descripcion'] ??
                                              'Sin descripción'),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Text(
                                                'Ubicación:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                  'Lat: ${lugar['latitud']}, Lng: ${lugar['longitud']}'),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Text(
                                                'Creado por:',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(lugar['creador_nombre'] ??
                                                  'Desconocido'),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          if (lugar['calificacion_promedio'] !=
                                              null)
                                            Row(
                                              children: [
                                                const Text(
                                                  'Calificación promedio:',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                const SizedBox(width: 8),
                                                ...List.generate(5, (i) {
                                                  final rating = lugar[
                                                          'calificacion_promedio'] ??
                                                      0;
                                                  return Icon(
                                                    i < rating
                                                        ? Icons.star
                                                        : Icons.star_border,
                                                    color: Colors.amber,
                                                    size: 18,
                                                  );
                                                }),
                                                const SizedBox(width: 4),
                                                Text(
                                                    '(${lugar['calificacion_promedio']})'),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
