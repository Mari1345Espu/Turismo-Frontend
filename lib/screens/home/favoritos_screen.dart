import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/menu_drawer.dart';
import '../../routes/app_routes.dart';
import 'lugar_detalle.dart';

class FavoritosScreen extends StatefulWidget {
  const FavoritosScreen({super.key});

  @override
  State<FavoritosScreen> createState() => _FavoritosScreenState();
}

class _FavoritosScreenState extends State<FavoritosScreen> {
  List<dynamic> favoritos = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargarFavoritos();
  }

  Future<void> cargarFavoritos() async {
    if (!AuthService.estaAutenticado) {
      setState(() {
        error = 'Debes iniciar sesión para ver tus favoritos';
        loading = false;
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final favs = await ApiService.getFavoritos();
      if (mounted) {
        setState(() {
          favoritos = favs;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          loading = false;
        });
      }
    }
  }

  Future<void> quitarFavorito(int lugarId) async {
    try {
      await ApiService.toggleFavorito(lugarId);
      await cargarFavoritos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al quitar de favoritos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget buildLugarCard(Map<String, dynamic> lugar) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: lugar['imagen_principal'] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  lugar['imagen_principal'],
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.place, color: Colors.grey),
              ),
        title: Text(
          lugar['nombre'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                lugar['categoria'],
                style: TextStyle(color: Colors.blue[900], fontSize: 12),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                ...List.generate(5, (i) {
                  return Icon(
                    i < (lugar['calificacion_promedio'] ?? 0).round()
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  '(${lugar['calificacion_promedio']?.toStringAsFixed(1) ?? 'Sin calificaciones'})',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red),
          onPressed: () => quitarFavorito(lugar['id']),
          tooltip: 'Quitar de favoritos',
        ),
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.lugarDetalle,
          arguments: lugar['id'],
        ).then((_) => cargarFavoritos()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Mis Favoritos',
        showDrawer: true,
      ),
      drawer: const MenuDrawer(),
      body: RefreshIndicator(
        onRefresh: cargarFavoritos,
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
                          onPressed: cargarFavoritos,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  )
                : favoritos.isEmpty
                    ? const Center(
                        child: Text(
                          'No tienes lugares favoritos',
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: favoritos.length,
                        itemBuilder: (context, index) =>
                            buildLugarCard(favoritos[index]['lugar']),
                      ),
      ),
    );
  }
}
