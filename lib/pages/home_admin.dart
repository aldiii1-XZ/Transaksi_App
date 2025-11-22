import 'package:flutter/material.dart';
import 'history_page.dart';
import '../widgets/futuristic_page.dart';

class HomeAdmin extends StatelessWidget {
  const HomeAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return FuturisticPage(
      title: "Panel Admin",
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Admin dapat melihat semua history transaksi.",
            style: TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            },
            child: const Text("Lihat History"),
          ),
        ],
      ),
    );
  }
}
