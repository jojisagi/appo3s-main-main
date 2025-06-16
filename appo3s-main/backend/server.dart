import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:dotenv/dotenv.dart' show load, env;

/// --- Configuración --------------------------------------------------------------------

Future<void> main() async {
  // 1. Cargar .env
  load();
  final mongoUri = env['MONGO_URI'];
  if (mongoUri == null) {
    print('❌  Falta MONGO_URI en .env');
    return;
  }

  // 2. Conectar a MongoDB
  final db = await Db.create(mongoUri);
  await db.open();
  final col = db.collection('biblioteca');   // Cambia si prefieres otra colección

  // 3. Definir router
  final router = Router()
  // Health-check
    ..get('/health', (Request _) => Response.ok(jsonEncode({'status': 'ok'}),
        headers: _jsonHeaders))
  // Obtener todos los registros
    ..get('/records', (Request _) async {
      final lista = await col.find().toList();
      return Response.ok(jsonEncode(lista), headers: _jsonHeaders);
    })
  // Insertar un registro
    ..post('/records', (Request req) async {
      try {
        final body = await req.readAsString();
        final data = jsonDecode(body) as Map<String, dynamic>;

        // Validación mínima
        if (!data.containsKey('contaminante') ||
            !data.containsKey('concentracion')) {
          return Response(400,
              body: jsonEncode({'error': 'Faltan campos requeridos'}),
              headers: _jsonHeaders);
        }

        // Si el ESP no envía fecha, la generamos aquí
        data.putIfAbsent('fechaHora', () => DateTime.now().toIso8601String());

        await col.insert(data);
        return Response(201, body: jsonEncode({'ok': true}), headers: _jsonHeaders);
      } catch (e) {
        return Response.internalServerError(
            body: jsonEncode({'error': e.toString()}),
            headers: _jsonHeaders);
      }
    });

  // 4. Pipeline con CORS + Logging
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(_corsMiddleware) // CORS primero
      .addHandler(router);

  // 5. Arrancar servidor
  final server = await serve(handler, '0.0.0.0', 8080);
  print('✅  API escuchando en http://${server.address.host}:${server.port}');
}

/// Encabezados JSON comunes
const _jsonHeaders = {'Content-Type': 'application/json; charset=utf-8'};

/// Middleware simple de CORS (permite todo; ajusta para producción)
Response _handleOptions(Request req) => Response.ok('',
    headers: {
      ..._jsonHeaders,
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    });

Middleware get _corsMiddleware => (innerHandler) {
  return (Request req) async {
    // Opciones preflight
    if (req.method == 'OPTIONS') return _handleOptions(req);

    // Respuesta normal con cabeceras CORS
    final resp = await innerHandler(req);
    return resp.change(headers: {
      'Access-Control-Allow-Origin': '*',
      ...resp.headers,
    });
  };
};
