import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// FastAPI 백엔드 기본 주소.
const String kApiBase = 'http://127.0.0.1:8000';
const String kAndroidEmulatorApiBase = 'http://10.0.2.2:8000';

/// 실행 환경별로 자동 선택된 API 주소.
String get resolvedApiBase {
  if (kIsWeb) return kApiBase;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return kAndroidEmulatorApiBase;
    default:
      return kApiBase;
  }
}

const Color kSeedColor = Color(0xFF6CC6A8);
const Color kSurfaceColor = Color(0xFFF7F8FA);
