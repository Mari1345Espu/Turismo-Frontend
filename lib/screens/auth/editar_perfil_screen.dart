import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/config_service.dart';
import '../../services/auth_service.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final usernameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  bool loading = false;
  String? mensaje;

  @override
  void initState() {
    super.initState();
    usernameCtrl.text = AuthService.username ?? '';
    emailCtrl.text = AuthService.email ?? '';
  }

  Future<void> actualizarPerfil() async {
    setState(() {
      loading = true;
      mensaje = null;
    });

    final res = await http.put(
      Uri.parse('${ConfigService.serverUrl}usuarios/perfil/'),
      headers: {
        'Authorization': 'Token ${AuthService.token}',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'username': usernameCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
      }),
    );

    setState(() => loading = false);

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      AuthService.iniciarSesion(
        t: AuthService.token!,
        e: data['email'],
        u: data['username'],
        r: data['rol'],
        id: data['id'].toString(),
      );
      setState(() => mensaje = 'Perfil actualizado correctamente.');
    } else {
      setState(() => mensaje = 'Error al actualizar perfil.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Editar perfil'), backgroundColor: Colors.blue),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: usernameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre de usuario'),
            ),
            TextField(
              controller: emailCtrl,
              decoration:
                  const InputDecoration(labelText: 'Correo electrónico'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: loading ? null : actualizarPerfil,
              icon: const Icon(Icons.save),
              label: const Text('Guardar cambios'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.blue,
              ),
            ),
            if (mensaje != null) ...[
              const SizedBox(height: 12),
              Text(mensaje!, style: const TextStyle(color: Colors.green)),
            ]
          ],
        ),
      ),
    );
  }
}
