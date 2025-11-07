import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 기본 위젯 테스트 (렌더링 확인용).
void main() {
  testWidgets('머티리얼 스캐폴드 렌더링', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
