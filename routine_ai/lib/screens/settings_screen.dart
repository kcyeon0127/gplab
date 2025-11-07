import 'package:flutter/material.dart';

/// 설정 탭: 향후 확장 예정.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: const Center(child: Text('설정 페이지 준비중')),
    );
  }
}
