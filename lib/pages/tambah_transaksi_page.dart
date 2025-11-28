import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/format.dart';

class TambahTransaksiPage extends StatefulWidget {
  const TambahTransaksiPage({super.key});

  @override
  State<TambahTransaksiPage> createState() => _TambahTransaksiPageState();
}

class _TambahTransaksiPageState extends State<TambahTransaksiPage> {
  final TextEditingController namaController = TextEditingController();
  final TextEditingController nominalController = TextEditingController();

  bool isSaving = false;

  @override
  void dispose() {
    namaController.dispose();
    nominalController.dispose();
    super.dispose();
  }

  Future<void> saveTransaction() async {
    if (namaController.text.isEmpty || nominalController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap isi semua data terlebih dahulu")),
      );
      return;
    }

    final rawNominal = nominalController.text.replaceAll('.', '');
    final parsedNominal = int.tryParse(rawNominal);

    if (parsedNominal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nominal tidak valid")),
      );
      return;
    }

    setState(() => isSaving = true);

    final newItem = {
      "name": namaController.text.trim(),
      "amount": parsedNominal,
      "date": DateFormat("dd MMM yyyy, HH:mm").format(DateTime.now()),
    };

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList("history") ?? [];
    existing.add(jsonEncode(newItem));
    await prefs.setStringList("history", existing);

    if (!mounted) return;

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Transaksi berhasil disimpan")),
    );

    Navigator.pop(context, true);
  }

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
                final formatted = formatRupiah(value);
                nominalController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isSaving ? null : saveTransaction,
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Simpan"),
            )
          ],
        ),
      ),
    );
  }
}
