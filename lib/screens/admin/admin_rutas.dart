import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/logger_service.dart';

class AdminRutasScreen extends StatefulWidget {
  const AdminRutasScreen({super.key});

  @override
  State<AdminRutasScreen> createState() => _AdminRutasScreenState();
}

class _AdminRutasScreenState extends State<AdminRutasScreen> {
  List<dynamic> rutas = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarRutas();
  }

  Future<void> cargarRutas() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await ApiService.getRutas();
      if (mounted) {
        setState(() {
          rutas = data;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
        LoggerService.error('Error al cargar rutas: $e');
      }
    }
  }

  Future<void> actualizarRuta(int id, Map<String, dynamic> data) async {
    try {
      await ApiService.actualizarRuta(id, data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ruta actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      cargarRutas();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar ruta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> eliminarRuta(int id) async {
    try {
      await ApiService.eliminarRuta(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ruta eliminada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
      cargarRutas();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar ruta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Rutas'),
        backgroundColor: Colors.blue,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error al cargar rutas: $error',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: cargarRutas,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: cargarRutas,
                  child: rutas.isEmpty
                      ? const Center(
                          child: Text('No hay rutas disponibles'),
                        )
                      : ListView.builder(
                          itemCount: rutas.length,
                          itemBuilder: (context, index) {
                            final ruta = rutas[index];
                            return Card(
                              margin: const EdgeInsets.all(12),
                              child: ExpansionTile(
                                title: Text(
                                  ruta['nombre'] ?? 'Sin nombre',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Creado por: ${ruta['creador_nombre'] ?? 'Desconocido'}'),
                                    Row(
                                      children: [
                                        Icon(
                                          ruta['aprobado'] == true
                                              ? Icons.check_circle
                                              : Icons.check_circle_outline,
                                          color: ruta['aprobado'] == true
                                              ? Colors.green
                                              : Colors.grey,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          ruta['aprobado'] == true
                                              ? 'Aprobado'
                                              : 'Pendiente',
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          ruta['destacado'] == true
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: ruta['destacado'] == true
                                              ? Colors.amber
                                              : Colors.grey,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          ruta['destacado'] == true
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
                                        ruta['aprobado'] == true
                                            ? Icons.check_circle
                                            : Icons.check_circle_outline,
                                        color: Colors.green,
                                      ),
                                      onPressed: () => actualizarRuta(
                                        ruta['id'],
                                        {'aprobado': !(ruta['aprobado'] == true)},
                                      ),
                                      tooltip: ruta['aprobado'] == true
                                          ? 'Desaprobar ruta'
                                          : 'Aprobar ruta',
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        ruta['destacado'] == true
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                      ),
                                      onPressed: () => actualizarRuta(
                                        ruta['id'],
                                        {'destacado': !(ruta['destacado'] == true)},
                                      ),
                                      tooltip: ruta['destacado'] == true
                                          ? 'Quitar destacado'
                                          : 'Destacar ruta',
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Confirmar eliminación'),
                                          content: Text(
                                              '¿Estás seguro de que deseas eliminar la ruta "${ruta['nombre']}"?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancelar'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                eliminarRuta(ruta['id']);
                                              },
                                              child: const Text(
                                                'Eliminar',
                                                style: TextStyle(color: Colors.red),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      tooltip: 'Eliminar ruta',
                                    ),
                                  ],
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Descripción:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(ruta['descripcion'] ?? 'Sin descripción'),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Lugares incluidos:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (ruta['lugares'] != null && ruta['lugares'].isNotEmpty)
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: List.generate(
                                              ruta['lugares'].length,
                                              (i) => Padding(
                                                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                                                child: Row(
                                                  children: [
                                                    Text('${i + 1}. '),
                                                    Expanded(
                                                      child: Text(
                                                        ruta['lugares'][i]['nombre'] ?? 'Lugar sin nombre',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          const Text('No hay lugares en esta ruta'),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Text(
                                              'Fecha de creación:',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              ruta['fecha_creacion'] != null
                                                  ? DateTime.parse(ruta['fecha_creacion'])
                                                      .toLocal()
                                                      .toString()
                                                      .substring(0, 16)
                                                  : 'Fecha desconocida',
                                            ),
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
    );
  }
} 