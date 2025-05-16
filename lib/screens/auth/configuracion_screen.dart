import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/config_service.dart';
import '../../services/auth_service.dart';
import '../../services/logger_service.dart';
import '../../widgets/custom_app_bar.dart';

class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  final serverUrlController = TextEditingController();
  String? mensaje;
  bool isSaving = false;
  bool success = false;
  String selectedEnvironment = 'custom';

  final Map<String, String> predefinedEnvironments = {
    'local': 'http://127.0.0.1:8000/api/',
    'android_emulator': 'http://10.0.2.2:8000/api/',
    'wifi_local': 'http://192.168.1.3:8000/api/',
    'custom': '',
  };

  @override
  void initState() {
    super.initState();
    serverUrlController.text = ConfigService.serverUrl;
    
    // Detectar si coincide con algún entorno predefinido
    predefinedEnvironments.forEach((key, value) {
      if (ConfigService.serverUrl == value) {
        selectedEnvironment = key;
      }
    });
    
    if (selectedEnvironment == 'custom') {
      predefinedEnvironments['custom'] = ConfigService.serverUrl;
    }
  }

  void seleccionarEntorno(String entorno) {
    setState(() {
      selectedEnvironment = entorno;
      if (entorno != 'custom') {
        serverUrlController.text = predefinedEnvironments[entorno] ?? '';
      }
    });
  }

  Future<void> guardarConfiguracion() async {
    setState(() {
      mensaje = null;
      isSaving = true;
      success = false;
    });

    try {
      final newUrl = serverUrlController.text.trim();
      if (newUrl.isEmpty) {
        throw Exception('La URL no puede estar vacía');
      }

      // Validar formato URL básico
      if (!newUrl.startsWith('http://') && !newUrl.startsWith('https://')) {
        throw Exception('La URL debe comenzar con http:// o https://');
      }

      await ConfigService.setServerUrl(newUrl);
      
      setState(() {
        mensaje = 'Configuración guardada correctamente';
        success = true;
      });
      
      LoggerService.info('URL del servidor actualizada a: $newUrl');
      
      // Mostrar diálogo para reiniciar la aplicación
      if (mounted) {
        _mostrarDialogoReiniciar();
      }
    } catch (e) {
      setState(() {
        mensaje = 'Error: ${e.toString()}';
        success = false;
      });
      LoggerService.error('Error al guardar configuración', e);
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  Future<void> _mostrarDialogoReiniciar() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración actualizada'),
        content: const Text(
          'Se recomienda reiniciar la aplicación para que los cambios surtan efecto completamente.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> resetearConfiguracion() async {
    setState(() {
      mensaje = null;
      isSaving = true;
      success = false;
    });

    try {
      await ConfigService.resetServerUrl();
      serverUrlController.text = ConfigService.serverUrl;
      
      setState(() {
        mensaje = 'Configuración restaurada al valor por defecto';
        success = true;
        // Actualizar el entorno seleccionado
        predefinedEnvironments.forEach((key, value) {
          if (ConfigService.serverUrl == value) {
            selectedEnvironment = key;
          }
        });
      });
      
      LoggerService.info('URL del servidor restaurada al valor por defecto: ${ConfigService.serverUrl}');
    } catch (e) {
      setState(() {
        mensaje = 'Error: ${e.toString()}';
        success = false;
      });
      LoggerService.error('Error al restaurar configuración', e);
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Configuración',
        showDrawer: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // URL del servidor
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'URL del Servidor',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Cambia la dirección del servidor backend',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 15),
                    
                    // Selector de entorno
                    const Text(
                      'Selecciona un entorno:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildEnvironmentChip('local', 'Desarrollo Local'),
                        _buildEnvironmentChip('android_emulator', 'Emulador Android'),
                        _buildEnvironmentChip('wifi_local', 'Red Local'),
                        _buildEnvironmentChip('custom', 'Personalizado'),
                      ],
                    ),
                    
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: serverUrlController,
                      decoration: InputDecoration(
                        labelText: 'URL del servidor',
                        hintText: 'http://127.0.0.1:8000/api/',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copiar',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: serverUrlController.text));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('URL copiada al portapapeles')),
                            );
                          },
                        ),
                      ),
                      onChanged: (value) {
                        if (value != predefinedEnvironments[selectedEnvironment]) {
                          setState(() {
                            selectedEnvironment = 'custom';
                            predefinedEnvironments['custom'] = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: isSaving ? null : guardarConfiguracion,
                            icon: const Icon(Icons.save),
                            label: const Text('Guardar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          onPressed: isSaving ? null : resetearConfiguracion,
                          icon: const Icon(Icons.restore),
                          label: const Text('Restaurar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Mensaje de resultado
            if (mensaje != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: success ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: success ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  mensaje!,
                  style: TextStyle(
                    color: success ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),

            // Información de conexión
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información de conexión',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Consejos para configurar correctamente la conexión:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Usa 127.0.0.1:8000 para desarrollo local en navegador web',
                      style: TextStyle(fontSize: 13),
                    ),
                    const Text(
                      '• Usa 10.0.2.2:8000 para emuladores Android',
                      style: TextStyle(fontSize: 13),
                    ),
                    Text(
                      '• Usa 192.168.1.3:8000 para dispositivos físicos en tu red',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const Text(
                      '• Asegúrate que el servidor backend esté en ejecución',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),

            // Estado de la sesión
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado de la sesión',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildInfoRow('Autenticado', AuthService.estaAutenticado ? 'Sí' : 'No'),
                    _buildInfoRow('Usuario', AuthService.username ?? 'No definido'),
                    _buildInfoRow('Email', AuthService.email ?? 'No definido'),
                    _buildInfoRow('Rol', AuthService.rol ?? 'No definido'),
                    _buildInfoRow('ID de Usuario', AuthService.userId ?? 'No definido'),
                    const SizedBox(height: 15),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Información actualizada')),
                        );
                        setState(() {});
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar información'),
                    ),
                  ],
                ),
              ),
            ),

            // URLs usadas por la aplicación
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'URLs de la aplicación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildUrlRow('URL Base', ConfigService.serverUrl),
                    _buildUrlRow('Auth URL', ConfigService.authUrl),
                    _buildUrlRow('Lugares URL', ConfigService.lugaresUrl),
                    _buildUrlRow('Favoritos URL', ConfigService.favoritosUrl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentChip(String environment, String label) {
    final isSelected = selectedEnvironment == environment;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => seleccionarEntorno(environment),
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.blue[100],
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue[800] : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlRow(String label, String url) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  url,
                  style: TextStyle(color: Colors.blue[700], fontSize: 13),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.content_copy, size: 18),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('URL copiada al portapapeles')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
} 