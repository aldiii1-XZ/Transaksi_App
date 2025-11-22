import 'package:flutter/material.dart';
import '../widgets/futuristic_page.dart';

class TambahTransaksiPage extends StatefulWidget {
  const TambahTransaksiPage({super.key});

  @override
  State<TambahTransaksiPage> createState() => _TambahTransaksiPageState();
}

class _TambahTransaksiPageState extends State<TambahTransaksiPage> {
  final TextEditingController namaC = TextEditingController();
  final TextEditingController jumlahC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FuturisticPage(
      title: "Tambah Transaksi",
      showBack: true,
      child: Column(
        children: [
          TextField(
            controller: namaC,
            decoration: _input("Nama Transaksi"),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 20),

          TextField(
            controller: jumlahC,
            keyboardType: TextInputType.number,
            decoration: _input("Jumlah"),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 30),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
            ),
            onPressed: () {},
            child: const Text(
              "Simpan",
              style: TextStyle(fontSize: 18),
            ),
          )
        ],
      ),
    );
  }

  InputDecoration _input(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
