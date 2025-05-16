import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/logger_service.dart';
import '../../widgets/menu_drawer.dart';
import '../../routes/app_routes.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool loading = true;
  Map<String, dynamic> estadisticas = {
    'usuarios': {'total': 0, 'expertos': 0, 'admins': 0},
    'lugares': {'total': 0, 'aprobados': 0, 'pendientes': 0},
    'rutas': {'total': 0, 'aprobadas': 0, 'pendientes': 0},
    'comentarios': {'total': 0, 'aprobados': 0, 'pendientes': 0},
  };
  String? error;

  @override
  void initState() {
    super.initState();
    cargarEstadisticas();
  }

  Future<void> cargarEstadisticas() async {
    if (!mounted) return;
    
    setState(() {
      loading = true;
      error = null;
    });

    try {
      // Cargar usuarios
      try {
        final usuarios = await ApiService.getUsuarios();
        if (mounted) {
          setState(() {
            estadisticas['usuarios']['total'] = usuarios.length;
            estadisticas['usuarios']['expertos'] = usuarios.where((u) => u['rol'] == 'experto').length;
            estadisticas['usuarios']['admins'] = usuarios.where((u) => u['rol'] == 'admin').length;
          });
        }
      } catch (e) {
        LoggerService.error('Error al cargar estadísticas de usuarios', e);
      }

      // Cargar lugares
      try {
        final lugares = await ApiService.getLugares();
        if (mounted) {
          setState(() {
            estadisticas['lugares']['total'] = lugares.length;
            estadisticas['lugares']['aprobados'] = lugares.where((l) => l['aprobado'] == true).length;
            estadisticas['lugares']['pendientes'] = lugares.where((l) => l['aprobado'] != true).length;
          });
        }
      } catch (e) {
        LoggerService.error('Error al cargar estadísticas de lugares', e);
      }

      // Cargar rutas
      try {
        final rutas = await ApiService.getRutas();
        if (mounted) {
          setState(() {
            estadisticas['rutas']['total'] = rutas.length;
            estadisticas['rutas']['aprobadas'] = rutas.where((r) => r['aprobado'] == true).length;
            estadisticas['rutas']['pendientes'] = rutas.where((r) => r['aprobado'] != true).length;
          });
        }
      } catch (e) {
        LoggerService.error('Error al cargar estadísticas de rutas', e);
      }

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: cargarEstadisticas,
            tooltip: 'Actualizar estadísticas',
          ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar el panel',
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
                        onPressed: cargarEstadisticas,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: cargarEstadisticas,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tarjetas con resumen
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.blue[700]!, Colors.blue[500]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue[300]!.withOpacity(0.5),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.dashboard, color: Colors.white, size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Panel de Control',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Bienvenido, ${AuthService.username}',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Aquí puedes administrar todos los aspectos de Rutas Andinas',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Estadísticas
                        Text(
                          'Resumen de la plataforma',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Estadísticas en tarjetas
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          children: [
                            _buildStatsCard(
                              context,
                              title: 'Usuarios',
                              total: estadisticas['usuarios']['total'],
                              icon: Icons.people,
                              color: Colors.indigo,
                              onTap: () => Navigator.pushNamed(context, AppRoutes.adminRoles),
                              stats: [
                                {'label': 'Expertos', 'value': estadisticas['usuarios']['expertos']},
                                {'label': 'Admins', 'value': estadisticas['usuarios']['admins']},
                              ],
                            ),
                            _buildStatsCard(
                              context,
                              title: 'Lugares',
                              total: estadisticas['lugares']['total'],
                              icon: Icons.place,
                              color: Colors.green,
                              onTap: () => Navigator.pushNamed(context, AppRoutes.adminLugares),
                              stats: [
                                {'label': 'Aprobados', 'value': estadisticas['lugares']['aprobados']},
                                {'label': 'Pendientes', 'value': estadisticas['lugares']['pendientes']},
                              ],
                              pendientes: estadisticas['lugares']['pendientes'],
                            ),
                            _buildStatsCard(
                              context,
                              title: 'Rutas',
                              total: estadisticas['rutas']['total'],
                              icon: Icons.route,
                              color: Colors.purple,
                              onTap: () => Navigator.pushNamed(context, AppRoutes.adminRutas),
                              stats: [
                                {'label': 'Aprobadas', 'value': estadisticas['rutas']['aprobadas']},
                                {'label': 'Pendientes', 'value': estadisticas['rutas']['pendientes']},
                              ],
                              pendientes: estadisticas['rutas']['pendientes'],
                            ),
                            _buildStatsCard(
                              context,
                              title: 'Comentarios',
                              total: estadisticas['comentarios']['total'],
                              icon: Icons.comment,
                              color: Colors.orange,
                              onTap: () => Navigator.pushNamed(context, AppRoutes.adminComentarios),
                              stats: [
                                {'label': 'Aprobados', 'value': estadisticas['comentarios']['aprobados']},
                                {'label': 'Pendientes', 'value': estadisticas['comentarios']['pendientes']},
                              ],
                              pendientes: estadisticas['comentarios']['pendientes'],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Acciones rápidas
                        Text(
                          'Acciones rápidas',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                context,
                                title: 'Gestionar Usuarios',
                                icon: Icons.admin_panel_settings,
                                color: Colors.indigo,
                                onTap: () => Navigator.pushNamed(context, AppRoutes.adminRoles),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildActionButton(
                                context,
                                title: 'Moderar Lugares',
                                icon: Icons.place,
                                color: Colors.green,
                                onTap: () => Navigator.pushNamed(context, AppRoutes.adminLugares),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                context,
                                title: 'Moderar Rutas',
                                icon: Icons.route,
                                color: Colors.purple,
                                onTap: () => Navigator.pushNamed(context, AppRoutes.adminRutas),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildActionButton(
                                context,
                                title: 'Moderar Comentarios',
                                icon: Icons.comment,
                                color: Colors.orange,
                                onTap: () => Navigator.pushNamed(context, AppRoutes.adminComentarios),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context, {
    required String title,
    required int total,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required List<Map<String, dynamic>> stats,
    int pendientes = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 28),
                if (pendientes > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      pendientes.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              total.toString(),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: stats.map((stat) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat['label'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      stat['value'].toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: color,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
