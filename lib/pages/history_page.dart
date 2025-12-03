import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_role.dart';
import '../utils/format.dart';
import '../widgets/futuristic_page.dart';

class HistoryPage extends StatefulWidget {
  final UserRole role;

  const HistoryPage({
    super.key,
    this.role = UserRole.user,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList("history") ?? [];

    final temp = <Map<String, dynamic>>[];

    for (var i = 0; i < rawList.length; i++) {
      final item = rawList[i];
      try {
        final data = jsonDecode(item);
        final map = Map<String, dynamic>.from(data);
        map['amount'] = _parseAmount(map['amount']);
        map['_storageIndex'] = i; // keep pointer to original list position
        temp.add(map);
      } catch (_) {}
    }

    // urutan terbaru di atas
    setState(() {
      history = temp.reversed.toList();
    });
  }

  int _parseAmount(dynamic raw) {
    if (raw is int) return raw;
    if (raw is String) {
      final cleaned = raw.replaceAll('.', '').replaceAll(',', '');
      return int.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  Future<void> clearAll() async {
    if (!_canManage) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Semua"),
        content: const Text("Yakin ingin menghapus seluruh history?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("history");
      setState(() {
        history = [];
      });
    }
  }

  bool get _canManage =>
      widget.role == UserRole.admin || widget.role == UserRole.owner;

  String _roleLabel(dynamic raw) {
    return userRoleFromString(raw?.toString()).label;
  }

  Future<void> _deleteItem(Map<String, dynamic> item) async {
    if (!_canManage) return;

    final name = item['name']?.toString() ?? 'transaksi';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus transaksi ini?"),
        content: Text(
          "Hapus \"$name\" dari history? Cocok jika ada input yang salah.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Hapus",
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList("history") ?? [];
    final createdAt = item['createdAt']?.toString();
    final storageIndex = item['_storageIndex'] is int
        ? item['_storageIndex'] as int
        : null;

    var removed = false;
    final updated = <String>[];

    for (var i = 0; i < rawList.length; i++) {
      final raw = rawList[i];
      var match = false;

      try {
        final decoded = jsonDecode(raw);
        final map = Map<String, dynamic>.from(decoded);
        final rawCreatedAt = map['createdAt']?.toString();
        if (createdAt != null && rawCreatedAt == createdAt) {
          match = true;
        }
      } catch (_) {}

      if (!match &&
          createdAt == null &&
          storageIndex != null &&
          storageIndex == i) {
        match = true;
      }

      if (!removed && match) {
        removed = true;
        continue;
      }

      updated.add(raw);
    }

    await prefs.setStringList("history", updated);
    await loadHistory();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Transaksi dihapus")),
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
                "Total: ${history.length} (${widget.role.label})",
                style: const TextStyle(color: Colors.white70),
              ),
              TextButton.icon(
                onPressed: history.isEmpty || !_canManage ? null : clearAll,
                icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                label: const Text(
                  "Kosongkan",
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: history.isEmpty
                ? const Center(
                    child: Text(
                      "Belum ada history",
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, i) {
                      final item = history[i];

                      final nominal =
                          formatRupiahInt(item['amount'] as int);
                      final category =
                          (item['category'] ?? "Lainnya").toString();
                      final note = item['note']?.toString();
                      final important = item['important'] == true;
                      final createdBy = _roleLabel(
                        item['createdBy'] ?? item['role'],
                      );

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                                      color: important
                                          ? Colors.amber.withValues(alpha: 0.3)
                                          : Colors.white.withValues(alpha: 0.1),
                                    ),
                                  ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: important
                                    ? Colors.amber.withValues(alpha: 0.35)
                                    : Colors.amber.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                important
                                    ? Icons.star_rounded
                                    : Icons.history_rounded,
                                color: Colors.amber,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['name'],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (_canManage)
                                        IconButton(
                                          visualDensity:
                                              VisualDensity.compact,
                                          onPressed: () => _deleteItem(item),
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: Colors.redAccent,
                                          ),
                                          tooltip: "Hapus transaksi",
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      Chip(
                                        label: Text(category),
                                        labelStyle: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        backgroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 0,
                                        ),
                                      ),
                                      Chip(
                                        avatar: const Icon(
                                          Icons.payments_rounded,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                        label: Text(
                                          "Rp $nominal",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        backgroundColor:
                                            Colors.green.withValues(alpha: 0.35),
                                      ),
                                      Chip(
                                        label: Text(createdBy),
                                        labelStyle: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        backgroundColor:
                                            Colors.blueGrey.withValues(alpha: 0.4),
                                      ),
                                      if (important)
                                        Chip(
                                          avatar: const Icon(
                                            Icons.priority_high,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            "Penting",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          backgroundColor: Colors.amber
                                              .withValues(alpha: 0.45),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    "Tanggal: ${item['date']}",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (note != null && note.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.notes_rounded,
                                          color: Colors.white70,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            note,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  ]
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
