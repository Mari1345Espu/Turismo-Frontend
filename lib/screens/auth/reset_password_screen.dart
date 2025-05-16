import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/logger_service.dart';
import '../../routes/app_routes.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String uid;
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.uid,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final nuevaCtrl = TextEditingController();
  final confirmarCtrl = TextEditingController();
  bool loading = false;
  bool mostrarPassword = false;
  String? mensaje;
  bool exito = false;

  Future<void> enviarNuevaPassword() async {
    // Cerrar el teclado
    FocusScope.of(context).unfocus();
    
    // Validar el formulario
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      loading = true;
      mensaje = null;
      exito = false;
    });

    try {
      LoggerService.info('Intentando restablecer contraseña con token');
      
      // Usar ApiService para restablecer la contraseña
      await ApiService.resetPassword(
        widget.uid,
        widget.token,
        nuevaCtrl.text.trim()
      );
      
      if (!mounted) return;
      
      // Mostrar mensaje de éxito
      setState(() {
        mensaje = 'Contraseña restablecida correctamente. Redirigiendo al inicio de sesión...';
        exito = true;
      });
      
      // Esperar unos segundos y redirigir al login
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.initial, 
        (route) => false
      );
    } catch (e) {
      LoggerService.error('Error al restablecer contraseña', e);
      if (!mounted) return;
      
      // Mostrar mensaje de error
      setState(() {
        mensaje = e.toString().replaceAll('Exception: ', '');
        exito = false;
      });
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
        title: const Text('Nueva contraseña'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instrucciones
              const Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(
                  'Ingresa y confirma tu nueva contraseña para restablecer el acceso a tu cuenta',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              
              // Nueva contraseña
              TextFormField(
                controller: nuevaCtrl,
                obscureText: !mostrarPassword,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(mostrarPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => mostrarPassword = !mostrarPassword),
                    tooltip: mostrarPassword ? 'Ocultar contraseña' : 'Mostrar contraseña',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una nueva contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Confirmar nueva contraseña
              TextFormField(
                controller: confirmarCtrl,
                obscureText: !mostrarPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar nueva contraseña',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(mostrarPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => mostrarPassword = !mostrarPassword),
                    tooltip: mostrarPassword ? 'Ocultar contraseña' : 'Mostrar contraseña',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor confirma tu nueva contraseña';
                  }
                  if (value != nuevaCtrl.text) {
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
                    color: exito ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: exito ? Colors.green.shade300 : Colors.red.shade300,
                    ),
                  ),
                  child: Text(
                    mensaje!,
                    style: TextStyle(
                      color: exito ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Botón para restablecer contraseña
              ElevatedButton.icon(
                onPressed: loading ? null : enviarNuevaPassword,
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.lock_reset),
                label: Text(loading ? 'Procesando...' : 'Restablecer contraseña'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              
              // Volver al login
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.initial,
                    (route) => false
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Volver al inicio de sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
