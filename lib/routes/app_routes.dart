import 'package:flutter/material.dart';

// Auth
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/recuperar_password.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/perfil_screen.dart';
import '../screens/auth/editar_perfil_screen.dart';
import '../screens/auth/cambiar_password_screen.dart';
import '../screens/auth/configuracion_screen.dart';

// Usuario
import '../screens/home/user_home.dart';
import '../screens/home/lugar_detalle.dart';
import '../screens/home/favoritos_screen.dart';
import '../screens/home/rutas_sugeridas.dart';
import '../screens/home/agregar_comentario.dart';
import '../screens/home/mapa_lugares.dart';
import '../screens/home/editar_comentario.dart';

// Experto
import '../screens/home/experto_home.dart';
import '../screens/experto/crear_lugar_screen.dart';
import '../screens/experto/editar_lugar_screen.dart';
import '../screens/experto/crear_ruta_screen.dart';
import '../screens/experto/editar_ruta_screen.dart';
import '../screens/home/mis_rutas_screen.dart';

// Admin
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/admin_comentarios.dart';
import '../screens/admin/admin_lugares.dart';
import '../screens/admin/admin_roles.dart';
import '../screens/admin/admin_rutas.dart';

class AppRoutes {
  // Auth Routes
  static const String initial = '/';
  static const String registro = '/registro';
  static const String recuperar = '/recuperar';
  static const String resetPassword = '/reset-password';
  static const String perfil = '/perfil';
  static const String editarPerfil = '/editar-perfil';
  static const String cambiarPassword = '/cambiar-password';
  static const String configuracion = '/configuracion';

  // User Routes
  static const String usuario = '/usuario';
  static const String favoritos = '/favoritos';
  static const String rutas = '/rutas';
  static const String mapa = '/mapa';
  static const String lugarDetalle = '/detalle-lugar';
  static const String agregarComentario = '/agregar-comentario';
  static const String editarComentario = '/editar-comentario';

  // Expert Routes
  static const String experto = '/experto';
  static const String crearLugar = '/crear-lugar';
  static const String editarLugar = '/editar-lugar';
  static const String crearRuta = '/crear-ruta';
  static const String editarRuta = '/editar-ruta';
  static const String misRutas = '/mis-rutas';

  // Admin Routes
  static const String admin = '/admin';
  static const String adminComentarios = '/admin-comentarios';
  static const String adminLugares = '/admin-lugares';
  static const String adminRoles = '/admin-roles';
  static const String adminRutas = '/admin-rutas';

  static Map<String, Widget Function(BuildContext)> get routes => {
        initial: (context) => const LoginScreen(),
        registro: (context) => const RegisterScreen(),
        recuperar: (context) => const RecuperarPassword(),
        perfil: (context) => const PerfilScreen(),
        editarPerfil: (context) => const EditarPerfilScreen(),
        cambiarPassword: (context) => const CambiarPasswordScreen(),
        configuracion: (context) => const ConfiguracionScreen(),
        usuario: (context) => const UsuarioHome(),
        favoritos: (context) => const FavoritosScreen(),
        rutas: (context) => const RutasSugeridasScreen(),
        mapa: (context) => const MapaLugares(),
        experto: (context) => const ExpertoHome(),
        crearLugar: (context) => const CrearLugarScreen(),
        crearRuta: (context) => const CrearRutaScreen(),
        misRutas: (context) => const MisRutasScreen(),
        admin: (context) => const AdminDashboard(),
        adminComentarios: (context) => const AdminComentariosScreen(),
        adminLugares: (context) => const AdminLugaresScreen(),
        adminRoles: (context) => const AdminRolesScreen(),
        adminRutas: (context) => const AdminRutasScreen(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name?.startsWith(resetPassword) ?? false) {
      final uri = Uri.parse(settings.name ?? '');
      if (uri.pathSegments.length == 3) {
        final uid = uri.pathSegments[1];
        final token = uri.pathSegments[2];
        return MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(uid: uid, token: token),
        );
      }
    }

    switch (settings.name) {
      case lugarDetalle:
        final lugarId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => LugarDetalle(lugarId: lugarId),
        );

