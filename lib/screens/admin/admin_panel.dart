import 'package:flutter/material.dart';
import '../../widgets/menu_drawer.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Panel de administrador'),
          backgroundColor: Colors.blue),
      drawer: const MenuDrawer(),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildCard(
            icon: Icons.comment_bank,
            title: 'Comentarios',
            color: Colors.orange,
            onTap: () => Navigator.pushNamed(context, '/admin-comentarios'),
          ),
          _buildCard(
            icon: Icons.place,
            title: 'Lugares',
            color: Colors.green,
            onTap: () => Navigator.pushNamed(context, '/admin-lugares'),
          ),
          _buildCard(
            icon: Icons.admin_panel_settings,
            title: 'Roles',
            color: Colors.indigo,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gestión de roles próximamente')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        color: Color.fromRGBO(
          color.r.toInt(),
          color.g.toInt(),
          color.b.toInt(),
          0.1,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(title,
                  style: TextStyle(
                      fontSize: 16, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
