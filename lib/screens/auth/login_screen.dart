import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/logger_service.dart';
import '../../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool loading = false;
  bool ocultarPassword = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Verifica si ya hay una sesión activa
    _verificarSesionActiva();
  }
  
  Future<void> _verificarSesionActiva() async {
    // Intenta recargar la sesión por si acaso
    await AuthService.cargarSesion();
    
    // Verifica si el usuario ya está autenticado
    if (mounted && AuthService.estaAutenticado) {
      LoggerService.info('Usuario ya autenticado: ${AuthService.username} (Rol: ${AuthService.rol})');
      
      // Redireccionar según el rol
      final route = AuthService.esAdmin
          ? AppRoutes.admin
          : AuthService.esExperto
              ? AppRoutes.experto
              : AppRoutes.usuario;
      
      Navigator.pushReplacementNamed(context, route);
    }
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu correo electrónico';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Por favor ingresa un correo electrónico válido';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  Future<void> loginUser() async {
    // Validar el formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      LoggerService.info('Iniciando proceso de login con email: ${emailController.text.trim()}');
      
      // Primero cerrar cualquier sesión existente por seguridad
      await AuthService.cerrarSesion();
      
      // Intentar login
      await ApiService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (!mounted) return;
      
      LoggerService.info('Login exitoso, redirigiendo según rol: ${AuthService.rol}');
      
      // Redireccionar según el rol
      final route = AuthService.esAdmin
          ? AppRoutes.admin
          : AuthService.esExperto
              ? AppRoutes.experto
              : AppRoutes.usuario;

      Navigator.pushReplacementNamed(context, route);
    } catch (e) {
      LoggerService.error('Error en pantalla de login', e);
      
      if (!mounted) return;
      
      // Mostrar mensaje de error específico
      setState(() {
        if (e.toString().contains('Credenciales inválidas')) {
          errorMessage = 'Correo o contraseña incorrectos';
        } else if (e.toString().contains('conexión a internet')) {
          errorMessage = 'No se pudo conectar al servidor. Verifica tu conexión a internet.';
        } else if (e.toString().contains('tiempo de espera agotado')) {
          errorMessage = 'Tiempo de espera agotado. Intenta nuevamente.';
        } else {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        }
      });
      
      // Mostrar snackbar si el error es grave
      if (e.toString().contains('servidor') || 
          e.toString().contains('conexión') ||
          e.toString().contains('timeout')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${errorMessage!}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  'Iniciar Sesión',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: validateEmail,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: passwordController,
                  obscureText: ocultarPassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        ocultarPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => ocultarPassword = !ocultarPassword),
                    ),
                  ),
                  validator: validatePassword,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.recuperar),
                    child: const Text('¿Olvidaste tu contraseña?'),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: loading ? null : loginUser,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Ingresar'),
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.registro),
                  child: const Text('¿No tienes cuenta? Regístrate'),
                ),
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red[800]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
