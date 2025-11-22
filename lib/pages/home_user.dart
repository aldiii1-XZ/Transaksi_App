import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'futuristic_page.dart';

class HomeUser extends StatefulWidget {
  const HomeUser({super.key});

  @override
  State<HomeUser> createState() => _HomeUserState();
}

class _HomeUserState extends State<HomeUser> {
  final nameController = TextEditingController();
  final amountController = TextEditingController();

  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filtered = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("transactions");

    if (data != null) {
      transactions = List<Map<String, dynamic>>.from(json.decode(data));
    }

    filtered = List.from(transactions);
    setState(() {});
  }

  /// 👉 Format angka otomatis pakai titik
  String formatNumber(String value) {
    if (value.isEmpty) return "";
    final number = int.tryParse(value.replaceAll('.', ''));
    if (number == null) return value;
    return NumberFormat.decimalPattern('id_ID').format(number);
  }

  Future<void> save(String name, String amountRaw) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateFormat('dd/MM/yyyy').format(DateTime.now());

    // 👉 Simpan nominal tanpa titik, sebagai angka murni
    final cleaned = amountRaw.replaceAll('.', '');
    final number = int.tryParse(cleaned) ?? 0;

    final item = {
      "name": name,
      "amount": number,
      "date": now
    };

    transactions.add(item);

    await prefs.setString("transactions", json.encode(transactions));

    filtered = List.from(transactions);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FuturisticPage(
      title: "Menu User",
      child: Column(
        children: [
          TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "Nama Pemberi",
              labelStyle: TextStyle(color: Colors.white70),
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: "Nominal (Rp)",
              labelStyle: TextStyle(color: Colors.white70),
            ),
            onChanged: (value) {
              final formatted = formatNumber(value);
              amountController.value = TextEditingValue(
                text: formatted,
                selection: TextSelection.collapsed(offset: formatted.length),
              );
            },
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  amountController.text.isNotEmpty) {
                save(nameController.text, amountController.text);
                nameController.clear();
                amountController.clear();
              }
            },
            child: const Text("Simpan"),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final item = filtered[i];

                // 👉 Format ulang angka saat ditampilkan
                final tampilNominal =
                    NumberFormat.decimalPattern('id_ID').format(item['amount']);

                return Card(
                  color: Colors.white.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    title: Text(
                      "${item['name']} - Rp $tampilNominal",
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      "Tanggal: ${item['date']}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    leading: const Icon(Icons.payment, color: Colors.blueAccent),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
