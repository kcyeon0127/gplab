import 'package:flutter/material.dart';

/// 주간 패널 열림/닫힘을 제어하는 삼각형 토글 버튼.
class TriangleToggleButton extends StatelessWidget {
  const TriangleToggleButton({super.key, required this.isOpen, required this.onTap});

  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 250),
            turns: isOpen ? 0.5 : 0.0,
            curve: Curves.easeInOut,
            child: const Icon(Icons.expand_more, color: Colors.grey, size: 24),
          ),
        ),
      ),
    );
  }
}
