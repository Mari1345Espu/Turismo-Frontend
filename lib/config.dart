// URLs para la API
// Si estás ejecutando la app en un emulador Android, usa 10.0.2.2 en lugar de 127.0.0.1
// Si estás ejecutando en un dispositivo físico, usa la IP de tu máquina en la red local
// Por ejemplo: 192.168.1.X

// URL del servidor backend - CAMBIAR AQUÍ según tu entorno
// Opciones comunes:
// - Emulador Android: 'http://10.0.2.2:8000/api/'
// - Dispositivo físico/Emulador iOS: 'http://192.168.X.X:8000/api/' (tu IP local)
// - Servidor en la nube: 'https://tu-dominio.com/api/'
// - Desarrollo local: 'http://localhost:8000/api/' o 'http://127.0.0.1:8000/api/'
const String baseURL = 'http://127.0.0.1:8000/api/';

// URLs derivadas
const String authURL = '${baseURL}auth/';
const String lugaresURL = '${baseURL}lugares/';
const String favoritosURL = '${baseURL}favoritos/';

// Configuración de timeouts (en segundos)
const int requestTimeout = 30;  // Aumentado para dar más tiempo a la red
const int connectTimeout = 20;
