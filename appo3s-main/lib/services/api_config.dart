import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

/// ───── Configura estas dos constantes ─────
/// • Si la app y el backend se ejecutan en la misma máquina → “localhost”.
/// • Si el backend está en otro PC de la LAN, pon su IP (p. ej. “192.168.1.20”).
const _host  = 'localhost';
const _port  = '8080';
/// ──────────────────────────────────────────

const _androidEmuBase = 'http://10.0.2.2:8080';   // Emulador Android

String get _lanBase => 'http://$_host:$_port';

/// URL base correcta para cada plataforma
String get baseUrl {
  if (kIsWeb) return _lanBase;          // Flutter Web
  if (Platform.isAndroid) return _androidEmuBase;
  return _lanBase;                      // iOS, macOS, Windows, Linux
}
