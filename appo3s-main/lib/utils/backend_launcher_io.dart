// Solo se compila donde existe dart:io
import 'dart:async';
import 'dart:io';

class BackendLauncher {
  static const _healthUrl = 'http://localhost:8080/health';
  static const _cmd       = ['dart', 'run', 'backend/server.dart'];

  /// Arranca el backend si /health no responde (timeout 1 s).
  static Future<void> launchIfNeeded() async {
    if (await _isOnline()) return;

    // Kill procesos viejos (opcional, macOS / Linux)
    if (Platform.isMacOS || Platform.isLinux) {
      await Process.run('lsof', ['-ti:8080']).then((res) async {
        if (res.stdout.toString().trim().isNotEmpty) {
          for (final pid in res.stdout.toString().trim().split('\n')) {
            await Process.run('kill', ['-9', pid]);
          }
        }
      });
    }

    print('[BACKEND] Lanzando server.dart…');
    Process.start(_cmd.first, _cmd.sublist(1),
        mode: ProcessStartMode.detachedWithStdio).then((proc) {
      // Imprime logs para depurar (opcional)
      proc.stdout.transform(SystemEncoding().decoder).listen(
              (l) => print('[BACK] $l'));
      proc.stderr.transform(SystemEncoding().decoder).listen(
              (l) => print('[BACK-ERR] $l'));
    });

    // Espera a que /health responda
    final ok = await _waitUntilOnline(const Duration(seconds: 8));
    if (!ok) {
      print('❌ Backend no levantó; revisa backend/server.dart');
    }
  }

  // ---------- helpers ----------
  static Future<bool> _isOnline() async {
    try {
      final client = HttpClient();
      final req    = await client
          .getUrl(Uri.parse(_healthUrl))
          .timeout(const Duration(seconds: 1));
      final res = await req.close();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> _waitUntilOnline(Duration max) async {
    final end = DateTime.now().add(max);
    while (DateTime.now().isBefore(end)) {
      if (await _isOnline()) return true;
      await Future.delayed(const Duration(seconds: 1));
    }
    return false;
  }
}
