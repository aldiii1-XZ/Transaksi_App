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
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.2),
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
      body: Stack(
        children: [
          // Background gradien futuristik
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F0F1F),
                  Color(0xFF1A1F3C),
                  Color(0xFF1C2A50),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Blur efek futuristik
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Container(color: Colors.black.withOpacity(0.1)),
          ),

          // Konten
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
