import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/logger_service.dart';
import '../../services/api_service.dart';
import '../../widgets/menu_drawer.dart';
import '../../widgets/custom_app_bar.dart';
import '../../routes/app_routes.dart';

class ExpertoHome extends StatefulWidget {
  const ExpertoHome({super.key});

  @override
  State<ExpertoHome> createState() => _ExpertoHomeState();
}

class _ExpertoHomeState extends State<ExpertoHome> {
  List lugares = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Verificamos primero que haya un usuario autenticado
      if (!AuthService.estaAutenticado) {
        LoggerService.warning('Acceso a ExpertoHome sin autenticación');
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
        LoggerService.warning(
            'Usuario con rol ${AuthService.rol} intentando acceder a ExpertoHome');
        AppRoutes.navigateToLogin(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Acceso denegado: tu rol es ${AuthService.rol ?? "indefinido"}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Si pasa las validaciones, cargamos los lugares
      LoggerService.info('Experto autenticado: ${AuthService.username}');
      cargarLugares();
    });
  }

  Future<void> cargarLugares() async {
    if (!mounted) return;

    // Verificación de seguridad adicional cada vez que se cargan los lugares
    if (!AuthService.estaAutenticado || !AuthService.esExperto) {
      LoggerService.warning(
          'Intento de cargar lugares sin autenticación o permisos adecuados');
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
      LoggerService.info(
          'Cargando lugares del experto: ${AuthService.username}');
      LoggerService.debug('Token: ${AuthService.token}');
      LoggerService.debug('Usuario ID: ${AuthService.userId}');

      final lugaresData = await ApiService.getLugaresExperto();

      if (!mounted) return;

      setState(() {
        lugares = lugaresData;
        loading = false;
      });

      LoggerService.info('Lugares cargados exitosamente: ${lugares.length}');
    } catch (e) {
      LoggerService.error('Error al cargar lugares', e);
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
            onPressed: cargarLugares,
            textColor: Colors.white,
          ),
        ),
      );
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
      appBar: const CustomAppBar(
        title: 'Mis lugares (Experto)',
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
                        onPressed: cargarLugares,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : lugares.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No has creado ningún lugar todavía',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                                    context, AppRoutes.crearLugar)
                                .then((_) => cargarLugares()),
                            icon: const Icon(Icons.add),
                            label: const Text('Crear nuevo lugar'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: cargarLugares,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: lugares.length,
                        itemBuilder: (context, index) {
                          final lugar = lugares[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 6),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => AppRoutes.navigateToLugarDetalle(
                                  context, lugar['id']),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            lugar['nombre'] ?? 'Sin nombre',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.orange),
                                          tooltip: 'Editar lugar',
                                          onPressed: () {
                                            Navigator.pushNamed(
                                              context,
                                              AppRoutes.editarLugar,
                                              arguments: lugar['id'],
                                            ).then((_) => cargarLugares());
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        buildStars(
                                            lugar['calificacion_promedio'] ??
                                                0),
                                        const SizedBox(width: 8),
                                        buildCategoriaChip(
                                            lugar['categoria'] ?? 'otra'),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            size: 16, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            lugar['direccion'] ??
                                                'Sin dirección',
                                            style: const TextStyle(
                                                color: Colors.grey),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
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
        onPressed: () => Navigator.pushNamed(context, AppRoutes.crearLugar)
            .then((_) => cargarLugares()),
        icon: const Icon(Icons.add),
        label: const Text('Agregar lugar'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
