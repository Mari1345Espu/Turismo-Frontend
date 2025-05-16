import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/logger_service.dart';

class AgregarComentario extends StatefulWidget {
  final int lugarId;
  final String lugarNombre;
  final String token;

  const AgregarComentario({
    super.key,
    required this.lugarId,
    required this.token,
    required this.lugarNombre,
  });

  @override
  State<AgregarComentario> createState() => _AgregarComentarioState();
}

class _AgregarComentarioState extends State<AgregarComentario> {
  final textoCtrl = TextEditingController();
  double calificacion = 3;
  bool loading = false;
  String? error;
  bool exito = false;

  Future<void> enviarComentario() async {
    if (textoCtrl.text.trim().isEmpty) {
      setState(() {
        error = 'El texto del comentario no puede estar vacío';
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
      exito = false;
    });

    try {
      await ApiService.crearComentario(
        lugarId: widget.lugarId,
        texto: textoCtrl.text.trim(),
        calificacion: calificacion.toInt(),
      );
      
      if (mounted) {
        setState(() {
          loading = false;
          exito = true;
          error = null;
        });
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Comentario enviado! Será visible cuando un administrador lo apruebe.'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Esperar un momento y luego cerrar la pantalla
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context, true); // Devolvemos true para indicar que se creó el comentario
        }
      }
    } catch (e) {
      LoggerService.error('Error al crear comentario', e);
      if (mounted) {
        setState(() {
          loading = false;
          error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reseña: ${widget.lugarNombre}'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Qué te pareció este lugar?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Calificación:'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < calificacion.toInt() 
                            ? Icons.star 
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          calificacion = (index + 1).toDouble();
                        });
                      },
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Tu comentario:'),
            const SizedBox(height: 8),
            TextField(
              controller: textoCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Comparte tu experiencia en este lugar...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loading || exito ? null : enviarComentario,
                icon: loading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : exito
                        ? const Icon(Icons.check_circle)
                        : const Icon(Icons.send),
                label: Text(
                  loading ? 'Enviando...' : exito ? 'Enviado' : 'Enviar reseña',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
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
            if (exito)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green),
                  ),
                  child: const Text(
                    '¡Comentario enviado con éxito! Será revisado por un administrador antes de ser publicado.',
                    style: TextStyle(color: Colors.green),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
