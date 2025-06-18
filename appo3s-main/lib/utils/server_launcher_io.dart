import 'dart:io';

class ServerLauncher {
  static const _healthUrl = 'http://localhost:8080/health';

  static Future<void> launchIfNeeded() async {
    if (await _isRunning()) return;

    try {
      final cmd = Platform.isWindows
          ? 'start cmd /c dart run backend/server.dart'
          : 'dart run backend/server.dart';

      await Process.start(
        Platform.isWindows ? 'cmd' : 'bash',
        Platform.isWindows ? ['/c', cmd] : ['-c', cmd],
        workingDirectory: Directory.current.path,
        mode: ProcessStartMode.detached,
      );
      stdout.writeln('🚀 Servidor lanzado automáticamente');
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      stderr.writeln('❌ No se pudo lanzar el servidor: $e');
    }
  }

  static Future<bool> _isRunning() async {
    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(_healthUrl));
      final res = await req.close();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
