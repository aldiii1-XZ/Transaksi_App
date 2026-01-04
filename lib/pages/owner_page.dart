import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_role.dart';
import '../utils/format.dart';
import 'history_page.dart';

class OwnerPage extends StatefulWidget {
  const OwnerPage({super.key});

  @override
  State<OwnerPage> createState() => _OwnerPageState();
}

class _OwnerPageState extends State<OwnerPage> {
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList("history") ?? [];

    final temp = <Map<String, dynamic>>[];
    for (final item in rawList) {
      try {
        final decoded = Map<String, dynamic>.from(jsonDecode(item));
        decoded['amount'] = _parseAmount(decoded['amount']);
        temp.add(decoded);
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      _history = temp.reversed.toList();
      _loading = false;
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

  int get _totalAmount =>
      _history.fold(0, (sum, item) => sum + ((item['amount'] ?? 0) as int));

  int get _importantCount =>
      _history.where((item) => item['important'] == true).length;

  Map<String, dynamic>? get _latest => _history.isEmpty ? null : _history.first;

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HistoryPage(role: UserRole.owner),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latest = _latest;
    const textPrimary = Color(0xFF1F2933);
    const textSecondary = Color(0xFF52616B);
    const surface = Color(0xFFF6F8FB);
    const accent = Color(0xFF2ECC71);

    return Scaffold(
      appBar: AppBar(title: const Text('Menu Owner')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Ringkasan Owner",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    _SummaryCard(
                      total: formatRupiahInt(_totalAmount),
                      totalTransactions: _history.length,
                      importantCount: _importantCount,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      surface: surface,
                    ),
                    const SizedBox(height: 16),
                    if (latest != null)
                      _LatestCard(
                        title: latest['name']?.toString() ?? "-",
                        date: latest['date']?.toString() ?? "-",
                        amount: formatRupiahInt(
                          (latest['amount'] ?? 0) as int,
                        ),
                        category: latest['category']?.toString() ?? "Lainnya",
                        createdBy:
                            userRoleFromString(latest['createdBy']).label,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        surface: surface,
                        accent: accent,
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          "Belum ada transaksi. Owner hanya membaca data.",
                          style: TextStyle(color: textSecondary),
                        ),
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _loadHistory,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text("Segarkan"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openHistory,
                            icon: const Icon(Icons.history_rounded),
                            label: const Text("Lihat History"),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String total;
  final int totalTransactions;
  final int importantCount;
  final Color textPrimary;
  final Color textSecondary;
  final Color surface;

  const _SummaryCard({
    required this.total,
    required this.totalTransactions,
    required this.importantCount,
    required this.textPrimary,
    required this.textSecondary,
    required this.surface,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Total Nominal",
            style: TextStyle(color: textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            "Rp $total",
            style: TextStyle(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _stat(
                  label: "Transaksi",
                  value: totalTransactions.toString(),
                ),
              ),
              Expanded(
                child: _stat(
                  label: "Ditandai penting",
                  value: importantCount.toString(),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _stat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        )
      ],
    );
  }
}

class _LatestCard extends StatelessWidget {
  final String title;
  final String date;
  final String amount;
  final String category;
  final String createdBy;
  final Color textPrimary;
  final Color textSecondary;
  final Color surface;
  final Color accent;

  const _LatestCard({
    required this.title,
    required this.date,
    required this.amount,
    required this.category,
    required this.createdBy,
    required this.textPrimary,
    required this.textSecondary,
    required this.surface,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Transaksi Terbaru",
            style: TextStyle(color: textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Chip(
                label: Text("Rp $amount"),
                backgroundColor: accent.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Chip(
                label: Text(category),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Chip(
                label: Text(createdBy),
                backgroundColor: Colors.grey.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            date,
            style: TextStyle(color: textSecondary),
          )
        ],
      ),
    );
  }
}
