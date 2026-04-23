import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mongo_dart/mongo_dart.dart';



const _jsonHeaders = {'Content-Type': 'application/json; charset=utf-8'};

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

class Mongo{

Future<void> iniciar_mongo() async {
  final mongoUri = 'mongodb+srv://jorgesanchez:Alfresi123@cluster0.vsbti.mongodb.net/appo3s?retryWrites=true&w=majority';

  if (mongoUri.isEmpty) {
    print('❌  Falta MONGO_URI');
    return;
  }

  Db? db;
  DbCollection? col;

  try {
    db = await Db.create(mongoUri);
    await db.open();
    col = db.collection('biblioteca');
    print('✅ Conectado a MongoDB');
  } catch (e) {
    print('❌ No se pudo conectar a MongoDB: $e');
  }

  final router = Router()

    ..get('/', (_) => Response.ok('Medición O₃ API', headers: _jsonHeaders))

    ..get('/health', (_) => Response.ok(
      jsonEncode({'status': 'ok'}),
      headers: _jsonHeaders,
    ))

    ..get('/records', (_) async {
      if (col == null) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Base de datos no disponible'}),
          headers: _jsonHeaders,
        );
      }

      try {
        final docs = await col.find().toList();
        final serialized = docs.map(_serializeDoc).toList();
        return Response.ok(jsonEncode(serialized), headers: _jsonHeaders);
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al consultar registros: $e'}),
          headers: _jsonHeaders,
        );
      }
    })

    ..post('/records', (Request req) async {
      if (col == null) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Base de datos no disponible'}),
          headers: _jsonHeaders,
        );
      }

      try {
        final body = await req.readAsString();
        final payload = jsonDecode(body) as Map<String, dynamic>;

        if (!payload.containsKey('contaminante') ||
            !payload.containsKey('concentracion')) {
          return Response(400,
            body: jsonEncode({'error': 'Faltan campos requeridos'}),
            headers: _jsonHeaders,
          );
        }

        payload.putIfAbsent(
          'fechaHora',
              () => DateTime.now().toIso8601String(),
        );

        await col.insert(payload);
        return Response(201, body: jsonEncode(_serializeDoc(payload)), headers: _jsonHeaders);
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Error al insertar: $e'}),
          headers: _jsonHeaders,
        );
      }
    });

  final handler = const Pipeline()
      .addMiddleware(_corsMiddleware)
      .addMiddleware(logRequests())
      .addHandler(router);

  final server = await serve(handler, '0.0.0.0', 8080);
  print('🌐 API escuchando en http://${server.address.host}:${server.port}');
}

}

Map<String, dynamic> _serializeDoc(Map<String, dynamic> doc) {
  return doc.map((key, value) {
    if (value is ObjectId) return MapEntry(key, value.toHexString());
    if (value is Map<String, dynamic>) return MapEntry(key, _serializeDoc(value));
    if (value is List) return MapEntry(key, value.map((e) => e is Map<String, dynamic> ? _serializeDoc(e) : e).toList());
    return MapEntry(key, value);
  });
}