import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FuturisticPage extends StatelessWidget {
  final String title;
  final Widget child;
  final bool showBack;

  const FuturisticPage({
    super.key,
    required this.title,
    required this.child,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    const textPrimary = Color(0xFF1F2933);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Color(0xFF52616B)),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                Color(0xFFF5FFE9),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
