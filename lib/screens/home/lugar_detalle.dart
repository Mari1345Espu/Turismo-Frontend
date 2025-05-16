import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/logger_service.dart';
import '../../routes/app_routes.dart';
import '../../services/config_service.dart';

class LugarDetalle extends StatefulWidget {
  final int lugarId;
  const LugarDetalle({super.key, required this.lugarId});

  @override
  State<LugarDetalle> createState() => _LugarDetalleState();
}

class _LugarDetalleState extends State<LugarDetalle> {
  Map<String, dynamic>? lugar;
  List<dynamic> comentarios = [];
  bool loading = true;
  bool esFavorito = false;
  String? error;
  bool isConnectionError = false;

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
      isConnectionError = false;
    });

    try {
      // Cargar datos del lugar
      LoggerService.info('Cargando lugar ${widget.lugarId}');
      LoggerService.info('URL del servidor: ${ConfigService.serverUrl}');

      final lugarData = await ApiService.getLugarById(widget.lugarId);

      if (!mounted) return;

      // Cargar comentarios
      List<dynamic> comentariosData = [];
      try {
        comentariosData = await ApiService.getComentarios(widget.lugarId);
      } catch (e) {
        LoggerService.error('Error al cargar comentarios', e);
        // No lanzamos el error aquí para que al menos se muestre la info del lugar
      }

      if (!mounted) return;

      // Cargar estado de favorito si el usuario está autenticado
      bool esFav = false;
      if (AuthService.estaAutenticado) {
        try {
          esFav = await ApiService.esFavorito(widget.lugarId);
        } catch (e) {
          LoggerService.error('Error al verificar favorito', e);
          // No lanzamos el error aquí para que no afecte la carga principal
        }
      }

      if (!mounted) return;

      setState(() {
        lugar = lugarData;
        comentarios = comentariosData;
        esFavorito = esFav;
        loading = false;
      });
    } catch (e) {
      LoggerService.error('Error al cargar datos del lugar', e);
      if (!mounted) return;

      // Detectar si es un error de conexión
      bool esErrorConexion = e.toString().contains('SocketException') ||
          e.toString().contains('timeout') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('No se puede conectar al servidor');

      setState(() {
        error = e.toString();
        loading = false;
        isConnectionError = esErrorConexion;
      });

      // Mostrar un snackbar con el error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Reintentar',
            textColor: Colors.white,
            onPressed: cargarDatos,
          ),
        ),
      );
    }
  }

  Future<void> toggleFavorito() async {
    if (!AuthService.estaAutenticado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para marcar favoritos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final eraFavorito = esFavorito;
      await ApiService.toggleFavorito(widget.lugarId);
      await cargarDatos(); // Recargar todos los datos después de cambiar el estado de favorito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(eraFavorito
              ? 'Lugar eliminado de favoritos'
              : 'Lugar agregado a favoritos'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar favorito: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildImageGallery() {
    if (lugar == null ||
        lugar!['imagenes'] == null ||
        lugar!['imagenes'].isEmpty) {
      return Container(
        height: 200,
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: lugar!['imagenes'].length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                lugar!['imagenes'][index]['url'],
                width: 300,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: lugar != null ? lugar!['nombre'] : 'Detalle del lugar',
        showDrawer: false,
        actions: AuthService.estaAutenticado
            ? [
                IconButton(
                  icon:
                      Icon(esFavorito ? Icons.favorite : Icons.favorite_border),
                  onPressed: toggleFavorito,
                  tooltip: 'Marcar como favorito',
                )
              ]
            : null,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isConnectionError
                              ? Icons.wifi_off
                              : Icons.error_outline,
                          size: 70,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isConnectionError
                              ? 'Error de conexión'
                              : 'Error al cargar el lugar',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isConnectionError
                              ? 'No se pudo conectar con el servidor. Verifica la configuración y tu conexión a internet.'
                              : error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: cargarDatos,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Reintentar'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                        ),
                        if (isConnectionError) ...[
                          const SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                  context, AppRoutes.configuracion);
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('Revisar configuración'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: cargarDatos,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildImageGallery(),
                        const SizedBox(height: 16),
                        Text(
                          lugar!['nombre'],
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lugar!['categoria'],
                            style: TextStyle(color: Colors.blue[900]),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          lugar!['descripcion'],
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.location_on),
                            title: const Text('Dirección'),
                            subtitle: Text(lugar!['direccion']),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: ListTile(
                            leading:
                                const Icon(Icons.star, color: Colors.amber),
                            title: const Text('Calificación promedio'),
                            subtitle: Row(
                              children: List.generate(5, (i) {
                                final calif =
                                    lugar!['calificacion_promedio'] ?? 0;
                                return Icon(
                                  i < calif.round()
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 20,
                                );
                              }),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Text(
                              'Reseñas',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (AuthService.estaAutenticado)
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.agregarComentario,
                                  arguments: {
                                    'lugarId': lugar!['id'],
                                    'lugarNombre': lugar!['nombre'],
                                    'token': AuthService.token,
                                  },
                                ).then((_) => cargarDatos()),
                                icon: const Icon(Icons.rate_review),
                                label: const Text('Escribir reseña'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (comentarios.isEmpty)
                          const Center(
                            child: Text(
                              'No hay reseñas aprobadas todavía. ¡Sé el primero en comentar!',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: comentarios.length,
                            itemBuilder: (context, index) {
                              final c = comentarios[index];
                              // Solo mostrar comentarios aprobados
                              if (c['aprobado'] != true)
                                return const SizedBox.shrink();
                              final esPropio =
                                  AuthService.username == c['usuario'];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Colors.blue[100],
                                            child: Text(
                                              c['usuario'][0].toUpperCase(),
                                              style: TextStyle(
                                                color: Colors.blue[900],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      c['usuario'],
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (c['rol'] == 'experto')
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(left: 6),
                                                        child: Tooltip(
                                                          message:
                                                              'Experto verificado',
                                                          child: Icon(
                                                            Icons.verified,
                                                            size: 16,
                                                            color: Colors
                                                                .blue[700],
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                Text(
                                                  c['fecha_creacion'] ??
                                                      'Fecha no disponible',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (esPropio)
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit,
                                                      color: Colors.orange),
                                                  tooltip: 'Editar comentario',
                                                  onPressed: () async {
                                                    final result =
                                                        await Navigator
                                                            .pushNamed(
                                                      context,
                                                      AppRoutes
                                                          .editarComentario,
                                                      arguments: {
                                                        'comentarioId': c['id'],
                                                        'lugarId':
                                                            widget.lugarId,
                                                        'textoInicial':
                                                            c['texto'],
                                                        'calificacionInicial':
                                                            c['calificacion'],
                                                        'lugarNombre':
                                                            lugar!['nombre'],
                                                      },
                                                    );
                                                    if (result == true)
                                                      cargarDatos();
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete,
                                                      color: Colors.red),
                                                  tooltip:
                                                      'Eliminar comentario',
                                                  onPressed: () =>
                                                      _confirmarEliminarComentario(
                                                          c['id']),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: List.generate(5, (i) {
                                          return Icon(
                                            i < c['calificacion']
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: Colors.amber,
                                            size: 18,
                                          );
                                        }),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        c['texto'],
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Future<void> _confirmarEliminarComentario(int comentarioId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: const Text(
            '¿Estás seguro de que quieres eliminar este comentario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await ApiService.eliminarComentario(comentarioId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comentario eliminado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        cargarDatos();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar el comentario: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