      case editarLugar:
        final lugarId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => EditarLugarScreen(lugarId: lugarId),
        );

      case editarRuta:
        final rutaId = settings.arguments as int;
        return MaterialPageRoute(
          builder: (_) => EditarRutaScreen(rutaId: rutaId),
        );

      case agregarComentario:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => AgregarComentario(
            lugarId: args['lugarId'] as int,
            token: args['token'] as String,
            lugarNombre: args['lugarNombre'] as String,
          ),
        );

      case 'mis-favoritos':
        return MaterialPageRoute(
          builder: (_) => const FavoritosScreen(),
        );

      case editarComentario:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => EditarComentario(
            comentarioId: args['comentarioId'] as int,
            lugarId: args['lugarId'] as int,
            textoInicial: args['textoInicial'] as String,
            calificacionInicial: args['calificacionInicial'] as int,
            lugarNombre: args['lugarNombre'] as String,
          ),
        );
    }

    return null;
  }

  // Navigation Methods
  static void navigateToHome(BuildContext context) {
    const route = AppRoutes.usuario;
    Navigator.pushNamedAndRemoveUntil(context, route, (route) => false);
  }

  static void navigateToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, initial, (route) => false);
  }

  static void navigateToMap(BuildContext context) {
    Navigator.pushNamed(context, mapa);
  }

  static void navigateToLugarDetalle(BuildContext context, int lugarId) {
    Navigator.pushNamed(
      context,
      lugarDetalle,
      arguments: lugarId,
    );
  }

  static void navigateToEditarLugar(BuildContext context, int lugarId) {
    Navigator.pushNamed(
      context,
      editarLugar,
      arguments: lugarId,
    );
  }

  static void navigateToAgregarComentario(
    BuildContext context, {
    required int lugarId,
    required String token,
    required String lugarNombre,
  }) {
    Navigator.pushNamed(
      context,
      agregarComentario,
      arguments: {
        'lugarId': lugarId,
        'token': token,
        'lugarNombre': lugarNombre,
      },
    );
  }

  static void navigateToUserProfile(BuildContext context) {
    Navigator.pushNamed(context, perfil);
  }

  static void navigateToEditProfile(BuildContext context) {
    Navigator.pushNamed(context, editarPerfil);
  }

  static void navigateToChangePassword(BuildContext context) {
    Navigator.pushNamed(context, cambiarPassword);
  }

  static void navigateToFavorites(BuildContext context) {
    Navigator.pushNamed(context, favoritos);
  }

  static void navigateToRoutes(BuildContext context) {
    Navigator.pushNamed(context, rutas);
  }

  static void navigateToAdminPanel(BuildContext context) {
    Navigator.pushReplacementNamed(context, admin);
  }

  static void navigateToExpertPanel(BuildContext context) {
    Navigator.pushReplacementNamed(context, experto);
  }

  static void navigateToEditarComentario(
    BuildContext context, {
    required int comentarioId,
    required int lugarId,
    required String textoInicial,
    required int calificacionInicial,
    required String lugarNombre,
  }) {
    Navigator.pushNamed(
      context,
      editarComentario,
      arguments: {
        'comentarioId': comentarioId,
        'lugarId': lugarId,
        'textoInicial': textoInicial,
        'calificacionInicial': calificacionInicial,
        'lugarNombre': lugarNombre,
      },
    );
  }

  static void navigateToConfiguracion(BuildContext context) {
    Navigator.pushNamed(context, configuracion);
  }

  static void navigateToCrearRuta(BuildContext context) {
    Navigator.pushNamed(context, crearRuta);
  }

  static void navigateToMisRutas(BuildContext context) {
    Navigator.pushNamed(context, misRutas);
  }

  static void navigateToAdminRutas(BuildContext context) {
    Navigator.pushNamed(context, adminRutas);
  }

  static void navigateToEditarRuta(BuildContext context, int rutaId) {
    Navigator.pushNamed(
      context,
      editarRuta,
      arguments: rutaId,
    );
  }
} 