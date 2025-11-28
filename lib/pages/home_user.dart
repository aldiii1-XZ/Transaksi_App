import 'package:flutter/material.dart';

class HomeUserPage extends StatelessWidget {
  const HomeUserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Transaksi"),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10, 
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text("Transaksi #${index + 1}"),
              subtitle: const Text("Status: Selesai"),
              trailing: const Text("Rp 20.000"),
            ),
          );
        },
      ),
    );
  }
}
