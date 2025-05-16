import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminRolesScreen extends StatefulWidget {
  const AdminRolesScreen({super.key});

  @override
  State<AdminRolesScreen> createState() => _AdminRolesScreenState();
}

class _AdminRolesScreenState extends State<AdminRolesScreen> {
  List<Map<String, dynamic>> usuarios = [];
  List<Map<String, dynamic>> usuariosFiltrados = [];
  bool loading = true;
  String? error;
  String busqueda = '';
  String filtroRol = 'todos';
  final searchController = TextEditingController();

  final List<String> roles = ['normal', 'experto', 'admin'];

  @override
  void initState() {
    super.initState();
    cargarUsuarios();
  }

  void filtrarUsuarios() {
    setState(() {
      usuariosFiltrados = usuarios.where((u) {
        final cumpleBusqueda = u['username']
                .toString()
                .toLowerCase()
                .contains(busqueda.toLowerCase()) ||
            u['email']
                .toString()
                .toLowerCase()
                .contains(busqueda.toLowerCase());
        final cumpleFiltroRol = filtroRol == 'todos' || u['rol'] == filtroRol;
        return cumpleBusqueda && cumpleFiltroRol;
      }).toList();
    });
  }

  Future<void> cargarUsuarios() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final data = await ApiService.getUsuarios();
      if (!mounted) return;

      setState(() {
        usuarios = List<Map<String, dynamic>>.from(data);
        filtrarUsuarios();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> cambiarRol(int userId, String nuevoRol) async {
    try {
      await ApiService.cambiarRolUsuario(userId, nuevoRol);
      await cargarUsuarios(); // Recargar la lista después del cambio
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rol actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cambiar rol: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Roles'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Buscar usuario',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      busqueda = value;
                      filtrarUsuarios();
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: filtroRol,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por rol',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: 'todos', child: Text('Todos')),
                    ...roles.map((rol) => DropdownMenuItem(
                          value: rol,
                          child: Text(rol.toUpperCase()),
                        )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      filtroRol = value!;
                      filtrarUsuarios();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: cargarUsuarios,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: cargarUsuarios,
                        child: ListView.builder(
                          itemCount: usuariosFiltrados.length,
                          itemBuilder: (context, index) {
                            final usuario = usuariosFiltrados[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue[100],
                                  child: Text(
                                    usuario['username'][0].toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.blue[900],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(usuario['username']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(usuario['email']),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        usuario['rol'].toUpperCase(),
                                        style: TextStyle(
                                          color: Colors.blue[900],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (rol) => cambiarRol(
                                    int.parse(usuario['id'].toString()),
                                    rol,
                                  ),
                                  itemBuilder: (context) => roles
                                      .where((rol) => rol != usuario['rol'])
                                      .map((rol) => PopupMenuItem(
                                            value: rol,
                                            child: Text(
                                              'Cambiar a ${rol.toUpperCase()}',
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
