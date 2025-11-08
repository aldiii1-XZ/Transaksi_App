import 'package:flutter/material.dart';

class TambahTransaksiPage extends StatefulWidget {
  const TambahTransaksiPage({super.key});

  @override
  State<TambahTransaksiPage> createState() => _TambahTransaksiPageState();
}

class _TambahTransaksiPageState extends State<TambahTransaksiPage> {
  final _namaController = TextEditingController();
  final _nominalController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nominalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                final nama = _namaController.text;
                final nominal = double.tryParse(_nominalController.text) ?? 0;
                if (nama.isNotEmpty && nominal > 0) {
                  Navigator.pop(context, {'nama': nama, 'nominal': nominal});
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
