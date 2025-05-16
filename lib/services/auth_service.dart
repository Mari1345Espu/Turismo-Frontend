import 'package:shared_preferences/shared_preferences.dart';
import 'logger_service.dart';

class AuthService {
  // Claves para almacenar en SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'auth_email';
  static const String _usernameKey = 'auth_username';
  static const String _rolKey = 'auth_rol';
  static const String _userIdKey = 'auth_userId';

  // Datos de sesión
  static String? token;
  static String? email;
  static String? username;
  static String? rol;
  static String? userId;

  // Iniciar sesión con validación de datos
  static Future<void> iniciarSesion({
    required String t,
    required String e,
    required String u,
    required String? r,
    required String id,
  }) async {
    LoggerService.info('Iniciando sesión para: $u (ID: $id, Rol: $r)');

    if (t.isEmpty) {
      LoggerService.error('Token vacío al iniciar sesión');
      throw Exception('Token de autenticación inválido');
    }

    if (id.isEmpty) {
      LoggerService.error('ID de usuario vacío al iniciar sesión');
      throw Exception('ID de usuario inválido');
    }

    // Normalizar el rol (por defecto 'normal' si es nulo o vacío)
    String role = r?.trim().toLowerCase() ?? 'normal';
    if (role.isEmpty) {
      LoggerService.warning('Rol vacío, estableciendo a "normal"');
      role = 'normal';
    }

    // Validar que el rol sea uno de los permitidos
    if (!['admin', 'experto', 'normal'].contains(role)) {
      LoggerService.warning('Rol desconocido: $role, estableciendo a "normal"');
      role = 'normal';
    }

    // Establecer en memoria
    token = t;
    email = e;
    username = u;
    rol = role;
    userId = id;

    // Guardar en almacenamiento persistente
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, t);
      await prefs.setString(_emailKey, e);
      await prefs.setString(_usernameKey, u);
      await prefs.setString(_rolKey, role);
      await prefs.setString(_userIdKey, id);

      LoggerService.info(
          'Sesión guardada correctamente en almacenamiento persistente');
    } catch (e) {
      LoggerService.error('Error al guardar sesión en SharedPreferences', e);
    }

    LoggerService.info(
        'Sesión iniciada correctamente para: $username (rol: $rol)');
  }

  // Cargar sesión desde almacenamiento persistente
  static Future<bool> cargarSesion() async {
    try {
      LoggerService.info('Intentando cargar sesión guardada');
      final prefs = await SharedPreferences.getInstance();

      final savedToken = prefs.getString(_tokenKey);
      if (savedToken == null || savedToken.isEmpty) {
        LoggerService.info('No hay sesión guardada');
        return false;
      }

      token = savedToken;
      email = prefs.getString(_emailKey);
      username = prefs.getString(_usernameKey);
      rol = prefs.getString(_rolKey) ?? 'normal';
      userId = prefs.getString(_userIdKey);

      LoggerService.info('Sesión cargada: usuario=$username, rol=$rol');
      return true;
    } catch (e) {
      LoggerService.error('Error al cargar sesión', e);
      return false;
    }
  }

  // Cerrar sesión
  static Future<void> cerrarSesion() async {
    LoggerService.info('Cerrando sesión para: $username');

    // Limpiar datos en memoria
    token = null;
    email = null;
    username = null;
    rol = null;
    userId = null;

    // Limpiar datos persistentes
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_usernameKey);
      await prefs.remove(_rolKey);
      await prefs.remove(_userIdKey);

      LoggerService.info(
          'Datos de sesión eliminados del almacenamiento persistente');
    } catch (e) {
      LoggerService.error('Error al eliminar datos de sesión persistentes', e);
    }

    LoggerService.info('Sesión cerrada correctamente');
  }

  // Getters para verificar estado de autenticación y roles
  static bool get estaAutenticado => token != null && token!.isNotEmpty;

  static bool get esAdmin =>
      estaAutenticado && rol != null && rol!.toLowerCase() == 'admin';

  static bool get esExperto =>
      estaAutenticado && rol != null && rol!.toLowerCase() == 'experto';

  static bool get esNormal =>
      estaAutenticado &&
      rol != null &&
      (rol!.toLowerCase() == 'normal' || (!esAdmin && !esExperto));

  // Método para depurar información de la sesión actual
  static Map<String, dynamic> debugInfo() {
    return {
      'estaAutenticado': estaAutenticado,
      'token': token != null
          ? '${token!.substring(0, min(10, token!.length))}...'
          : null,
      'email': email,
      'username': username,
      'rol': rol,
      'userId': userId,
      'esAdmin': esAdmin,
      'esExperto': esExperto,
      'esNormal': esNormal,
    };
  }

  // Método auxiliar para truncar strings
  static int min(int a, int b) => a < b ? a : b;
}
