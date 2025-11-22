import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TambahTransaksiPage extends StatefulWidget {
  const TambahTransaksiPage({super.key});

  @override
  State<TambahTransaksiPage> createState() => _TambahTransaksiPageState();
}

class _TambahTransaksiPageState extends State<TambahTransaksiPage> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController nominalController = TextEditingController();

  final formatter = NumberFormat.decimalPattern('id');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Transaksi")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: namaController,
              decoration: const InputDecoration(
                labelText: "Nama Transaksi",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Nominal otomatis jadi format 12.000
            TextField(
              controller: nominalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Nominal",
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                String raw = value.replaceAll('.', '');

                if (raw.isEmpty) {
                  nominalController.text = '';
                  return;
                }

                String formatted = formatter.format(int.parse(raw));

                nominalController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                if (namaController.text.isEmpty ||
                    nominalController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Harap isi semua data terlebih dahulu")),
                  );
                  return;
                }

                // ACTION SIMPAN — nanti kamu sambungkan ke save real database
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Transaksi berhasil disimpan")),
                );

                Navigator.pop(context);
              },
              child: const Text("Simpan"),
            )
          ],
        ),
      ),
    );
  }
}
