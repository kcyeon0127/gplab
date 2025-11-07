import 'package:flutter/material.dart';

/// 소셜 탭: 향후 확장 예정.
class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('소셜')),
      body: const Center(child: Text('소셜 피드 준비중')),
    );
  }
}
