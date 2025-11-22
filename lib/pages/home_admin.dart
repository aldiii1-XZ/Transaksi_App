// lib/pages/home_admin.dart
import 'package:flutter/material.dart';
import '../widgets/futuristic_page.dart';
import 'history_page.dart';

class HomeAdmin extends StatelessWidget {
  const HomeAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return FuturisticPage(
      title: 'Admin Panel',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Selamat datang, Admin',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total transaksi tersimpan',
                    style: TextStyle(color: Colors.white70)),
                ElevatedButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const HistoryPage())),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B67C9)),
                  child: const Text('Lihat History'),
                )
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
              child: Center(
                  child: Image.asset('assets/banking_illustration.png',
                      width: 260, fit: BoxFit.contain))),
        ],
      ),
    );
  }
}
