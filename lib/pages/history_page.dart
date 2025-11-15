import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> historyList;

  const HistoryPage({super.key, required this.historyList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("History Transaksi")),
      body: ListView.builder(
        itemCount: historyList.length,
        itemBuilder: (context, index) {
          final item = historyList[index];

          final tanggal = item['tanggal'] as DateTime;
          final formatTanggal =
              "${tanggal.day}-${tanggal.month}-${tanggal.year} "
              "${tanggal.hour}:${tanggal.minute.toString().padLeft(2, '0')}";

          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(item['nama']),
            subtitle: Text("Rp ${item['nominal']} • $formatTanggal"),
          );
        },
      ),
    );
  }
}
