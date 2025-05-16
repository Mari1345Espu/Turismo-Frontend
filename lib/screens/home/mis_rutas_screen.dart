import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/logger_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/menu_drawer.dart';
import '../../routes/app_routes.dart';

class MisRutasScreen extends StatefulWidget {
  const MisRutasScreen({super.key});

  @override
  State<MisRutasScreen> createState() => _MisRutasScreenState();
}

class _MisRutasScreenState extends State<MisRutasScreen> {
  List<dynamic> rutas = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Verificamos primero que haya un usuario autenticado
      if (!AuthService.estaAutenticado) {
        LoggerService.warning('Acceso a MisRutasScreen sin autenticación');
        AppRoutes.navigateToLogin(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor inicia sesión para continuar'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Ahora verificamos que sea un experto
      if (!AuthService.esExperto) {
        LoggerService.warning('Usuario con rol ${AuthService.rol} intentando acceder a MisRutasScreen');
        AppRoutes.navigateToLogin(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Acceso denegado: tu rol es ${AuthService.rol ?? "indefinido"}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Si pasa las validaciones, cargamos las rutas
      LoggerService.info('Experto autenticado: ${AuthService.username}');
      cargarRutas();
    });
  }

  Future<void> cargarRutas() async {
    if (!mounted) return;
    
    // Verificación de seguridad adicional cada vez que se cargan las rutas
    if (!AuthService.estaAutenticado || !AuthService.esExperto) {
      LoggerService.warning('Intento de cargar rutas sin autenticación o permisos adecuados');
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppRoutes.navigateToLogin(context);
        });
      }
      return;
    }
    
    setState(() {
      loading = true;
      error = null;
    });

    try {
      LoggerService.info('Cargando rutas del experto: ${AuthService.username}');
      
      final rutasData = await ApiService.getRutasExperto();
      
      if (!mounted) return;
      
      setState(() {
        rutas = rutasData;
        loading = false;
      });
      
      LoggerService.info('Rutas cargadas exitosamente: ${rutas.length}');
    } catch (e) {
      LoggerService.error('Error al cargar rutas', e);
      if (!mounted) return;
      
      // Manejar errores específicos
      String errorMessage = e.toString();
      
      if (errorMessage.contains('No tienes permisos') || 
          errorMessage.contains('Usuario no autenticado') ||
          errorMessage.contains('Sesión expirada')) {
        // Redirigir al login en caso de error de permisos
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppRoutes.navigateToLogin(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage.replaceAll('Exception: ', '')),
              backgroundColor: Colors.red,
            ),
          );
        });
        return;
      }
      
      setState(() {
        error = errorMessage.replaceAll('Exception: ', '');
        loading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${error!}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: cargarRutas,
            textColor: Colors.white,
          ),
        ),
      );
    }
  }

  Future<void> eliminarRuta(int rutaId) async {
    try {
      // Mostrar diálogo de confirmación
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar esta ruta?'),
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
      
      // Si el usuario no confirmó, cancelamos
      if (confirmar != true) return;
      
      // Mostrar indicador de carga
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Eliminando ruta...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Eliminar la ruta
      await ApiService.eliminarRuta(rutaId);
      
      if (!mounted) return;
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ruta eliminada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Recargar las rutas
      cargarRutas();
    } catch (e) {
      if (!mounted) return;
      
      LoggerService.error('Error al eliminar ruta', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar ruta: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Widget para mostrar el número de lugares en una ruta
  Widget buildLugaresCount(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Text(
        '$count ${count == 1 ? 'lugar' : 'lugares'}',
        style: TextStyle(color: Colors.blue[700], fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Mis Rutas de Viaje',
        showDrawer: true,
      ),
      drawer: const MenuDrawer(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: cargarRutas,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : rutas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.route_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No has creado ninguna ruta todavía',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.crearRuta)
                                .then((_) => cargarRutas()),
                            icon: const Icon(Icons.add),
                            label: const Text('Crear nueva ruta'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: cargarRutas,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: rutas.length,
                        itemBuilder: (context, index) {
                          final ruta = rutas[index];
                          final lugaresCount = ruta['lugares'] != null 
                              ? (ruta['lugares'] as List).length 
                              : 0;
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                // Aquí podríamos navegar a un detalle de la ruta
                                // pero como no existe esa pantalla, mostramos un SnackBar
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Vista detallada no implementada'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            ruta['nombre'] ?? 'Sin nombre',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.orange),
                                          tooltip: 'Editar ruta',
                                          onPressed: () {
                                            // Aquí navegaríamos a editar ruta
                                            AppRoutes.navigateToEditarRuta(context, ruta['id']);
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          tooltip: 'Eliminar ruta',
                                          onPressed: () => eliminarRuta(ruta['id']),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.route, size: 16, color: Colors.blue),
                                        const SizedBox(width: 8),
                                        buildLugaresCount(lugaresCount),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      ruta['descripcion'] ?? 'Sin descripción',
                                      style: const TextStyle(fontSize: 14),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.crearRuta)
            .then((_) => cargarRutas()),
        icon: const Icon(Icons.add),
        label: const Text('Crear Ruta'),
        backgroundColor: Colors.blue,
      ),
    );
  }
} 