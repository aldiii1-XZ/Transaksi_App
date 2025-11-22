// lib/pages/history_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    for (final s in raw) {
      try {
        final decoded = jsonDecode(s);
        if (decoded is Map) tmp.add(Map<String, dynamic>.from(decoded));
      } catch (_) {
        continue;
      }
    }
    history = tmp.reversed.toList();
    setState(() {});
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Semua History?'),
        content: const Text(
            'Semua catatan history akan dihapus permanen. Lanjutkan?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
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

  @override
  Widget build(BuildContext context) {
    return FuturisticPage(
      title: 'History (Owner)',
      showBack: true,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: ${history.length}',
                  style: const TextStyle(color: Colors.white70)),
              TextButton.icon(
                  onPressed: history.isEmpty ? null : _clearAll,
                  icon:
                      const Icon(Icons.delete_forever, color: Colors.redAccent),
                  label: const Text('Kosongkan',
                      style: TextStyle(color: Colors.redAccent))),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: history.isEmpty
                ? const Center(
                    child: Text('Belum ada history',
                        style: TextStyle(color: Colors.white54)))
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (c, i) {
                      final it = history[i];
                      final am = NumberFormat.decimalPattern('id_ID')
                          .format(it['amount']);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.04)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(it['name'],
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 6),
                                    Text('Tanggal: ${it['date']}',
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 13)),
                                  ]),
                            ),
                            Text('Rp $am',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700)),
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
