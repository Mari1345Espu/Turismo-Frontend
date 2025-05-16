import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config_service.dart';
import 'auth_service.dart';
import 'logger_service.dart';

class ApiService {
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (AuthService.token != null)
          'Authorization': 'Token ${AuthService.token}',
      };

  // Auth endpoints
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      // Validar entradas
      if (email.isEmpty || password.isEmpty) {
        LoggerService.warning('Intento de login con credenciales vacías');
        throw Exception('El correo y la contraseña son obligatorios');
      }

      LoggerService.info('Intentando iniciar sesión con email: $email');
      LoggerService.debug(
          'URL de autenticación: ${ConfigService.authUrl}token/login/');

      // Verificar conexión primero
      try {
        // Determinar qué host verificar según la URL
        final Uri uri = Uri.parse(ConfigService.serverUrl);
        final String host = uri.host;

        LoggerService.debug('Verificando conectividad con el servidor: $host');

        // Intenta una conexión con un límite de tiempo corto para verificar
        final connectionTestResponse = await http
            .get(
          Uri.parse(ConfigService.serverUrl),
        )
            .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw Exception(
                'No se puede conectar al servidor. Verifica que el servidor esté en ejecución y la URL sea correcta.');
          },
        );

        LoggerService.debug(
            'Conexión con el servidor exitosa: ${connectionTestResponse.statusCode}');
      } catch (e) {
        LoggerService.error('Error al conectar con el servidor', e);
        // Si el error no es de timeout, propagar el error
        if (!e.toString().contains('timeout')) {
          throw Exception(
              'No se puede conectar al servidor. Verifica tu conexión a internet y la URL del servidor: ${ConfigService.serverUrl}. Error: $e');
        }
      }

      // 1. Obtener token
      final response = await http
          .post(
        Uri.parse('${ConfigService.authUrl}token/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          LoggerService.error('Timeout en la solicitud de login');
          throw Exception(
              'Tiempo de espera agotado (30 segundos). Verifica tu conexión a internet y que el servidor esté funcionando en ${ConfigService.serverUrl}');
        },
      );

      LoggerService.debug(
          'Respuesta del servidor (login): ${response.statusCode}');
      LoggerService.debug('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Verificar que el token existe en la respuesta
        final token = responseData['auth_token'];
        if (token == null || token.toString().isEmpty) {
          LoggerService.error(
              'Token no encontrado en la respuesta: $responseData');
          throw Exception('Token no encontrado en la respuesta del servidor');
        }

        LoggerService.info('Token obtenido, solicitando datos del usuario...');

        // 2. Obtener perfil con el token
        final userRes = await http.get(
          Uri.parse('${ConfigService.serverUrl}usuarios/perfil/'),
          headers: {'Authorization': 'Token $token'},
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            LoggerService.error('Timeout en la solicitud de perfil');
            throw Exception(
                'Tiempo de espera agotado al obtener perfil de usuario. Verifica la conexión al servidor.');
          },
        );

        LoggerService.debug(
            'Respuesta del servidor (perfil): ${userRes.statusCode}');
        LoggerService.debug('Cuerpo de la respuesta: ${userRes.body}');

        if (userRes.statusCode == 200) {
          final userData = jsonDecode(userRes.body);
          LoggerService.info('Datos del usuario obtenidos: $userData');

          // Validar campos obligatorios
          if (userData['id'] == null) {
            LoggerService.error(
                'ID de usuario no encontrado en la respuesta: $userData');
            throw Exception('Datos de usuario incompletos: ID no encontrado');
          }

          // Iniciar sesión con los datos obtenidos (ahora con await)
          try {
            await AuthService.iniciarSesion(
              t: token,
              e: userData['email'] ?? email,
              u: userData['username'] ?? email.split('@')[0],
              r: userData['rol'],
              id: userData['id'].toString(),
            );

            LoggerService.info('Sesión iniciada correctamente');
            return userData;
          } catch (e) {
            LoggerService.error(
                'Error al iniciar sesión con los datos obtenidos', e);
            throw Exception('Error al procesar los datos de usuario: $e');
          }
        } else if (userRes.statusCode == 401) {
          LoggerService.warning('Token inválido al obtener perfil: $token');
          throw Exception('Token inválido o expirado');
        } else {
          LoggerService.error('Error al obtener perfil: ${userRes.statusCode}');
          try {
            final errorBody = jsonDecode(userRes.body);
            LoggerService.error('Cuerpo del error: $errorBody');
            throw Exception(
                'Error al obtener datos del usuario: ${errorBody['detail'] ?? userRes.statusCode}');
          } catch (e) {
            throw Exception(
                'Error al obtener datos del usuario: ${userRes.statusCode}');
          }
        }
      } else if (response.statusCode == 400) {
        LoggerService.warning('Credenciales inválidas para: $email');
        try {
          final errorBody = jsonDecode(response.body);
          if (errorBody.containsKey('non_field_errors')) {
            throw Exception(errorBody['non_field_errors'][0]);
          } else if (errorBody.containsKey('email')) {
            throw Exception('Email: ${errorBody['email'][0]}');
          } else if (errorBody.containsKey('password')) {
            throw Exception('Contraseña: ${errorBody['password'][0]}');
          }
          throw Exception('Credenciales inválidas');
        } catch (e) {
          throw Exception('Credenciales inválidas');
        }
      } else if (response.statusCode == 401) {
        LoggerService.warning('No autorizado para: $email');
        throw Exception('No autorizado');
      } else {
        LoggerService.error('Error en autenticación: ${response.statusCode}');
        throw Exception('Error en la autenticación: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error en login', e);
      if (e is FormatException) {
        throw Exception('Error al procesar la respuesta del servidor');
      } else if (e.toString().contains('SocketException')) {
        throw Exception(
            'No se puede conectar al servidor. Verifica tu conexión a internet y que el servidor esté funcionando en ${ConfigService.serverUrl}');
      } else if (e.toString().contains('HandshakeException')) {
        throw Exception(
            'Error de seguridad en la conexión. Verifica la configuración SSL del servidor.');
      } else if (e is Exception) {
        throw e;
      }
      throw Exception('Error en la autenticación: $e');
    }
  }

  // Registro de usuarios
  static Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    try {
      // Validar entradas
      if (username.isEmpty || email.isEmpty || password.isEmpty) {
        LoggerService.warning('Intento de registro con datos incompletos');
        throw Exception('Todos los campos son obligatorios');
      }

      LoggerService.info('Intentando registrar usuario: $email');
      LoggerService.debug('URL de registro: ${ConfigService.authUrl}users/');

      // Enviar solicitud de registro
      final response = await http
          .post(
        Uri.parse('${ConfigService.authUrl}users/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'email': email.trim(),
          'password': password.trim(),
          'rol': 'normal' // Por defecto, todos los usuarios nuevos son "normal"
        }),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          LoggerService.error('Timeout en la solicitud de registro');
          throw Exception(
              'Tiempo de espera agotado. Verifica tu conexión a internet.');
        },
      );

      LoggerService.debug(
          'Respuesta del servidor (registro): ${response.statusCode}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        LoggerService.info('Usuario registrado exitosamente: $email');
        return responseData;
      } else if (response.statusCode == 400) {
        // Manejar errores de validación
        final errorData = jsonDecode(response.body);
        String errorMsg = 'Error en el registro:';

        if (errorData.containsKey('email')) {
          errorMsg += ' Email: ${errorData['email'][0]}';
        }
        if (errorData.containsKey('username')) {
          errorMsg += ' Usuario: ${errorData['username'][0]}';
        }
        if (errorData.containsKey('password')) {
          errorMsg += ' Contraseña: ${errorData['password'][0]}';
        }
        if (errorData.containsKey('non_field_errors')) {
          errorMsg += ' ${errorData['non_field_errors'][0]}';
        }

        LoggerService.warning('Error de validación en registro: $errorData');
        throw Exception(errorMsg);
      } else {
        LoggerService.error('Error en registro: ${response.statusCode}');
        throw Exception('Error en el registro: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error en registro', e);
      if (e is Exception) {
        throw e;
      }
      throw Exception('Error en el registro: $e');
    }
  }

  // Cambio de contraseña
  static Future<void> changePassword(
      String currentPassword, String newPassword) async {
    if (!AuthService.estaAutenticado) {
      LoggerService.warning('Intento de cambiar contraseña sin autenticación');
      throw Exception('Debes iniciar sesión para cambiar tu contraseña');
    }

    try {
      LoggerService.info(
          'Intentando cambiar contraseña para: ${AuthService.username}');

      final response = await http
          .post(
        Uri.parse('${ConfigService.authUrl}password/change/'),
        headers: {
          'Authorization': 'Token ${AuthService.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_password': currentPassword.trim(),
          'new_password': newPassword.trim(),
        }),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          LoggerService.error(
              'Timeout en la solicitud de cambio de contraseña');
          throw Exception(
              'Tiempo de espera agotado. Verifica tu conexión a internet.');
        },
      );

      LoggerService.debug(
          'Respuesta del servidor (cambio contraseña): ${response.statusCode}');

      if (response.statusCode == 204) {
        LoggerService.info('Contraseña actualizada correctamente');
        return;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        String errorMsg = 'Error al cambiar contraseña:';

        if (errorData.containsKey('current_password')) {
          errorMsg += ' Contraseña actual: ${errorData['current_password'][0]}';
        }
        if (errorData.containsKey('new_password')) {
          errorMsg += ' Nueva contraseña: ${errorData['new_password'][0]}';
        }

        LoggerService.warning('Error en cambio de contraseña: $errorData');
        throw Exception(errorMsg);
      } else if (response.statusCode == 401) {
        LoggerService.warning('Error de autenticación al cambiar contraseña');
        throw Exception('No autorizado. Por favor, inicia sesión nuevamente.');
      } else {
        LoggerService.error(
            'Error al cambiar contraseña: ${response.statusCode}');
        throw Exception(
            'Error al cambiar la contraseña: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error al cambiar contraseña', e);
      if (e is Exception) {
        throw e;
      }
      throw Exception('Error al cambiar la contraseña: $e');
    }
  }

  // Recuperación de contraseña
  static Future<void> requestPasswordReset(String email) async {
    try {
      LoggerService.info('Solicitando recuperación de contraseña para: $email');

      final response = await http
          .post(
        Uri.parse('${ConfigService.authUrl}password/reset/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim()}),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          LoggerService.error(
              'Timeout en la solicitud de recuperación de contraseña');
          throw Exception(
              'Tiempo de espera agotado. Verifica tu conexión a internet.');
        },
      );

      LoggerService.debug(
          'Respuesta del servidor (recuperación contraseña): ${response.statusCode}');

      if (response.statusCode == 204) {
        LoggerService.info('Solicitud de recuperación enviada correctamente');
        return;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        LoggerService.warning(
            'Error en recuperación de contraseña: $errorData');
        throw Exception(
            'Error: ${errorData['email']?[0] ?? 'Correo inválido'}');
      } else {
        LoggerService.error(
            'Error en recuperación de contraseña: ${response.statusCode}');
        throw Exception(
            'Error al procesar la solicitud: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error al solicitar recuperación de contraseña', e);
      if (e is Exception) {
        throw e;
      }
      throw Exception('Error al solicitar recuperación: $e');
    }
  }

  // Reset de contraseña con token
  static Future<void> resetPassword(
      String uid, String token, String newPassword) async {
    try {
      LoggerService.info('Intentando restablecer contraseña con token');

      final response = await http
          .post(
        Uri.parse('${ConfigService.authUrl}password/reset/confirm/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': uid,
          'token': token,
          'new_password': newPassword.trim(),
        }),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          LoggerService.error(
              'Timeout en la solicitud de restablecimiento de contraseña');
          throw Exception(
              'Tiempo de espera agotado. Verifica tu conexión a internet.');
        },
      );

      LoggerService.debug(
          'Respuesta del servidor (reset contraseña): ${response.statusCode}');

      if (response.statusCode == 204) {
        LoggerService.info('Contraseña restablecida correctamente');
        return;
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        LoggerService.warning(
            'Error en restablecimiento de contraseña: $errorData');
        throw Exception(
            'Error: ${errorData['token'] ?? errorData['new_password'] ?? 'Token inválido o expirado'}');
      } else {
        LoggerService.error(
            'Error en restablecimiento de contraseña: ${response.statusCode}');
        throw Exception(
            'Error al restablecer la contraseña: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error al restablecer contraseña', e);
      if (e is Exception) {
        throw e;
      }
      throw Exception('Error al restablecer la contraseña: $e');
    }
  }

  // Lugares endpoints
  static Future<List<dynamic>> getLugares({String? categoria}) async {
    try {
      LoggerService.info(
          'Solicitando lugares. Categoría: ${categoria ?? 'todas'}');

      final url = categoria != null && categoria != 'todas'
          ? '${ConfigService.lugaresUrl}?categoria=$categoria'
          : ConfigService.lugaresUrl;

      LoggerService.debug('URL de la solicitud: $url');

      final response = await http.get(Uri.parse(url), headers: _headers);

      LoggerService.debug('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        LoggerService.info('Lugares obtenidos: ${data.length}');
        return data;
      }

      throw Exception('Error al cargar lugares: ${response.body}');
    } catch (e) {
      LoggerService.error('Error al cargar lugares', e);
      throw Exception('Error al cargar lugares: $e');
    }
  }

  static Future<Map<String, dynamic>> getLugarById(int id) async {
    try {
      LoggerService.info('Solicitando lugar con ID: $id');
      LoggerService.debug('Token de autorización: ${AuthService.token}');

      final response = await http.get(
        Uri.parse('${ConfigService.lugaresUrl}$id/'),
        headers: _headers,
      );

      LoggerService.debug('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        LoggerService.debug('Datos del lugar obtenidos: $data');
        return data;
      }

      throw Exception('Error al cargar lugar: ${response.statusCode}');
    } catch (e) {
      LoggerService.error('Error al cargar lugar', e);
      throw Exception('Error al cargar lugar: $e');
    }
  }

  static Future<void> eliminarLugar(int id) async {
    if (!AuthService.estaAutenticado) {
      throw Exception('Usuario no autenticado');
    }

    // Solo expertos y administradores pueden eliminar lugares
    if (!AuthService.esExperto && !AuthService.esAdmin) {
      throw Exception('No tienes permisos para eliminar lugares');
    }

    try {
      LoggerService.info('Eliminando lugar con ID: $id');

      final response = await http.delete(
        Uri.parse('${ConfigService.lugaresUrl}$id/'),
        headers: _headers,
      );

      LoggerService.debug('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 204) {
        LoggerService.info('Lugar eliminado exitosamente');
        return;
      }

      // Manejar códigos de error específicos
      if (response.statusCode == 403) {
        throw Exception('No tienes permisos para eliminar este lugar');
      } else if (response.statusCode == 404) {
        throw Exception('Lugar no encontrado');
      }

      throw Exception('Error al eliminar lugar: ${response.statusCode}');
    } catch (e) {
      LoggerService.error('Error al eliminar lugar', e);
      throw Exception('Error al eliminar lugar: $e');
    }
  }

  static Future<void> actualizarLugar(int id, Map<String, dynamic> data) async {
    if (!AuthService.estaAutenticado) {
      throw Exception('Usuario no autenticado');
    }

    // Solo expertos y administradores pueden actualizar lugares
    if (!AuthService.esExperto && !AuthService.esAdmin) {
      throw Exception('No tienes permisos para actualizar lugares');
    }

    try {
      LoggerService.info(
          'Actualizando lugar con ID: $id - Datos: ${jsonEncode(data)}');

      final response = await http.patch(
        Uri.parse('${ConfigService.lugaresUrl}$id/'),
        headers: _headers,
        body: jsonEncode(data),
      );

      LoggerService.debug('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        LoggerService.info('Lugar actualizado exitosamente');
        return;
      }

      // Manejar códigos de error específicos
      if (response.statusCode == 403) {
        throw Exception('No tienes permisos para actualizar este lugar');
      } else if (response.statusCode == 404) {
        throw Exception('Lugar no encontrado');
      }

      throw Exception('Error al actualizar lugar: ${response.statusCode}');
    } catch (e) {
      LoggerService.error('Error al actualizar lugar', e);
      throw Exception('Error al actualizar lugar: $e');
    }
  }

  // Comentarios endpoints
  static Future<List<dynamic>> getComentarios(int lugarId) async {
    try {
      final response = await http.get(
        Uri.parse('${ConfigService.serverUrl}comentarios/?lugar=$lugarId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final comentarios = jsonDecode(response.body);
        // Ordenar comentarios por fecha de creación (más recientes primero)
        comentarios.sort((a, b) {
          final fechaA =
              DateTime.tryParse(a['fecha_creacion'] ?? '') ?? DateTime(1900);
          final fechaB =
              DateTime.tryParse(b['fecha_creacion'] ?? '') ?? DateTime(1900);
          return fechaB.compareTo(fechaA);
        });
        return comentarios;
      }

      throw Exception('Error ${response.statusCode}: ${response.body}');
    } catch (e) {
      throw Exception('Error al cargar comentarios: $e');
    }
  }

  static Future<Map<String, dynamic>> crearComentario({
    required int lugarId,
    required String texto,
    required int calificacion,
  }) async {
    try {
      if (!AuthService.estaAutenticado) {
        throw Exception('Debes iniciar sesión para comentar');
      }

      LoggerService.info('Creando comentario para lugar $lugarId');
      LoggerService.debug(
          'Datos del comentario: texto=$texto, calificación=$calificacion');

      final response = await http.post(
        Uri.parse('${ConfigService.serverUrl}comentarios/'),
        headers: _headers,
        body: jsonEncode({
          'lugar': lugarId,
          'texto': texto,
          'calificacion': calificacion,
        }),
      );

      LoggerService.debug('Respuesta del servidor: ${response.statusCode}');
      LoggerService.debug('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        LoggerService.info('Comentario creado exitosamente');
        return data;
      }

      final errorData = jsonDecode(response.body);
      final errorMsg = errorData['detail'] ?? 'Error desconocido';
      LoggerService.error('Error al crear comentario: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      LoggerService.error('Error al crear comentario', e);
      throw Exception('Error al crear comentario: $e');
    }
  }

  static Future<Map<String, dynamic>> editarComentario({
    required int comentarioId,
    required String texto,
    required int calificacion,
  }) async {
    try {
      if (!AuthService.estaAutenticado) {
        throw Exception('Debes iniciar sesión para editar comentarios');
      }

      LoggerService.info('Editando comentario $comentarioId');

      final response = await http.put(
        Uri.parse('${ConfigService.serverUrl}comentarios/$comentarioId/'),
        headers: _headers,
        body: jsonEncode({
          'texto': texto,
          'calificacion': calificacion,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        LoggerService.info('Comentario editado exitosamente');
        return data;
      }

      final errorData = jsonDecode(response.body);
      final errorMsg = errorData['detail'] ?? 'Error desconocido';
      LoggerService.error('Error al editar comentario: $errorMsg');
      throw Exception(errorMsg);
    } catch (e) {
      LoggerService.error('Error al editar comentario', e);
      throw Exception('Error al editar comentario: $e');
    }
  }

  static Future<void> eliminarComentario(int comentarioId) async {
    try {
      if (!AuthService.estaAutenticado) {
        throw Exception('Debes iniciar sesión para eliminar comentarios');
      }

      LoggerService.info('Eliminando comentario $comentarioId');

      final response = await http.delete(
        Uri.parse('${ConfigService.serverUrl}comentarios/$comentarioId/'),
        headers: _headers,
      );

      if (response.statusCode == 204) {
        LoggerService.info('Comentario eliminado exitosamente');
        return;
      }

      LoggerService.error(
          'Error al eliminar comentario: ${response.statusCode}');
      throw Exception('Error al eliminar comentario');
    } catch (e) {
      LoggerService.error('Error al eliminar comentario', e);
      throw Exception('Error al eliminar comentario: $e');
    }
  }

  /**  Favoritos endpoints
  static Future<List<dynamic>> getFavoritos() async {
    try {
      if (!AuthService.estaAutenticado) {
        throw Exception('No autorizado');
      }

      LoggerService.info(
          'Solicitando favoritos del usuario: ${AuthService.userId}');
      LoggerService.debug('Token de autorización: ${AuthService.token}');

      final response = await http.get(
        Uri.parse('${ConfigService.favoritosUrl}'),
        headers: _headers,
      );

      LoggerService.debug('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        LoggerService.info('Favoritos obtenidos: ${data.length}');
        return data;
      }

      throw Exception('Error al cargar favoritos: ${response.statusCode}');
    } catch (e) {
      LoggerService.error('Error al cargar favoritos', e);
      throw Exception('Error al cargar favoritos: $e');
    }
  }**/
  
  static Future<void> toggleFavorito(int lugarId) async {
    try {
      LoggerService.info('Iniciando toggle de favorito para lugar $lugarId');

      final esFav = await esFavorito(lugarId);
      LoggerService.debug(
          'El lugar ${esFav ? 'será eliminado de' : 'será agregado a'} favoritos');

      final response = esFav
          ? await http.delete(
              Uri.parse('${ConfigService.favoritosUrl}$lugarId/'),
              headers: _headers,
            )
          : await http.post(
              Uri.parse(ConfigService.favoritosUrl),
              headers: _headers,
              body: jsonEncode({'lugar': lugarId}),
            );

      LoggerService.debug('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 204) {
        throw Exception(
            'Error al ${esFav ? 'eliminar de' : 'agregar a'} favoritos: ${response.statusCode}');
      }

      LoggerService.info('Operación de favorito completada exitosamente');
    } catch (e) {
      LoggerService.error('Error en toggleFavorito', e);
      throw Exception('Error al gestionar favorito: $e');
    }
  }

  // Rutas endpoints
  static Future<List<dynamic>> getRutas() async {
    try {
      LoggerService.info('Solicitando rutas sugeridas');

      final response = await http.get(
        Uri.parse('${ConfigService.serverUrl}rutas/'),
        headers: _headers,
      );

      LoggerService.debug(
          'Respuesta del servidor (rutas): ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        LoggerService.info('Rutas obtenidas: ${data.length}');
        return data;
      }

      throw Exception(
          'Error al cargar rutas: ${response.statusCode} - ${response.body}');
    } catch (e) {
      LoggerService.error('Error al cargar rutas', e);
      throw Exception('Error al cargar rutas: $e');
    }
  }

  static Future<Map<String, dynamic>> crearRuta(
      Map<String, dynamic> rutaData) async {
    if (!AuthService.estaAutenticado) {
      throw Exception('Usuario no autenticado');
    }

    if (!AuthService.esExperto) {
      throw Exception('No tienes permisos de experto');
    }

    try {
      LoggerService.info('Intentando crear ruta: ${jsonEncode(rutaData)}');
      LoggerService.debug('URL: ${ConfigService.serverUrl}rutas/');
      LoggerService.debug('Headers: ${_headers}');

      // Validar que tenga nombre, descripción y al menos un lugar
      if (rutaData['nombre'] == null || rutaData['nombre'].toString().isEmpty) {
        throw Exception('El nombre de la ruta es obligatorio');
      }

      if (rutaData['descripcion'] == null ||
          rutaData['descripcion'].toString().isEmpty) {
        throw Exception('La descripción de la ruta es obligatoria');
      }

      if (rutaData['lugares'] == null ||
          (rutaData['lugares'] as List).isEmpty) {
        throw Exception('Debes seleccionar al menos un lugar para la ruta');
      }

      final response = await http.post(
        Uri.parse('${ConfigService.serverUrl}rutas/'),
        headers: _headers,
        body: jsonEncode(rutaData),
      );

      LoggerService.debug('Respuesta del servidor: ${response.statusCode}');
      LoggerService.debug('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        LoggerService.info('Ruta creada exitosamente con ID: ${data['id']}');
        return data;
      }

      // Manejar respuestas de error específicas
      if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        String errorMessage = 'Error de validación:';

        // Extraer mensajes de error detallados
        error.forEach((key, value) {
          if (value is List) {
            errorMessage += '\n• $key: ${value.join(', ')}';
          } else {
            errorMessage += '\n• $key: $value';
          }
        });

        LoggerService.error('Error de validación al crear ruta', error);
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Inicia sesión nuevamente.');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos para crear rutas.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
            error['detail'] ?? 'Error al crear ruta: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error al crear ruta', e);
      if (e is FormatException) {
        throw Exception('Error al procesar la respuesta del servidor');
      } else if (e.toString().contains('SocketException')) {
        throw Exception(
            'No se puede conectar al servidor. Verifica tu conexión a internet.');
      }
      throw Exception('Error al crear ruta: $e');
    }
  }

  static Future<Map<String, dynamic>> getRutaById(int id) async {
    try {
      LoggerService.info('Solicitando ruta con ID: $id');

      final response = await http.get(
        Uri.parse('${ConfigService.serverUrl}rutas/$id/'),
        headers: _headers,
      );

      LoggerService.debug('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        LoggerService.info('Datos de la ruta obtenidos para ID: $id');
        return data;
      }

      if (response.statusCode == 404) {
        throw Exception('Ruta no encontrada');
      }

      throw Exception('Error al cargar la ruta: ${response.statusCode}');
    } catch (e) {
      LoggerService.error('Error al cargar ruta', e);
      throw Exception('Error al cargar detalles de la ruta: $e');
    }
  }

  static Future<List<dynamic>> getRutasExperto() async {
    // Verificar autenticación
    if (!AuthService.estaAutenticado) {
      LoggerService.error(
          'Intento de acceder a rutas de experto sin autenticación');
      throw Exception(
          'Usuario no autenticado. Por favor inicia sesión nuevamente.');
    }

    // Verificar rol
    if (!AuthService.esExperto) {
      LoggerService.error(
          'Usuario con rol ${AuthService.rol} intentando acceder a función de experto');
      throw Exception(
          'No tienes permisos de experto. Tu rol actual es: ${AuthService.rol ?? "no definido"}');
    }

    // Verificar que tengamos userId
    if (AuthService.userId == null || AuthService.userId!.isEmpty) {
      LoggerService.error('ID de usuario no disponible para búsqueda de rutas');
      throw Exception(
          'ID de usuario no disponible. Por favor inicia sesión nuevamente.');
    }

    try {
      LoggerService.info(
          'Solicitando rutas creadas por el experto: ${AuthService.username}');

      // Primero intentamos con el endpoint específico
      try {
        final response = await http.get(
          Uri.parse('${ConfigService.serverUrl}rutas/mis-rutas/'),
          headers: _headers,
        );

        LoggerService.debug(
            'Respuesta del servidor mis-rutas: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          LoggerService.info('Rutas obtenidas desde mis-rutas: ${data.length}');
          return data;
        }

        // Si no existe el endpoint específico, intentamos con el filtro general
        if (response.statusCode == 404) {
          LoggerService.warning(
              'Endpoint mis-rutas no encontrado, intentando filtro por creador');
        } else {
          throw Exception('Error al obtener rutas: ${response.statusCode}');
        }
      } catch (e) {
        LoggerService.warning(
            'Error con endpoint mis-rutas, intentando filtro alternativo. ${e.toString()}');
      }

      // Intentamos con filtro por creador
      final response = await http.get(
        Uri.parse(
            '${ConfigService.serverUrl}rutas/?creador=${AuthService.userId}'),
        headers: _headers,
      );

      LoggerService.debug(
          'Respuesta del servidor (filtro por creador): ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        LoggerService.info(
            'Rutas obtenidas por filtro de creador: ${data.length}');
        return data;
      }

      throw Exception('Error al cargar rutas: ${response.statusCode}');
    } catch (e) {
      LoggerService.error('Error al cargar rutas del experto', e);
      throw Exception('Error al cargar rutas: $e');
    }
  }

  static Future<Map<String, dynamic>> editarRuta(
      int id, Map<String, dynamic> rutaData) async {
    if (!AuthService.estaAutenticado) {
      throw Exception('Usuario no autenticado');
    }

    if (!AuthService.esExperto) {
      throw Exception('No tienes permisos de experto');
    }

    try {
      LoggerService.info(
          'Enviando actualización para ruta $id: ${jsonEncode(rutaData)}');

      // Validar datos mínimos
      if (rutaData['nombre'] == null || rutaData['nombre'].toString().isEmpty) {
        throw Exception('El nombre de la ruta es obligatorio');
      }

      if (rutaData['descripcion'] == null ||
          rutaData['descripcion'].toString().isEmpty) {
        throw Exception('La descripción de la ruta es obligatoria');
      }

      if (rutaData['lugares'] == null ||
          (rutaData['lugares'] as List).isEmpty) {
        throw Exception('Debes seleccionar al menos un lugar para la ruta');
      }

      final response = await http.put(
        Uri.parse('${ConfigService.serverUrl}rutas/$id/'),
        headers: _headers,
        body: jsonEncode(rutaData),
      );

      LoggerService.debug('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        LoggerService.info('Ruta actualizada exitosamente');
        return data;
      }

      // Manejar errores específicos
      if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        String errorMessage = 'Error de validación:';

        error.forEach((key, value) {
          if (value is List) {
            errorMessage += '\n• $key: ${value.join(', ')}';
          } else {
            errorMessage += '\n• $key: $value';
          }
        });

        throw Exception(errorMessage);
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos para editar esta ruta');
      } else if (response.statusCode == 404) {
        throw Exception('Ruta no encontrada');
      }

      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al actualizar ruta');
    } catch (e) {
      LoggerService.error('Error al actualizar ruta', e);
      throw Exception('Error al actualizar ruta: $e');
    }
  }

  static Future<void> eliminarRuta(int id) async {
    if (!AuthService.estaAutenticado) {
      throw Exception('Usuario no autenticado');
    }

    if (!AuthService.esExperto) {
      throw Exception('No tienes permisos de experto');
    }

    try {
      LoggerService.info('Eliminando ruta con ID: $id');

      final response = await http.delete(
        Uri.parse('${ConfigService.serverUrl}rutas/$id/'),
        headers: _headers,
      );

      LoggerService.debug('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 204) {
        LoggerService.info('Ruta eliminada exitosamente');
        return;
      }

      if (response.statusCode == 403) {
        throw Exception('No tienes permisos para eliminar esta ruta');
      } else if (response.statusCode == 404) {
        throw Exception('Ruta no encontrada');
      }

      throw Exception('Error al eliminar ruta: ${response.statusCode}');
    } catch (e) {
      LoggerService.error('Error al eliminar ruta', e);
      throw Exception('Error al eliminar ruta: $e');
    }
  }

  static Future<void> actualizarRuta(int id, Map<String, dynamic> data) async {
    if (!AuthService.estaAutenticado) {
      throw Exception('Usuario no autenticado');
    }

    if (!AuthService.esAdmin) {
      throw Exception('No tienes permisos de administrador');
    }

    try {
      LoggerService.info(
          'Actualizando ruta con ID: $id - Datos: ${jsonEncode(data)}');

      final response = await http.patch(
        Uri.parse('${ConfigService.serverUrl}rutas/$id/'),
        headers: _headers,
        body: jsonEncode(data),
      );

      LoggerService.debug('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        LoggerService.info('Ruta actualizada exitosamente');
        return;
      }

      if (response.statusCode == 403) {
        throw Exception('No tienes permisos para actualizar esta ruta');
      } else if (response.statusCode == 404) {
        throw Exception('Ruta no encontrada');
      }

      throw Exception('Error al actualizar ruta: ${response.statusCode}');
    } catch (e) {
      LoggerService.error('Error al actualizar ruta', e);
      throw Exception('Error al actualizar ruta: $e');
    }
  }

  // Admin endpoints
  static Future<List<dynamic>> getUsuarios() async {
    final response = await http.get(
      Uri.parse('${baseURL}usuarios/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al cargar usuarios');
  }

  static Future<void> cambiarRolUsuario(int userId, String nuevoRol) async {
    final response = await http.patch(
      Uri.parse('${baseURL}usuarios/$userId/'),
      headers: _headers,
      body: jsonEncode({'rol': nuevoRol}),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al cambiar rol');
    }
  }

  // Experto endpoints
  static Future<Map<String, dynamic>> crearLugar(
      Map<String, dynamic> lugarData) async {
    if (!AuthService.estaAutenticado) {
      throw Exception('Usuario no autenticado');
    }

    if (!AuthService.esExperto) {
      throw Exception('No tienes permisos de experto');
    }

    try {
      LoggerService.info('Intentando crear lugar: ${jsonEncode(lugarData)}');
      LoggerService.debug('URL: ${ConfigService.lugaresUrl}');
      LoggerService.debug('Headers: ${_headers}');

      // Validar que la latitud y longitud sean valores numéricos
      if (lugarData['latitud'] == null || lugarData['longitud'] == null) {
        throw Exception('La latitud y longitud son obligatorias');
      }

      // Asegurar que latitud y longitud sean números válidos
      if (lugarData['latitud'] is String) {
        lugarData['latitud'] = double.tryParse(lugarData['latitud']) ?? 0.0;
      }
      if (lugarData['longitud'] is String) {
        lugarData['longitud'] = double.tryParse(lugarData['longitud']) ?? 0.0;
      }

      final response = await http.post(
        Uri.parse(ConfigService.lugaresUrl),
        headers: _headers,
        body: jsonEncode(lugarData),
      );

      LoggerService.debug('Respuesta del servidor: ${response.statusCode}');
      LoggerService.debug('Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        LoggerService.info('Lugar creado exitosamente con ID: ${data['id']}');
        return data;
      }

      // Manejar respuestas de error específicas
      if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        String errorMessage = 'Error de validación:';

        // Extraer mensajes de error detallados
        error.forEach((key, value) {
          if (value is List) {
            errorMessage += '\n• $key: ${value.join(', ')}';
          } else {
            errorMessage += '\n• $key: $value';
          }
        });

        LoggerService.error('Error de validación al crear lugar', error);
        throw Exception(errorMessage);
      } else if (response.statusCode == 401) {
        throw Exception('No autorizado. Inicia sesión nuevamente.');
      } else if (response.statusCode == 403) {
        throw Exception('No tienes permisos para crear lugares.');
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
            error['detail'] ?? 'Error al crear lugar: ${response.statusCode}');
      }
    } catch (e) {
      LoggerService.error('Error al crear lugar', e);
      if (e is FormatException) {
        throw Exception('Error al procesar la respuesta del servidor');
      } else if (e.toString().contains('SocketException')) {
        throw Exception(
            'No se puede conectar al servidor. Verifica tu conexión a internet.');
      }
      throw Exception('Error al crear lugar: $e');
    }
  }

  static Future<Map<String, dynamic>> editarLugar(
      int id, Map<String, dynamic> lugarData) async {
    if (!AuthService.estaAutenticado) {
      throw Exception('Usuario no autenticado');
    }

    if (!AuthService.esExperto) {
      throw Exception('No tienes permisos de experto');
    }

    try {
      LoggerService.info(
          'Enviando actualización para lugar $id: ${jsonEncode(lugarData)}');

      final response = await http.put(
        Uri.parse('${ConfigService.lugaresUrl}$id/'),
        headers: _headers,
        body: jsonEncode(lugarData),
      );

      LoggerService.debug('Respuesta del servidor: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data == null) {
          throw Exception('La respuesta del servidor está vacía');
        }
        return data;
      }

      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'Error al actualizar lugar');
    } catch (e) {
      LoggerService.error('Error al actualizar lugar', e);
      throw Exception('Error al actualizar lugar: $e');
    }
  }

  static Future<List<dynamic>> getLugaresExperto() async {
    // Verificar autenticación con mensajes detallados
    if (!AuthService.estaAutenticado) {
      LoggerService.error(
          'Intento de acceder a lugares de experto sin autenticación');
      throw Exception(
          'Usuario no autenticado. Por favor inicia sesión nuevamente.');
    }

    // Verificar rol con mensajes detallados
    if (!AuthService.esExperto) {
      LoggerService.error(
          'Usuario con rol ${AuthService.rol} intentando acceder a función de experto');
      throw Exception(
          'No tienes permisos de experto. Tu rol actual es: ${AuthService.rol ?? "no definido"}');
    }

    // Verificar que tengamos userId
    if (AuthService.userId == null || AuthService.userId!.isEmpty) {
      LoggerService.error(
          'ID de usuario no disponible para búsqueda de lugares');
      throw Exception(
          'ID de usuario no disponible. Por favor inicia sesión nuevamente.');
    }

    try {
      LoggerService.info(
          'Solicitando lugares creados por el experto: ${AuthService.username}');
      LoggerService.debug('URL base: ${ConfigService.lugaresUrl}');
      LoggerService.debug('Token: ${AuthService.token}');
      LoggerService.debug('ID de usuario: ${AuthService.userId}');

      // Intento con timeout
      List<dynamic> resultado = [];
      bool exito = false;
      String errorMsg = '';

      // Primero intentamos con el endpoint específico
      try {
        final response = await http
            .get(
          Uri.parse('${ConfigService.lugaresUrl}mis-lugares/'),
          headers: _headers,
        )
            .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            LoggerService.warning('Timeout al intentar obtener mis-lugares');
            throw Exception('Tiempo de espera agotado al cargar lugares');
          },
        );

        LoggerService.debug(
            'Respuesta del servidor mis-lugares: ${response.statusCode}');
        LoggerService.debug('Respuesta body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          LoggerService.info(
              'Lugares obtenidos desde mis-lugares: ${data.length}');
          resultado = data;
          exito = true;
        } else if (response.statusCode == 401) {
          LoggerService.warning('Token inválido al obtener mis-lugares');
          errorMsg = 'Sesión expirada. Por favor inicia sesión nuevamente.';
        } else if (response.statusCode == 404) {
          LoggerService.warning('Endpoint mis-lugares no encontrado (404)');
          // Continuamos con el siguiente método, no es un error crítico
        } else {
          LoggerService.warning(
              'Error en endpoint mis-lugares: ${response.statusCode}');
          errorMsg = 'Error al cargar lugares: ${response.statusCode}';
        }
      } catch (e) {
        LoggerService.warning(
            'Endpoint mis-lugares falló, intentando filtrar por creador: ${e.toString()}');
        // No es crítico, intentamos con el segundo método
      }

      // Si el endpoint específico no funcionó, usamos el endpoint general con filtro
      if (!exito) {
        try {
          final response = await http
              .get(
            Uri.parse(
                '${ConfigService.lugaresUrl}?creador=${AuthService.userId}'),
            headers: _headers,
          )
              .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              LoggerService.warning('Timeout al intentar filtrar por creador');
              throw Exception('Tiempo de espera agotado al cargar lugares');
            },
          );

          LoggerService.debug(
              'Respuesta del servidor (filtro por creador): ${response.statusCode}');
          LoggerService.debug('Respuesta body: ${response.body}');

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            LoggerService.info(
                'Lugares obtenidos por filtro de creador: ${data.length}');
            resultado = data;
            exito = true;
          } else if (response.statusCode == 401) {
            LoggerService.error('Token inválido al filtrar por creador');
            throw Exception(
                'Sesión expirada. Por favor inicia sesión nuevamente.');
          } else {
            LoggerService.error(
                'Error al filtrar por creador: ${response.statusCode}');
            throw Exception(errorMsg.isNotEmpty
                ? errorMsg
                : 'Error al cargar lugares: ${response.statusCode}');
          }
        } catch (e) {
          LoggerService.error('Error al filtrar por creador', e);
          if (e is Exception) throw e;
          throw Exception('Error al cargar lugares: $e');
        }
      }

      if (!exito) {
        throw Exception(errorMsg.isNotEmpty
            ? errorMsg
            : 'No se pudo obtener lugares para el experto');
      }

      return resultado;
    } catch (e) {
      LoggerService.error('Error al cargar lugares del experto', e);
      if (e is Exception) throw e;
      throw Exception('Error al cargar lugares: $e');
    }
  }
}
