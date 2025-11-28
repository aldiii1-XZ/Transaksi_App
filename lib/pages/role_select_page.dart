import 'package:flutter/material.dart';
import 'home_admin.dart';
import 'owner_page.dart';
import 'home_page.dart';
import 'login_page.dart';

class RoleSelectPage extends StatelessWidget {
  const RoleSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B1023), Color(0xFF111A33)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Pilih Mode",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Masuk sebagai owner, admin, atau pengguna biasa.",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView(
                    children: [
                      _RoleCard(
                        title: "Owner",
                        subtitle: "Pantau seluruh transaksi dan history.",
                        icon: Icons.star_rounded,
                        color: Colors.amberAccent,
                        onTap: () => _open(context, const OwnerPage()),
                      ),
                      _RoleCard(
                        title: "Admin",
                        subtitle: "Kelola dan lihat history lengkap.",
                        icon: Icons.shield_moon_rounded,
                        color: Colors.cyanAccent,
                        onTap: () => _open(context, const HomeAdmin()),
                      ),
                      _RoleCard(
                        title: "User",
                        subtitle: "Catat transaksi harian dengan tampilan modern.",
                        icon: Icons.person_pin_circle_rounded,
                        color: Colors.greenAccent,
                        onTap: () => _open(context, const HomePage()),
                      ),
                      _RoleCard(
                        title: "Masuk / Login",
                        subtitle: "Gunakan kredensial jika diperlukan.",
                        icon: Icons.lock_open_rounded,
                        color: Colors.purpleAccent,
                        onTap: () => _open(context, const LoginPage()),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70)
          ],
        ),
      ),
    );
  }
}
