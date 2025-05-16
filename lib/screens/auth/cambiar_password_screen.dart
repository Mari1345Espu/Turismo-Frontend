import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/logger_service.dart';
import '../../widgets/custom_app_bar.dart';

class CambiarPasswordScreen extends StatefulWidget {
  const CambiarPasswordScreen({super.key});

  @override
  State<CambiarPasswordScreen> createState() => _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState extends State<CambiarPasswordScreen> {
  final formKey = GlobalKey<FormState>();
  final actualCtrl = TextEditingController();
  final nuevaCtrl = TextEditingController();
  final confirmarCtrl = TextEditingController();
  bool loading = false;
  bool mostrarActual = false;
  bool mostrarNueva = false;
  bool mostrarConfirmar = false;
  String? mensaje;
  bool exito = false;

  @override
  void initState() {
    super.initState();

    // Verificar autenticación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!AuthService.estaAutenticado) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes iniciar sesión para cambiar tu contraseña'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    });
  }

  Future<void> cambiarPassword() async {
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
      LoggerService.info(
          'Iniciando cambio de contraseña para: ${AuthService.username}');

      // Usar ApiService para cambiar la contraseña
      await ApiService.changePassword(
          actualCtrl.text.trim(), nuevaCtrl.text.trim());

      if (!mounted) return;

      // Mostrar mensaje de éxito
      setState(() {
        mensaje = 'Contraseña actualizada correctamente';
        exito = true;

        // Limpiar los campos
        actualCtrl.clear();
        nuevaCtrl.clear();
        confirmarCtrl.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contraseña actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      LoggerService.error('Error al cambiar contraseña', e);
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
      appBar: const CustomAppBar(
        title: 'Cambiar contraseña',
        showDrawer: false,
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
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Ingresa tu contraseña actual y la nueva contraseña para actualizarla',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              // Contraseña actual
              TextFormField(
                controller: actualCtrl,
                obscureText: !mostrarActual,
                decoration: InputDecoration(
                  labelText: 'Contraseña actual',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(mostrarActual
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => mostrarActual = !mostrarActual),
                    tooltip: mostrarActual
                        ? 'Ocultar contraseña'
                        : 'Mostrar contraseña',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu contraseña actual';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nueva contraseña
              TextFormField(
                controller: nuevaCtrl,
                obscureText: !mostrarNueva,
                decoration: InputDecoration(
                  labelText: 'Nueva contraseña',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                        mostrarNueva ? Icons.visibility : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => mostrarNueva = !mostrarNueva),
                    tooltip: mostrarNueva
                        ? 'Ocultar contraseña'
                        : 'Mostrar contraseña',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una nueva contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  if (value == actualCtrl.text) {
                    return 'La nueva contraseña debe ser diferente a la actual';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirmar nueva contraseña
              TextFormField(
                controller: confirmarCtrl,
                obscureText: !mostrarConfirmar,
                decoration: InputDecoration(
                  labelText: 'Confirmar nueva contraseña',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_reset),
                  suffixIcon: IconButton(
                    icon: Icon(mostrarConfirmar
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => mostrarConfirmar = !mostrarConfirmar),
                    tooltip: mostrarConfirmar
                        ? 'Ocultar contraseña'
                        : 'Mostrar contraseña',
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
                      color:
                          exito ? Colors.green.shade300 : Colors.red.shade300,
                    ),
                  ),
                  child: Text(
                    mensaje!,
                    style: TextStyle(
                      color:
                          exito ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Botón actualizar
              ElevatedButton.icon(
                onPressed: loading ? null : cambiarPassword,
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
                label:
                    Text(loading ? 'Actualizando...' : 'Actualizar contraseña'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
