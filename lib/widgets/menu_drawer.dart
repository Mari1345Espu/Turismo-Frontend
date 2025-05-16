import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../routes/app_routes.dart';

class MenuDrawer extends StatelessWidget {
  const MenuDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Verificamos si el usuario es experto
    final bool esExperto = AuthService.esExperto;
    final bool esAdmin = AuthService.esAdmin;
    
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rutas Andinas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AuthService.username ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                Text(
                  AuthService.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Rol: ${AuthService.rol}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          // Sección de Exploración
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Text(
              'EXPLORACIÓN',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pop(context);
              if (ModalRoute.of(context)?.settings.name != AppRoutes.usuario) {
                Navigator.pushReplacementNamed(context, AppRoutes.usuario);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('Mapa'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.mapa);
            },
          ),
          ListTile(
            leading: const Icon(Icons.route),
            title: const Text('Rutas Sugeridas'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.rutas);
            },
          ),

          // Sección Personal
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              'PERSONAL',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Mis Favoritos'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.favoritos);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Mi Perfil'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.perfil);
            },
          ),

          // Sección de Experto
          if (esExperto || esAdmin) ...[
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                'GESTIÓN DE LUGARES',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // La opción de crear lugar solo aparece para expertos
            if (esExperto)
              ListTile(
                leading: const Icon(Icons.add_location),
                title: const Text('Crear Lugar'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.crearLugar);
                },
              ),
            // La opción de crear ruta solo aparece para expertos
            if (esExperto)
              ListTile(
                leading: const Icon(Icons.route_sharp),
                title: const Text('Crear Ruta de Viaje'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.crearRuta);
                },
              ),
            // La opción de mis rutas solo aparece para expertos
            if (esExperto)
              ListTile(
                leading: const Icon(Icons.map_sharp),
                title: const Text('Mis Rutas de Viaje'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.misRutas);
                },
              ),
            ListTile(
              leading: const Icon(Icons.home_work),
              title: const Text('Mis Lugares'),
              onTap: () {
                Navigator.pop(context);
                if (ModalRoute.of(context)?.settings.name != AppRoutes.experto) {
                  Navigator.pushReplacementNamed(context, AppRoutes.experto);
                }
              },
            ),
          ],

          // Sección de Administración
          if (esAdmin) ...[
            const Padding(
              padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
              child: Text(
                'ADMINISTRACIÓN',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Panel Admin'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, AppRoutes.admin);
              },
            ),
            ListTile(
              leading: const Icon(Icons.comment),
              title: const Text('Moderar Comentarios'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.adminComentarios);
              },
            ),
            ListTile(
              leading: const Icon(Icons.place),
              title: const Text('Gestionar Lugares'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.adminLugares);
              },
            ),
            ListTile(
              leading: const Icon(Icons.route),
              title: const Text('Gestionar Rutas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.adminRutas);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Gestionar Roles'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.adminRoles);
              },
            ),
          ],

          // Sección de Configuración
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              'CONFIGURACIÓN',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.configuracion);
            },
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar Sesión'),
            onTap: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              await AuthService.cerrarSesion();
              
              if (context.mounted) {
                Navigator.pop(context); // Cierra el diálogo
                
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.initial,
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
