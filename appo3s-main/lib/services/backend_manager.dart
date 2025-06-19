//backend_manager.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

// carpeta donde está tu server.dart  (relativa al .exe/.app)
const _backendPath = 'backend/server.dart';
const _port        = 8080;
const _healthUrl   = 'http://localhost:$_port/health';

class BackendManager {
  BackendManager._();
  static final BackendManager instance = BackendManager._();

  Process? _proc;
  Timer?   _heartbeat;

  // ───────────────────────── PUBLIC ─────────────────────────
  Future<void> init() async {
    // si ya está arriba sólo activamos latido
    if (await _isUp()) {
      _startHeartbeat();
      return;
    }
    await _restart();
  }

  Future<void> dispose() async {
    await _proc?.kill();
    _heartbeat?.cancel();
  }

  // ───────────────────────── PRIVATE ────────────────────────
  Future<bool> _isUp() async {
    try {
      final req = await HttpClient()
          .getUrl(Uri.parse(_healthUrl))
          .timeout(const Duration(seconds: 2));
      final res = await req.close();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _restart() async {
    await _killPort();                       // libera 8080 si quedó colgado

    _proc = await Process.start(
      'dart', ['run', _backendPath],
      mode: ProcessStartMode.detachedWithStdio,
    );

    // log de depuración
    _proc!.stdout.transform(utf8.decoder).listen((l) => print('[BACK]  $l'));
    _proc!.stderr.transform(utf8.decoder).listen((l) => print('[BACK❗] $l'));

    final ok = await _waitUntilUp(const Duration(seconds: 10));
    if (!ok) {
      print('❌  Backend no responde (revisa backend/server.dart)');
    } else {
      print('✅  Backend levantado, pid ${_proc!.pid}');
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
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!await _isUp()) {
        print('⚠️  Backend caído, reiniciando…');
        await _restart();
      }
    });
  }

  Future<void> _killPort() async {
    if (Platform.isMacOS || Platform.isLinux) {
      final res = await Process.run('lsof', ['-ti:$_port']);
      final pids = (res.stdout as String).trim().split('\n').where((e) => e.isNotEmpty);
      for (final pid in pids) {
        await Process.run('kill', ['-9', pid]);
      }
    } else if (Platform.isWindows) {
      final res = await Process.run('netstat', ['-ano']);
      final lines = (res.stdout as String).split('\n');
      for (final l in lines) {
        if (l.contains('$_port') && l.contains('LISTEN')) {
          final pid = l.trim().split(RegExp(r'\s+')).last;
          await Process.run('taskkill', ['/F', '/PID', pid]);
        }
      }
    }
  }
}
