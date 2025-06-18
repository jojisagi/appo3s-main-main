import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Path RELATIVO al ejecutable de tu app (ajústalo si cambias carpetas)
const _backendPath = 'backend/server.dart';
const _host        = 'localhost';
const _port        = 8080;
const _healthUrl   = 'http://$_host:$_port/health';

class BackendManager {
  BackendManager._();
  static final BackendManager instance = BackendManager._();

  Process? _proc;                           // proceso en ejecución
  Timer?   _timer;                          // heart-beat

  /// Llama a esto lo antes posible (p. ej. en main.dart)
  Future<void> init() async {
    if (await _isUp()) {
      _startHeartbeat();
      return;
    }
    await _restart();
  }

  /// ------------------------------------------------------------ PRIVATE ---

  Future<bool> _isUp() async {
    try {
      final req = await HttpClient().getUrl(Uri.parse(_healthUrl))
          .timeout(const Duration(seconds: 2));
      final res = await req.close();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _restart() async {
    await _killPort();           // libera el 8080 si algo quedó colgado
    _proc = await Process.start(
      'dart',
      ['run', _backendPath],
      mode: ProcessStartMode.detachedWithStdio,
    );

    // Imprime stdout/stderr para depurar
    _proc!.stdout.transform(utf8.decoder).listen((l) => print('[BACK] $l'));
    _proc!.stderr.transform(utf8.decoder).listen((l) => print('[BACK-ERR] $l'));

    // Espera hasta que /health responda o 10 s de timeout
    final ok = await _waitUntilUp(const Duration(seconds: 10));
    if (!ok) {
      print('❌ Backend no responde; revisa server.dart');
    } else {
      print('✅ Backend levantado (PID ${_proc!.pid})');
      _startHeartbeat();
    }
  }

  Future<bool> _waitUntilUp(Duration max) async {
    final end = DateTime.now().add(max);
    while (DateTime.now().isBefore(end)) {
      if (await _isUp()) return true;
      await Future.delayed(const Duration(seconds: 1));
    }
    return false;
  }

  void _startHeartbeat() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!await _isUp()) {
        print('⚠️ Backend caído. Reiniciando…');
        await _restart();
      }
    });
  }

  Future<void> _killPort() async {
    if (Platform.isMacOS || Platform.isLinux) {
      // lsof devuelve los PIDs que escuchan en :8080
      final result = await Process.run('lsof', ['-ti:$_port']);
      if (result.stdout is String && result.stdout.toString().trim().isNotEmpty) {
        final pids = result.stdout.toString().trim().split('\n');
        for (var pid in pids) {
          await Process.run('kill', ['-9', pid]);
        }
      }
    } else if (Platform.isWindows) {
      // netstat -> findstr -> taskkill
      final res = await Process.run('netstat', ['-ano']);
      final lines = (res.stdout as String).split('\n');
      for (var l in lines) {
        if (l.contains('$_host:$_port')) {
          final pid = l.trim().split(RegExp(r'\s+')).last;
          await Process.run('taskkill', ['/F', '/PID', pid]);
        }
      }
    }
  }

  /// Llama a esto cuando cierres la app (quit), si quieres limpiar.
  Future<void> dispose() async {
    await _proc?.kill();
    _timer?.cancel();
  }
}
