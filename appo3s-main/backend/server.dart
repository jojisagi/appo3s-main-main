import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:dotenv/dotenv.dart' show load, env;

void main() async {
  load();

  final db = await Db.create(env['MONGO_URI']!);
  await db.open();
  final col = db.collection('registros');

  final app = Router()
    ..get('/records', (Request req) async {
      final rs = await col.find().toList();
      return Response.ok(jsonEncode(rs));
    })
    ..post('/records', (Request req) async {
      final body = await req.readAsString();
      await col.insert(jsonDecode(body));
      return Response.ok('ok');
    });

  final handler =
  const Pipeline().addMiddleware(logRequests()).addHandler(app);

  await serve(handler, '0.0.0.0', 8080);
  print('✅  API escuchando en http://localhost:8080');
}
