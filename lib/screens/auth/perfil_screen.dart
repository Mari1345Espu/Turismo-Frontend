import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/config_service.dart';
import '../../services/auth_service.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? perfil;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarPerfil();
  }

  Future<void> cargarPerfil() async {
    final res = await http.get(
      Uri.parse('${ConfigService.serverUrl}usuarios/perfil/'),
      headers: {'Authorization': 'Token ${AuthService.token}'},
    );

    if (res.statusCode == 200) {
      setState(() {
        perfil = jsonDecode(res.body);
        loading = false;
      });
    } else {
      setState(() {
        error = 'No se pudo cargar el perfil.';
        loading = false;
      });
    }
  }

  Future<void> eliminarCuenta() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Eliminar cuenta?'),
        content: const Text('Esto eliminará tu cuenta permanentemente.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );

    if (confirm == true) {
      final res = await http.delete(
        Uri.parse('${ConfigService.authUrl}users/me/'),
        headers: {'Authorization': 'Token ${AuthService.token}'},
      );

      if (res.statusCode == 204) {
        AuthService.cerrarSesion();
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo eliminar la cuenta')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Mi perfil'), backgroundColor: Colors.blue),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : perfil == null
              ? Center(child: Text(error ?? 'Error desconocido'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.account_circle,
                          size: 100, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(perfil!['username'],
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      Text(perfil!['email'],
                          style: const TextStyle(color: Colors.grey)),
                      Text('Rol: ${perfil!['rol']}',
                          style: const TextStyle(color: Colors.blue)),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/editar-perfil'),
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar perfil'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/cambiar-password'),
                        icon: const Icon(Icons.password),
                        label: const Text('Cambiar contraseña'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: eliminarCuenta,
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('Eliminar cuenta'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          AuthService.cerrarSesion();
                          Navigator.pushNamedAndRemoveUntil(
                              context, '/', (_) => false);
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Cerrar sesión'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
