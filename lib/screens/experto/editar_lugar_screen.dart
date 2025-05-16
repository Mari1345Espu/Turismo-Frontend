import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/logger_service.dart';
import '../../widgets/custom_app_bar.dart';

class EditarLugarScreen extends StatefulWidget {
  final int lugarId;
  const EditarLugarScreen({super.key, required this.lugarId});

  @override
  State<EditarLugarScreen> createState() => _EditarLugarScreenState();
}

class _EditarLugarScreenState extends State<EditarLugarScreen> {
  final formKey = GlobalKey<FormState>();
  final nombreCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final dirCtrl = TextEditingController();
  final telCtrl = TextEditingController();
  final webCtrl = TextEditingController();
  final latCtrl = TextEditingController();
  final lonCtrl = TextEditingController();
  String categoria = 'restaurante';
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    
    // Verificamos permisos antes de cargar datos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!AuthService.estaAutenticado) {
        LoggerService.warning('Intento de editar lugar sin autenticación');
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes iniciar sesión para editar lugares'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (!AuthService.esExperto) {
        LoggerService.warning('Usuario no experto (${AuthService.rol}) intentando editar lugar');
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solo expertos pueden editar lugares'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      cargarDatos();
    });
  }

  Future<void> cargarDatos() async {
    setState(() {
      loading = true;
      error = null;
    });
    
    try {
      LoggerService.info('Cargando datos del lugar ID: ${widget.lugarId}');
      
      final lugar = await ApiService.getLugarById(widget.lugarId);
      
      if (!mounted) return;
      
      setState(() {
        nombreCtrl.text = lugar['nombre'] ?? '';
        descCtrl.text = lugar['descripcion'] ?? '';
        dirCtrl.text = lugar['direccion'] ?? '';
        telCtrl.text = lugar['telefono'] ?? '';
        webCtrl.text = lugar['sitio_web'] ?? '';
        latCtrl.text = lugar['latitud'].toString();
        lonCtrl.text = lugar['longitud'].toString();
        categoria = lugar['categoria'] ?? 'restaurante';
        loading = false;
      });
      
      LoggerService.info('Datos del lugar cargados correctamente');
    } catch (e) {
      LoggerService.error('Error al cargar datos del lugar', e);
      
      if (!mounted) return;
      
      setState(() {
        error = 'No se pudo cargar la información del lugar: ${e.toString().replaceAll('Exception: ', '')}';
        loading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> guardarCambios() async {
    if (!formKey.currentState!.validate()) return;
    
    setState(() {
      loading = true;
      error = null;
    });

    try {
      // Validar el formato de latitud y longitud
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
        'telefono': telCtrl.text.trim(),
        'sitio_web': webCtrl.text.trim().isEmpty ? null : webCtrl.text.trim(),
        'latitud': latitud,
        'longitud': longitud,
        'categoria': categoria,
      };
      
      LoggerService.info('Actualizando lugar ID: ${widget.lugarId}');
      LoggerService.debug('Datos a actualizar: $lugarData');
      
      await ApiService.editarLugar(widget.lugarId, lugarData);
      
      if (!mounted) return;
      
      LoggerService.info('Lugar actualizado correctamente');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lugar actualizado con éxito'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      LoggerService.error('Error al actualizar lugar', e);
      
      if (!mounted) return;
      
      setState(() {
        error = 'Error al actualizar lugar: ${e.toString().replaceAll('Exception: ', '')}';
        loading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error!),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Editar lugar',
        showDrawer: false,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: formKey,
                child: ListView(
                  children: [
                    if (error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[300]!),
                        ),
                        child: Text(
                          error!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    TextFormField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Descripción'),
                      maxLines: 3,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: categoria,
                      decoration: const InputDecoration(labelText: 'Categoría'),
                      items: const [
                        DropdownMenuItem(
                            value: 'restaurante', child: Text('Restaurante')),
                        DropdownMenuItem(
                            value: 'atraccion', child: Text('Atracción')),
                        DropdownMenuItem(
                            value: 'hospedaje', child: Text('Hospedaje')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => categoria = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: dirCtrl,
                      decoration: const InputDecoration(labelText: 'Dirección'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: latCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Latitud'),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: lonCtrl,
                            decoration:
                                const InputDecoration(labelText: 'Longitud'),
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Requerido' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: telCtrl,
                      decoration: const InputDecoration(labelText: 'Teléfono'),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: webCtrl,
                      decoration: const InputDecoration(labelText: 'Sitio web'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: loading ? null : guardarCambios,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar cambios'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
