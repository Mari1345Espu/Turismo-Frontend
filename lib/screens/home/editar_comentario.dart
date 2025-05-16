import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/logger_service.dart';

class EditarComentario extends StatefulWidget {
  final int comentarioId;
  final int lugarId;
  final String textoInicial;
  final int calificacionInicial;
  final String lugarNombre;

  const EditarComentario({
    super.key,
    required this.comentarioId,
    required this.lugarId,
    required this.textoInicial,
    required this.calificacionInicial,
    required this.lugarNombre,
  });

  @override
  State<EditarComentario> createState() => _EditarComentarioState();
}

class _EditarComentarioState extends State<EditarComentario> {
  final comentarioCtrl = TextEditingController();
  int calificacion = 5;
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    comentarioCtrl.text = widget.textoInicial;
    calificacion = widget.calificacionInicial;
  }

  Future<void> actualizarComentario() async {
    if (comentarioCtrl.text.trim().isEmpty) {
      setState(() {
        error = 'El texto del comentario no puede estar vacío';
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await ApiService.editarComentario(
        comentarioId: widget.comentarioId,
        texto: comentarioCtrl.text.trim(),
        calificacion: calificacion,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comentario actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      LoggerService.error('Error al actualizar comentario', e);
      if (mounted) {
        setState(() {
          loading = false;
          error = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar comentario'), 
        backgroundColor: Colors.blue
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.place, color: Colors.blue, size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.lugarNombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Estás editando tu comentario para este lugar',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tu calificación:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    i < calificacion ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () => setState(() => calificacion = i + 1),
                  tooltip: '${i + 1} estrellas',
                );
              }),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tu comentario:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: comentarioCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Escribe tu opinión sobre este lugar...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    error!,
                    style: TextStyle(color: Colors.red[800]),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loading ? null : actualizarComentario,
                icon: loading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  loading ? 'Guardando...' : 'Guardar cambios',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
