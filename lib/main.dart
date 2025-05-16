import 'package:flutter/material.dart';
import 'routes/app_routes.dart';
import 'services/auth_service.dart';
import 'services/logger_service.dart';
import 'services/config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa el servicio de logs
  await LoggerService.init();
  
  // Inicializa el servicio de configuración
  await ConfigService.init();
  LoggerService.info('ConfigService inicializado con URL del servidor: ${ConfigService.serverUrl}');
  
  // Intenta cargar la sesión guardada
  final bool sesionCargada = await AuthService.cargarSesion();
  LoggerService.info('Iniciando aplicación. Sesión cargada: $sesionCargada');
  
  runApp(const RutasAndinasApp());
}

class RutasAndinasApp extends StatelessWidget {
  const RutasAndinasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rutas Andinas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      initialRoute: AuthService.estaAutenticado ? _getInitialRoute() : AppRoutes.initial,
      routes: AppRoutes.routes,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
  
  // Determina la ruta inicial según el rol del usuario
  String _getInitialRoute() {
    if (AuthService.esAdmin) {
      return AppRoutes.admin;
    } else if (AuthService.esExperto) {
      return AppRoutes.experto;
    } else {
      return AppRoutes.usuario;
    }
  }
}
