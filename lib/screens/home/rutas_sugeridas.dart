import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/logger_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/menu_drawer.dart';
import 'lugar_detalle.dart';
import '../../routes/app_routes.dart';

class RutasSugeridasScreen extends StatefulWidget {
  const RutasSugeridasScreen({super.key});

  @override
  State<RutasSugeridasScreen> createState() => _RutasSugeridasScreenState();
}

class _RutasSugeridasScreenState extends State<RutasSugeridasScreen> {
  List<dynamic> rutas = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarRutas();
  }

  Future<void> cargarRutas() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      LoggerService.info('Cargando rutas sugeridas');
      final data = await ApiService.getRutas();
      
      if (!mounted) return;

      setState(() {
        rutas = data;
        loading = false;
      });
      
      LoggerService.info('Rutas cargadas: ${rutas.length}');
    } catch (e) {
      LoggerService.error('Error cargando rutas', e);
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar rutas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildRutaCard(Map<String, dynamic> ruta) {
    final lugaresCount = ruta['lugares'] != null ? (ruta['lugares'] as List).length : 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.route, size: 28, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ruta['nombre'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${lugaresCount} ${lugaresCount == 1 ? 'lugar' : 'lugares'}',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              ruta['descripcion'],
              style: const TextStyle(fontSize: 14),
            ),
          ),
          if (ruta['lugares'] != null && (ruta['lugares'] as List).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.place, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        'Lugares en esta ruta:',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(
                    ruta['lugares'].length,
                    (index) {
                      final lugar = ruta['lugares'][index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: lugar['imagen_principal'] != null
                                ? Image.network(
                                    lugar['imagen_principal'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.image_not_supported,
                                            color: Colors.grey),
                                  )
                                : const Icon(Icons.place, color: Colors.grey),
                          ),
                        ),
                        title: Text(
                          lugar['nombre'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          lugar['categoria'],
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          LoggerService.info('Navegando a detalle de lugar ID: ${lugar['id']}');
                          Navigator.pushNamed(
                            context,
                            AppRoutes.lugarDetalle,
                            arguments: lugar['id'],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool puedeCrearRutas = AuthService.esExperto;
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Rutas Sugeridas',
        showDrawer: true,
      ),
      drawer: const MenuDrawer(),
      body: RefreshIndicator(
        onRefresh: cargarRutas,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[300], size: 64),
                        const SizedBox(height: 16),
                        Text(
                          'No se pudieron cargar las rutas',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error!,
                          style: TextStyle(color: Colors.red[700]),
                          textAlign: TextAlign.center,
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
                            Icon(Icons.route, size: 64, color: Colors.blue[200]),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay rutas sugeridas disponibles',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (puedeCrearRutas) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, AppRoutes.crearRuta)
                                    .then((_) => cargarRutas()),
                                icon: const Icon(Icons.add),
                                label: const Text('Crear nueva ruta'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: rutas.length,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemBuilder: (context, index) => buildRutaCard(rutas[index]),
                      ),
      ),
      floatingActionButton: puedeCrearRutas
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.crearRuta)
                  .then((_) => cargarRutas()),
              icon: const Icon(Icons.add),
              label: const Text('Crear Ruta'),
              backgroundColor: Colors.blue,
            )
          : null,
    );
  }
}
