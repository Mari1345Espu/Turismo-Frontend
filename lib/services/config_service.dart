import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'logger_service.dart';

class ConfigService {
  static const String _urlKey = 'server_url';
  
  // URL del servidor actual
  static String _serverUrl = baseURL;
  
  // Getter para obtener la URL actual
  static String get serverUrl => _serverUrl;
  static String get authUrl => '${_serverUrl}auth/';
  static String get lugaresUrl => '${_serverUrl}lugares/';
  static String get favoritosUrl => '${_serverUrl}favoritos/';
  
  // Inicializa el servicio y carga la URL guardada
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_urlKey);
      
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _serverUrl = savedUrl;
        LoggerService.info('URL del servidor cargada: $_serverUrl');
      } else {
        // Si no hay URL guardada, usar la del config.dart
        _serverUrl = baseURL;
        LoggerService.info('Usando URL del servidor por defecto: $_serverUrl');
      }
    } catch (e) {
      LoggerService.error('Error al cargar la configuración del servidor', e);
      _serverUrl = baseURL;
    }
  }
  
  // Cambia la URL del servidor y la guarda
  static Future<void> setServerUrl(String url) async {
    // Asegurarse de que la URL termina con /
    if (!url.endsWith('/')) {
      url += '/';
    }
    
    // Asegurarse de que termina con api/
    if (!url.endsWith('api/')) {
      if (!url.endsWith('api')) {
        url += 'api/';
      } else {
        url += '/';
      }
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_urlKey, url);
      _serverUrl = url;
      LoggerService.info('URL del servidor actualizada: $_serverUrl');
    } catch (e) {
      LoggerService.error('Error al guardar la URL del servidor', e);
      throw Exception('No se pudo guardar la configuración del servidor: $e');
    }
  }
  
  // Restaura la URL por defecto
  static Future<void> resetServerUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_urlKey);
      _serverUrl = baseURL;
      LoggerService.info('URL del servidor restaurada al valor por defecto: $_serverUrl');
    } catch (e) {
      LoggerService.error('Error al restaurar la URL del servidor', e);
      throw Exception('No se pudo restaurar la configuración del servidor: $e');
    }
  }
} 