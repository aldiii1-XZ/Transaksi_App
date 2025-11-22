// history_page.dart
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../widgets/futuristic_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('history') ?? [];

    final List<Map<String, dynamic>> tmp = [];
    for (final e in raw) {
      try {
        final decoded = jsonDecode(e);
        if (decoded is Map) {
          tmp.add(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {
        continue;
      }
    }

    history = tmp.reversed.toList();
    setState(() {});
  }

  /// Format angka agar muncul titik seperti "150.000"
  String formatNominal(dynamic raw) {
    if (raw == null) return "0";
    final cleaned = raw.toString().replaceAll('.', '').replaceAll(',', '');
    final value = int.tryParse(cleaned) ?? 0;
    return NumberFormat.decimalPattern('id').format(value);
  }

  Future<void> _clearHistoryConfirm() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus History'),
        content: const Text('Yakin ingin menghapus seluruh history transaksi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Hapus')),
        ],
      ),
    );

    if (ok == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('history');
      setState(() => history = []);
    }
  }

  Widget _card(Map<String, dynamic> item) {
    final name = item['name'] ?? item['nama'] ?? '—';
    final amount = formatNominal(item['amount'] ?? item['nominal']);
    final date = item['date'] ?? item['tanggal'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$name",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  "Rp $amount",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          Text(
            "$date",
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FuturisticPage(
      title: "History Transaksi",
      showBack: true,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${history.length}',
                style: const TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w600),
              ),
              TextButton.icon(
                onPressed: history.isEmpty ? null : _clearHistoryConfirm,
                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                label: const Text('Kosongkan',
                    style: TextStyle(color: Colors.redAccent)),
              )
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: history.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada history transaksi',
                      style: TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, i) => _card(history[i]),
                  ),
          ),
        ],
      ),
    );
  }
}
