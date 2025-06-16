import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

const _webBase = 'http://localhost:8080';        // Web (Safari, Chrome)
const _androidEmuBase = 'http://10.0.2.2:8080';  // Emulador Android
const _iosSimBase = 'http://127.0.0.1:8080';     // iOS Simulator

String get baseUrl {
  if (kIsWeb) return _webBase;
  if (Platform.isAndroid) return _androidEmuBase;
  if (Platform.isIOS || Platform.isMacOS) return _iosSimBase;
  return _webBase;
}
