import 'dart:ui';
import 'package:flutter/material.dart';

class FuturisticPage extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showBack;

  const FuturisticPage(
      {super.key,
      required this.title,
      required this.child,
      this.showBack = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        centerTitle: true,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => Navigator.pop(context))
            : null,
      ),
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B1226), Color(0xFF0E254A), Color(0xFF122F6A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(color: Colors.black.withOpacity(0.06)),
          ),
        ),
        SafeArea(
            child: Padding(padding: const EdgeInsets.all(16), child: child)),
      ]),
    );
  }
}
