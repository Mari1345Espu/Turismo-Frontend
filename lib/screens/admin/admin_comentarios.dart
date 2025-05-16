import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../config.dart';
import '../../services/auth_service.dart';
import '../../widgets/menu_drawer.dart';

class AdminComentariosScreen extends StatefulWidget {
  const AdminComentariosScreen({super.key});

  @override
  State<AdminComentariosScreen> createState() => _AdminComentariosScreenState();
}

class _AdminComentariosScreenState extends State<AdminComentariosScreen> {
  List<dynamic> comentarios = [];
  bool loading = true;
  String? error;
  String busqueda = '';
  String filtroEstado = 'todos';
  final searchController = TextEditingController();
  
  final List<Map<String, dynamic>> filtrosEstado = [
    {'valor': 'todos', 'texto': 'Todos los comentarios'},
    {'valor': 'pendientes', 'texto': 'Pendientes de aprobación'},
    {'valor': 'aprobados', 'texto': 'Aprobados'},
  ];

  @override
  void initState() {
    super.initState();
    // Validar si el usuario es admin
    if (AuthService.rol != 'admin') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acceso restringido: solo administradores pueden moderar comentarios.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      });
    } else {
      cargarComentarios();
    }
  }

  Future<void> cargarComentarios() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await http.get(
        Uri.parse('${baseURL}comentarios/moderacion/'),
        headers: {'Authorization': 'Token ${AuthService.token}'},
      );
      
      if (response.statusCode == 200) {
        setState(() {
          comentarios = jsonDecode(response.body);
          loading = false;
        });
      } else {
        setState(() {
          error = 'Error ${response.statusCode}: ${response.body}';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        comentarios = [];
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> aprobarComentario(int id) async {
    try {
      final res = await http.patch(
        Uri.parse('${baseURL}comentarios/moderacion/$id/'),
        headers: {
          'Authorization': 'Token ${AuthService.token}',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({'aprobado': true}),
      );
      
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comentario aprobado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        cargarComentarios();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al aprobar comentario: ${res.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aprobar comentario: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> eliminarComentario(int id) async {
    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar comentario?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar')
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final res = await http.delete(
          Uri.parse('${baseURL}comentarios/moderacion/$id/'),
          headers: {'Authorization': 'Token ${AuthService.token}'},
        );
        
        if (res.statusCode == 204) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comentario eliminado correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          cargarComentarios();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar comentario: ${res.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar comentario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar comentarios según búsqueda y estado
    final comentariosFiltrados = comentarios.where((c) {
      final matchBusqueda = 
          (c['usuario']?.toString().toLowerCase() ?? '').contains(busqueda.toLowerCase()) ||
          (c['texto']?.toString().toLowerCase() ?? '').contains(busqueda.toLowerCase()) ||
          (c['lugar_nombre']?.toString().toLowerCase() ?? '').contains(busqueda.toLowerCase());
      
      bool matchEstado = true;
      if (filtroEstado == 'pendientes') {
        matchEstado = c['aprobado'] != true;
      } else if (filtroEstado == 'aprobados') {
        matchEstado = c['aprobado'] == true;
      }
      
      return matchBusqueda && matchEstado;
    }).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moderar Comentarios'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cargarComentarios,
            tooltip: 'Recargar comentarios',
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
                    labelText: 'Buscar en comentarios',
                    hintText: 'Buscar por usuario, texto o lugar',
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
                  value: filtroEstado,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por estado',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: filtrosEstado.map<DropdownMenuItem<String>>((filtro) => DropdownMenuItem<String>(
                    value: filtro['valor'] as String,
                    child: Text(filtro['texto'] as String),
                  )).toList(),
                  onChanged: (valor) {
                    setState(() {
                      filtroEstado = valor ?? 'todos';
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
                  'Mostrando ${comentariosFiltrados.length} de ${comentarios.length} comentarios',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                if (filtroEstado == 'pendientes' && comentariosFiltrados.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () async {
                      // Mostrar diálogo de confirmación
                      final confirmarTodos = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Aprobar todos los comentarios'),
                          content: Text('¿Deseas aprobar los ${comentariosFiltrados.length} comentarios pendientes?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Aprobar todos'),
                            ),
                          ],
                        ),
                      );
                      
                      if (confirmarTodos == true) {
                        setState(() {
                          loading = true;
                        });
                        
                        int exitos = 0;
                        int fallos = 0;
                        
                        // Aprobar todos los comentarios filtrados
                        for (var c in comentariosFiltrados) {
                          if (c['aprobado'] != true) {
                            try {
                              final res = await http.patch(
                                Uri.parse('${baseURL}comentarios/moderacion/${c['id']}/'),
                                headers: {
                                  'Authorization': 'Token ${AuthService.token}',
                                  'Content-Type': 'application/json'
                                },
                                body: jsonEncode({'aprobado': true}),
                              );
                              
                              if (res.statusCode == 200) {
                                exitos++;
                              } else {
                                fallos++;
                              }
                            } catch (e) {
                              fallos++;
                            }
                          }
                        }
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Procesados $exitos comentarios correctamente${fallos > 0 ? ', $fallos fallaron' : ''}'),
                              backgroundColor: fallos == 0 ? Colors.green : Colors.orange,
                            ),
                          );
                          cargarComentarios();
                        }
                      }
                    },
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Aprobar todos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
          
          // Lista de comentarios
          Expanded(
            child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar comentarios',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                          onPressed: cargarComentarios,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : comentariosFiltrados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.comment_bank, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            busqueda.isNotEmpty || filtroEstado != 'todos'
                              ? 'No se encontraron comentarios con los filtros seleccionados'
                              : 'No hay comentarios para revisar',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: comentariosFiltrados.length,
                      itemBuilder: (context, index) {
                        final c = comentariosFiltrados[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.blueGrey[100],
                                      child: Text(
                                        (c['usuario'] ?? '').toString().isNotEmpty 
                                            ? c['usuario'][0].toUpperCase() 
                                            : '?',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                c['usuario'] ?? 'Usuario anónimo',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (c['rol'] == 'experto')
                                                Container(
                                                  margin: const EdgeInsets.only(left: 8),
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 6, 
                                                    vertical: 2
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.orange[50],
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: Colors.orange),
                                                  ),
                                                  child: const Text(
                                                    'EXPERTO',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.deepOrange,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          Text(
                                            'Lugar: ${c['lugar_nombre'] ?? 'Desconocido'}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            'Fecha: ${c['fecha_creacion'] != null ? DateTime.parse(c['fecha_creacion']).toLocal().toString().substring(0, 16) : 'Desconocida'}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8, 
                                        vertical: 4
                                      ),
                                      decoration: BoxDecoration(
                                        color: c['aprobado'] == true 
                                            ? Colors.green[50] 
                                            : Colors.orange[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: c['aprobado'] == true 
                                              ? Colors.green 
                                              : Colors.orange
                                        ),
                                      ),
                                      child: Text(
                                        c['aprobado'] == true 
                                            ? 'APROBADO' 
                                            : 'PENDIENTE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: c['aprobado'] == true 
                                              ? Colors.green[800] 
                                              : Colors.orange[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Card(
                                  margin: EdgeInsets.zero,
                                  color: Colors.grey[50],
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: Colors.grey[200]!),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Text(c['texto'] ?? ''),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    const Text('Calificación:'),
                                    const SizedBox(width: 8),
                                    ...List.generate(5, (i) {
                                      return Icon(
                                        i < (c['calificacion'] ?? 0)
                                            ? Icons.star
                                            : Icons.star_border,
                                        color: Colors.amber,
                                        size: 18,
                                      );
                                    }),
                                    const Spacer(),
                                    if (c['aprobado'] != true)
                                      TextButton.icon(
                                        onPressed: () => aprobarComentario(c['id']),
                                        icon: const Icon(Icons.check_circle),
                                        label: const Text('Aprobar'),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.green,
                                        ),
                                      ),
                                    IconButton(
                                      onPressed: () => eliminarComentario(c['id']),
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Eliminar comentario',
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
