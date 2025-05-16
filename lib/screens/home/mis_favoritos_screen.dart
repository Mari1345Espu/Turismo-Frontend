import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/menu_drawer.dart';
import '../../routes/app_routes.dart';

class MisFavoritosScreen extends StatefulWidget {
  const MisFavoritosScreen({super.key});

  @override
  State<MisFavoritosScreen> createState() => _MisFavoritosScreenState();
}

class _MisFavoritosScreenState extends State<MisFavoritosScreen> {
  List favoritos = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarFavoritos();
  }

  Future<void> cargarFavoritos() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await ApiService.getFavoritos();
      setState(() {
        favoritos = data;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Favoritos'),
        backgroundColor: Colors.blue,
      ),
      drawer: const MenuDrawer(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
              : favoritos.isEmpty
                  ? const Center(child: Text('No tienes lugares favoritos aún.'))
                  : ListView.builder(
                      itemCount: favoritos.length,
                      itemBuilder: (context, index) {
                        final fav = favoritos[index];
                        final lugar = fav['lugar'];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: ListTile(
                            title: Text(lugar['nombre'] ?? ''),
                            subtitle: Text(lugar['direccion'] ?? ''),
                            trailing: const Icon(Icons.favorite, color: Colors.red),
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.lugarDetalle,
                              arguments: lugar['id'],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
} 