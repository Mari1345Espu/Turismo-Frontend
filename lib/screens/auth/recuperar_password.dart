import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/logger_service.dart';
import '../../routes/app_routes.dart';

class RecuperarPassword extends StatefulWidget {
  const RecuperarPassword({super.key});

  @override
  State<RecuperarPassword> createState() => _RecuperarPasswordState();
}

class _RecuperarPasswordState extends State<RecuperarPassword> {
  final formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  bool loading = false;
  String? mensaje;
  bool exito = false;

  Future<void> solicitarReset() async {
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
      LoggerService.info('Solicitando recuperación de contraseña para: ${emailCtrl.text}');
      
      // Usar ApiService para solicitar el reset de contraseña
      await ApiService.requestPasswordReset(emailCtrl.text.trim());
      
      if (!mounted) return;
      
      // Mostrar mensaje de éxito
      setState(() {
        mensaje = 'Se ha enviado un correo electrónico con instrucciones para recuperar tu contraseña. Revisa tu bandeja de entrada.';
        exito = true;
        
        // Limpiar el campo
        emailCtrl.clear();
      });
    } catch (e) {
      LoggerService.error('Error al solicitar recuperación de contraseña', e);
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
        title: const Text('Recuperar contraseña'),
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
                  'Ingresa tu correo electrónico y te enviaremos instrucciones para recuperar tu contraseña.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              
              // Campo de correo electrónico
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
              
              // Botón para enviar solicitud
              ElevatedButton.icon(
                onPressed: loading ? null : solicitarReset,
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.email),
                label: Text(loading ? 'Enviando...' : 'Enviar correo de recuperación'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              
              // Botones adicionales
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, 
                      AppRoutes.initial, 
                      (route) => false
                    ),
                    icon: const Icon(Icons.login),
                    label: const Text('Volver al inicio de sesión'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
