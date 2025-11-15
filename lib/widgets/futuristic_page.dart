// futuristic_page.dart
import 'package:flutter/material.dart';
import 'dart:ui';

class FuturisticPage extends StatelessWidget {
  final String title;
  final Widget content;

  const FuturisticPage({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F0C29),
                  Color(0xFF302B63),
                  Color(0xFF24243E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Blur futuristik
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Konten
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}
