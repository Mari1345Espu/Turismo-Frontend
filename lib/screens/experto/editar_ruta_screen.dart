import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/logger_service.dart';
import '../../widgets/custom_app_bar.dart';

class EditarRutaScreen extends StatefulWidget {
  final int rutaId;
  
  const EditarRutaScreen({super.key, required this.rutaId});

  @override
  State<EditarRutaScreen> createState() => _EditarRutaScreenState();
}

class _EditarRutaScreenState extends State<EditarRutaScreen> {
  final formKey = GlobalKey<FormState>();
  final nombreCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();
  List<Map<String, dynamic>> lugaresDisponibles = [];
  List<Map<String, dynamic>> lugaresSeleccionados = [];
  bool cargandoRuta = true;
  bool cargandoLugares = true;
  bool enviandoFormulario = false;
  String? error;
  Map<String, dynamic>? rutaOriginal;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarAutenticacion();
      _cargarRuta();
    });
  }
  
  void _verificarAutenticacion() {
    if (!AuthService.estaAutenticado) {
      LoggerService.warning('Intento de editar ruta sin autenticación');
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
        error = 'Debes iniciar sesión para editar rutas.';
      });
      return;
    }
    
    if (!AuthService.esExperto) {
      LoggerService.warning('Usuario con rol ${AuthService.rol} intentando editar ruta');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Solo expertos pueden editar rutas. Tu rol es: ${AuthService.rol ?? "no definido"}'),
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
        error = 'Solo usuarios con rol "experto" pueden editar rutas. Tu rol actual es: ${AuthService.rol ?? "no definido"}';
      });
    }
  }
  
  Future<void> _cargarRuta() async {
    try {
      setState(() {
        cargandoRuta = true;
        error = null;
      });
      
      LoggerService.info('Cargando datos de la ruta ${widget.rutaId}');
      
      final ruta = await ApiService.getRutaById(widget.rutaId);
      
      setState(() {
        rutaOriginal = ruta;
        nombreCtrl.text = ruta['nombre'] ?? '';
        descripcionCtrl.text = ruta['descripcion'] ?? '';
        cargandoRuta = false;
      });
      
      // Extraer los lugares que ya están en la ruta
      if (ruta['lugares'] != null && ruta['lugares'] is List) {
        final lugaresRuta = List<Map<String, dynamic>>.from(
          (ruta['lugares'] as List).map((lugar) => lugar as Map<String, dynamic>)
        );
        setState(() {
          lugaresSeleccionados = lugaresRuta;
        });
      }
      
      LoggerService.info('Datos de la ruta cargados exitosamente');
      
      // Ahora cargamos los lugares disponibles
      _cargarLugaresDisponibles();
    } catch (e) {
      LoggerService.error('Error al cargar datos de la ruta', e);
      setState(() {
        error = 'Error al cargar datos de la ruta: ${e.toString()}';
        cargandoRuta = false;
      });
    }
  }
  
  Future<void> _cargarLugaresDisponibles() async {
    try {
      setState(() {
        cargandoLugares = true;
        error = null;
      });
      
      LoggerService.info('Cargando lugares disponibles para editar ruta');
      
      final lugares = await ApiService.getLugares();
      
      // Filtrar los lugares que ya están seleccionados
      final lugaresIds = lugaresSeleccionados.map((l) => l['id']).toSet();
      final lugaresDisp = (lugares as List).where((l) => !lugaresIds.contains(l['id'])).toList();
      
      setState(() {
        lugaresDisponibles = List<Map<String, dynamic>>.from(lugaresDisp);
        cargandoLugares = false;
      });
      
      LoggerService.info('${lugaresDisponibles.length} lugares disponibles para agregar a la ruta');
    } catch (e) {
      LoggerService.error('Error al cargar lugares disponibles', e);
      setState(() {
        error = 'Error al cargar lugares: ${e.toString()}';
        cargandoLugares = false;
      });
    }
  }
  
  void _agregarLugar(Map<String, dynamic> lugar) {
    setState(() {
      lugaresSeleccionados.add(lugar);
      lugaresDisponibles.removeWhere((l) => l['id'] == lugar['id']);
    });
  }
  
  void _quitarLugar(Map<String, dynamic> lugar) {
    setState(() {
      lugaresDisponibles.add(lugar);
      lugaresSeleccionados.removeWhere((l) => l['id'] == lugar['id']);
    });
  }
  
  void _moverLugarArriba(int index) {
    if (index > 0) {
      setState(() {
        final lugar = lugaresSeleccionados.removeAt(index);
        lugaresSeleccionados.insert(index - 1, lugar);
      });
    }
  }
  
  void _moverLugarAbajo(int index) {
    if (index < lugaresSeleccionados.length - 1) {
      setState(() {
        final lugar = lugaresSeleccionados.removeAt(index);
        lugaresSeleccionados.insert(index + 1, lugar);
      });
    }
  }
  
  Future<void> _guardarCambios() async {
    if (!formKey.currentState!.validate()) return;
    
    if (lugaresSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar al menos un lugar para la ruta'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      enviandoFormulario = true;
      error = null;
    });
    
    try {
      final rutaData = {
        'nombre': nombreCtrl.text.trim(),
        'descripcion': descripcionCtrl.text.trim(),
        'lugares': lugaresSeleccionados.map((lugar) => lugar['id']).toList(),
      };
      
      LoggerService.info('Enviando datos actualizados de la ruta: $rutaData');
      
      // Enviar datos al servidor mediante el ApiService
      await ApiService.editarRuta(widget.rutaId, rutaData);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ruta actualizada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      LoggerService.error('Error al actualizar ruta', e);
      setState(() {
        error = 'Error al actualizar ruta: ${e.toString()}';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        enviandoFormulario = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Editar Ruta de Viaje',
        showDrawer: false,
      ),
      body: cargandoRuta
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mensaje de error
                    if (error != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
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
                    
                    // Información de la ruta
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información de la Ruta',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: nombreCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nombre de la ruta',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa un nombre para la ruta';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: descripcionCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Descripción',
                                border: OutlineInputBorder(),
                                hintText: 'Describe brevemente esta ruta turística',
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor ingresa una descripción';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Sección de lugares seleccionados
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Lugares en esta Ruta',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${lugaresSeleccionados.length} seleccionados',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Ordena los lugares según el itinerario sugerido',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            if (lugaresSeleccionados.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'No hay lugares seleccionados. Añade lugares desde la lista inferior.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            else
                              cargandoLugares
                                ? const Center(child: CircularProgressIndicator())
                                : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: lugaresSeleccionados.length,
                                  itemBuilder: (context, index) {
                                    final lugar = lugaresSeleccionados[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      color: Colors.blue[50],
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.blue,
                                          child: Text('${index + 1}'),
                                        ),
                                        title: Text(lugar['nombre'] ?? 'Sin nombre'),
                                        subtitle: Text(lugar['categoria'] ?? 'Sin categoría'),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.arrow_upward),
                                              onPressed: index > 0 ? () => _moverLugarArriba(index) : null,
                                              tooltip: 'Mover arriba',
                                              color: Colors.blue,
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.arrow_downward),
                                              onPressed: index < lugaresSeleccionados.length - 1 ? () => _moverLugarAbajo(index) : null,
                                              tooltip: 'Mover abajo',
                                              color: Colors.blue,
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle),
                                              onPressed: () => _quitarLugar(lugar),
                                              tooltip: 'Quitar de la ruta',
                                              color: Colors.red,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Lugares disponibles
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Lugares Disponibles',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${lugaresDisponibles.length} disponibles',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Selecciona lugares para añadir a la ruta',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            if (cargandoLugares)
                              const Center(child: CircularProgressIndicator())
                            else if (lugaresDisponibles.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'No hay más lugares disponibles para añadir.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: lugaresDisponibles.length,
                                itemBuilder: (context, index) {
                                  final lugar = lugaresDisponibles[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(lugar['nombre'] ?? 'Sin nombre'),
                                      subtitle: Text(
                                        '${lugar['categoria'] ?? 'Sin categoría'} • ${lugar['direccion'] ?? 'Sin dirección'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.add_circle),
                                        onPressed: () => _agregarLugar(lugar),
                                        tooltip: 'Añadir a la ruta',
                                        color: Colors.green,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botón guardar
                    ElevatedButton.icon(
                      onPressed: enviandoFormulario ? null : _guardarCambios,
                      icon: enviandoFormulario
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(enviandoFormulario ? 'Guardando...' : 'Guardar Cambios'),
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