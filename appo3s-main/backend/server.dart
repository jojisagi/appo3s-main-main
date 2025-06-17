//server.dart
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:dotenv/dotenv.dart' show load, env;

/// ─────────────────────────────────────────────────────────
/// 1. Cargar variables .env  (necesario:  MONGO_URI )
/// ─────────────────────────────────────────────────────────
Future<void> main() async {
  load();
  final mongoUri = env['MONGO_URI'];
  if (mongoUri == null) {
    print('❌  Falta MONGO_URI en .env');
    return;
  }

  /// ── 2. Conectar a MongoDB ─────────────────────────────
  final db = await Db.create(mongoUri);
  await db.open();
  final col = db.collection('biblioteca');        // <- cambia si necesitas otra colección

  /// ── 3. Definir rutas ─────────────────────────────────
  final router = Router()
  // Fallback para raíz
    ..get('/', (_) => Response.ok('Medición O₃ API', headers: _jsonHeaders))

  // Health-check
    ..get('/health', (_) => Response.ok(
      jsonEncode({'status': 'ok'}),
      headers: _jsonHeaders,
    ))

  // Obtener todos los registros
    ..get('/records', (_) async {
      final docs = await col.find().toList();
      return Response.ok(jsonEncode(docs), headers: _jsonHeaders);
    })

  // Insertar un registro
    ..post('/records', (Request req) async {
      try {
        final body     = await req.readAsString();
        final payload  = jsonDecode(body) as Map<String, dynamic>;

        if (!payload.containsKey('contaminante') ||
            !payload.containsKey('concentracion')) {
          return Response(
            400,
            body: jsonEncode({'error': 'Faltan campos requeridos'}),
            headers: _jsonHeaders,
          );
        }

        // Fecha por defecto si el cliente no la envía
        payload.putIfAbsent(
          'fechaHora',
              () => DateTime.now().toIso8601String(),
        );

        await col.insert(payload);
        return Response(201,
            body: jsonEncode({'ok': true}), headers: _jsonHeaders);
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': e.toString()}),
          headers: _jsonHeaders,
        );
      }
    });

  /// ── 4. Construir pipeline (CORS primero) ──────────────
  final handler = const Pipeline()
      .addMiddleware(_corsMiddleware)     // 👈 ¡primero!
      .addMiddleware(logRequests())
      .addHandler(router);

  /// ── 5. Arrancar servidor ──────────────────────────────
  final server = await serve(handler, '0.0.0.0', 8080);
  print('✅  API escuchando en http://${server.address.host}:${server.port}');
}

/// Encabezados JSON comunes
const _jsonHeaders = {'Content-Type': 'application/json; charset=utf-8'};

/// Middleware CORS permisivo (ajusta en producción)
Middleware get _corsMiddleware => (innerHandler) {
  Response _options() => Response.ok('', headers: _corsHeaders);

  return (Request req) async {
    if (req.method == 'OPTIONS') return _options();
    final res = await innerHandler(req);
    return res.change(headers: _corsHeaders);
  };
};

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': '*',
  ..._jsonHeaders,
};
