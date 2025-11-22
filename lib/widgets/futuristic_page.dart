// lib/widgets/futuristic_page.dart
import 'dart:ui';
import 'package:flutter/material.dart';

class FuturisticPage extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showBack;

  const FuturisticPage({
    super.key,
    required this.title,
    required this.child,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    // color palette (modern banking)
    const Color primary = Color(0xFF1B67C9); // blue BCA-like
    const Color accent = Color(0xFF1089FF); // bright accent
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        centerTitle: true,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                onPressed: () => Navigator.pop(context))
            : null,
      ),
      body: Stack(children: [
        // gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B1226), Color(0xFF0E254A), Color(0xFF122F6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),

        // soft top-right glow
        Positioned(
          right: -120,
          top: -60,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Color(0xFF1089FF).withOpacity(0.14),
                  Colors.transparent
                ],
              ),
            ),
          ),
        ),

        // blur glass layer
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(color: Colors.black.withOpacity(0.05)),
          ),
        ),

        // content area with padding
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: child,
          ),
        ),
      ]),
    );
  }
}
