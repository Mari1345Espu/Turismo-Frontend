import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/logger_service.dart';
import '../../services/config_service.dart';
import '../../widgets/custom_app_bar.dart';

class CrearLugarScreen extends StatefulWidget {
  const CrearLugarScreen({super.key});

  @override
  State<CrearLugarScreen> createState() => _CrearLugarScreenState();
}

class _CrearLugarScreenState extends State<CrearLugarScreen> {
  final formKey = GlobalKey<FormState>();
  final nombreCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final dirCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lonCtrl = TextEditingController();
  final telCtrl = TextEditingController();
  final webCtrl = TextEditingController();
  String categoria = 'restaurante';
  bool loading = false;
  String? error;
  bool authChecked = false;

  @override
  void initState() {
    super.initState();
    // Verificamos que el usuario esté autenticado y sea experto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!AuthService.estaAutenticado) {
        LoggerService.warning('Intento de crear lugar sin autenticación');
        // Mostramos un aviso pero no redirigimos inmediatamente
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No estás autenticado. Los cambios no se guardarán.'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Iniciar sesión',
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
              textColor: Colors.white,
            ),
          ),
        );
        setState(() {
          error = 'Debes iniciar sesión para crear lugares.';
          authChecked = true;
        });
        return;
      }
      
      if (!AuthService.esExperto) {
        LoggerService.warning('Usuario con rol ${AuthService.rol} intentando crear lugar');
        // Mostramos un aviso pero no redirigimos inmediatamente
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Solo expertos pueden crear lugares. Tu rol es: ${AuthService.rol ?? "no definido"}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Entendido',
              onPressed: () {},
              textColor: Colors.white,
            ),
          ),
        );
        setState(() {
          error = 'Solo usuarios con rol "experto" pueden crear lugares. Tu rol actual es: ${AuthService.rol ?? "no definido"}';
          authChecked = true;
        });
        return;
      }
      
      setState(() {
        authChecked = true;
      });
      
      LoggerService.info('Experto ${AuthService.username} accediendo a pantalla de crear lugar');
    });
  }

  Future<void> enviarLugar() async {
    if (!formKey.currentState!.validate()) return;

    // Validación extra de autenticación
    if (!AuthService.estaAutenticado || !AuthService.esExperto) {
      setState(() {
        error = 'Solo expertos autenticados pueden crear lugares.';
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {      
      LoggerService.info('Preparando datos para crear lugar (Experto: ${AuthService.username})');
      LoggerService.debug('URL del servidor actual: ${ConfigService.serverUrl}');

      // Validar formato de latitud y longitud
      final latitud = double.tryParse(latCtrl.text.trim());
      final longitud = double.tryParse(lonCtrl.text.trim());
      
      if (latitud == null || longitud == null) {
        throw Exception('La latitud y longitud deben ser números válidos');
      }
      
      if (latitud < -90 || latitud > 90) {
        throw Exception('La latitud debe estar entre -90 y 90 grados');
      }
      
      if (longitud < -180 || longitud > 180) {
        throw Exception('La longitud debe estar entre -180 y 180 grados');
      }

      final lugarData = {
        'nombre': nombreCtrl.text.trim(),
        'descripcion': descCtrl.text.trim(),
        'direccion': dirCtrl.text.trim(),
        'categoria': categoria,
        'latitud': latitud,
        'longitud': longitud,
        'telefono': telCtrl.text.trim(),
        'sitio_web': webCtrl.text.trim().isEmpty ? null : webCtrl.text.trim(),
      };

      LoggerService.debug('Datos del lugar a crear: ${lugarData.toString()}');
      LoggerService.debug('Token del usuario: ${AuthService.token}');

      try {
        await ApiService.crearLugar(lugarData);
        
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lugar creado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Volver al home con resultado exitoso
      } catch (e) {
        LoggerService.error('Error API al crear lugar', e);
        if (!mounted) return;
        setState(() => error = e.toString());
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error del servidor: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              textColor: Colors.white,
            ),
          ),
        );
      }
    } catch (e) {
      LoggerService.error('Error de validación al crear lugar', e);
      if (!mounted) return;
      setState(() => error = e.toString());
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de validación: ${e.toString()}'),
          backgroundColor: Colors.orange,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!authChecked) {
      return Scaffold(
        appBar: const CustomAppBar(
          title: 'Crear nuevo lugar',
          showDrawer: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Crear nuevo lugar',
        showDrawer: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Error:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          error!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Información de conexión
              if (!AuthService.estaAutenticado || !AuthService.esExperto)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Información de conexión:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('URL del servidor: ${ConfigService.serverUrl}'),
                          Text('Autenticado: ${AuthService.estaAutenticado ? 'Sí' : 'No'}'),
                          Text('Usuario: ${AuthService.username ?? 'No definido'}'),
                          Text('Rol: ${AuthService.rol ?? 'No definido'}'),
                          Text('Token presente: ${AuthService.token != null ? 'Sí' : 'No'}'),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/configuracion');
                            },
                            icon: const Icon(Icons.settings),
                            label: const Text('Ir a Configuración'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              TextFormField(
                controller: nombreCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: categoria,
                items: const [
                  DropdownMenuItem(
                      value: 'restaurante', child: Text('Restaurante')),
                  DropdownMenuItem(
                      value: 'atraccion', child: Text('Atracción')),
                  DropdownMenuItem(
                      value: 'hospedaje', child: Text('Hospedaje')),
                ],
                onChanged: (String? value) {
                  setState(() => categoria = value ?? 'restaurante');
                },
                decoration: const InputDecoration(labelText: 'Categoría'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: dirCtrl,
                decoration: const InputDecoration(labelText: 'Dirección'),
                validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: latCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Latitud',
                        hintText: 'Ej: 4.8126',
                        helperText: 'Formato decimal (no usar comas)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Formato inválido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: lonCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Longitud',
                        hintText: 'Ej: -75.2356',
                        helperText: 'Formato decimal (no usar comas)',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null) return 'Formato inválido';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: telCtrl,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  hintText: 'Opcional',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: webCtrl,
                decoration: const InputDecoration(
                  labelText: 'Sitio Web',
                  hintText: 'Opcional',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: loading || !AuthService.estaAutenticado || !AuthService.esExperto
                    ? null
                    : enviarLugar,
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_location),
                label: const Text('Crear Lugar'),
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
