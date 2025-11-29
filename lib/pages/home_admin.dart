import 'package:flutter/material.dart';
import '../models/user_role.dart';
import 'history_page.dart';
import 'tambah_transaksi_page.dart';

class HomeAdmin extends StatelessWidget {
  const HomeAdmin({super.key});

  Future<void> _openTambah(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TambahTransaksiPage(role: UserRole.admin),
      ),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HistoryPage(role: UserRole.admin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Panel Admin")),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Admin dapat menambahkan transaksi serta mengelola history.",
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () => _openTambah(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Tambah Transaksi"),
            ),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () => _openHistory(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Lihat History Transaksi"),
            ),
          ],
        ),
      ),
    );
  }
}
