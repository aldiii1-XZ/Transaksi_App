import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transaksi_app/widgets/futuristic_page.dart';

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
    final raw = prefs.getString("transactions");
    if (raw != null) {
      transactions = List<Map<String, dynamic>>.from(jsonDecode(raw));
    }
    filtered = List.from(transactions);
    setState(() {});
  }

  /// 👉 Format angka input agar ada titik (.) sebagai pemisah
  String formatNumber(String value) {
    value = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (value.isEmpty) return "";
    final number = int.parse(value);

    return NumberFormat("#,###", "id_ID").format(number).replaceAll(",", ".");
  }

  /// 👉 Simpan angka tanpa titik (untuk JSON)
  Future<void> save(String name, String amountRaw) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final cleaned = amountRaw.replaceAll('.', '');
    final number = int.tryParse(cleaned) ?? 0;

    final item = {
      "name": name,
      "amount": number,
      "date": now,
    };

    transactions.add(item);
    await prefs.setString("transactions", jsonEncode(transactions));

    filtered = List.from(transactions);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FuturisticPage(
      title: "Dashboard User",
      child: Column(
        children: [
          // ---------------- NAMA ----------------
          TextField(
            controller: nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Nama Pemberi",
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 15),

          // ---------------- NOMINAL ----------------
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Nominal (Rp)",
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
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

          // ---------------- TOMBOL SIMPAN ----------------
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  save(nameController.text, amountController.text);
                  nameController.clear();
                  amountController.clear();
                }
              },
              child: const Text(
                "Simpan",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 25),

          // ---------------- LIST DATA ----------------
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final item = filtered[i];

                final formattedAmount = NumberFormat("#,###", "id_ID")
                    .format(item['amount'])
                    .replaceAll(",", ".");

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Rp $formattedAmount",
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              "Tanggal: ${item['date']}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
