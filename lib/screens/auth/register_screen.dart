import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/logger_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final formKey = GlobalKey<FormState>();
  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  bool loading = false;
  bool ocultarPassword = true;
  String? mensaje;

  Future<void> registrarUsuario() async {
    // Cerrar el teclado
    FocusScope.of(context).unfocus();
    
    // Validar el formulario
    if (!formKey.currentState!.validate()) {
      return;
    }
    
    // Validar que las contraseñas coincidan
    if (passwordCtrl.text != confirmCtrl.text) {
      setState(() => mensaje = 'Las contraseñas no coinciden');
      return;
    }

    setState(() {
      loading = true;
      mensaje = null;
    });

    try {
      LoggerService.info('Iniciando registro para usuario: ${usernameCtrl.text}');
      
      // Usar ApiService para el registro
      await ApiService.register(
        usernameCtrl.text.trim(),
        emailCtrl.text.trim(),
        passwordCtrl.text.trim()
      );
      
      if (!mounted) return;
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cuenta creada exitosamente. Por favor inicia sesión.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Volver a la pantalla de login
      Navigator.pop(context);
    } catch (e) {
      LoggerService.error('Error en registro de usuario', e);
      if (!mounted) return;
      
      // Mostrar mensaje de error
      setState(() => mensaje = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mensaje informativo
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Ingresa tus datos para crear una cuenta',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              
              // Nombre de usuario
              TextFormField(
                controller: usernameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre de usuario',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un nombre de usuario';
                  }
                  if (value.length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Correo electrónico
              TextFormField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu correo electrónico';
                  }
                  // Validación básica de formato de email
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Ingresa un correo electrónico válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Contraseña
              TextFormField(
                controller: passwordCtrl,
                obscureText: ocultarPassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(ocultarPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => ocultarPassword = !ocultarPassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Confirmar contraseña
              TextFormField(
                controller: confirmCtrl,
                obscureText: ocultarPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(ocultarPassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => ocultarPassword = !ocultarPassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor confirma tu contraseña';
                  }
                  if (value != passwordCtrl.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              
              // Mensaje de error o éxito
              if (mensaje != null)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: mensaje!.contains('exitosamente') ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: mensaje!.contains('exitosamente') ? Colors.green.shade300 : Colors.red.shade300,
                    ),
                  ),
                  child: Text(
                    mensaje!,
                    style: TextStyle(
                      color: mensaje!.contains('exitosamente') ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Botón de registro
              ElevatedButton.icon(
                onPressed: loading ? null : registrarUsuario,
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.app_registration),
                label: Text(loading ? 'Registrando...' : 'Crear cuenta'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              
              // Botón para volver al login
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('¿Ya tienes cuenta? Inicia sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
