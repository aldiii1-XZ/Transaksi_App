import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/format.dart';
import 'tambah_transaksi_page.dart';
import 'history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

    setState(() {
      // newest first
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

  int get _totalAmount => _history.fold(
        0,
        (sum, item) => sum + ((item['amount'] ?? 0) as int),
      );

  int get _totalTransactions => _history.length;

  String get _lastTransactionTitle =>
      _history.isEmpty ? "Belum ada transaksi" : _history.first['name'] as String;

  Future<void> _openTambahTransaksi() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TambahTransaksiPage()),
    );

    if (result == true) {
      _loadHistory();
    }
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HistoryPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFF0B1023);
    const Color surface = Color(0xFF121A32);
    const Color accent = Color(0xFF6BD1FF);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          "Transaksi Harian",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openHistory,
            icon: const Icon(Icons.timeline_rounded, color: Colors.white),
            tooltip: "Lihat history",
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openTambahTransaksi,
        icon: const Icon(Icons.add_rounded),
        label: const Text("Transaksi Baru"),
        backgroundColor: accent,
        foregroundColor: Colors.black,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B1023), Color(0xFF0E1C3A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadHistory,
            color: accent,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                _HeroCard(
                  background: surface,
                  accent: accent,
                  totalAmount: _totalAmount,
                  totalTransactions: _totalTransactions,
                  lastTransaction: _lastTransactionTitle,
                  onAddTap: _openTambahTransaksi,
                ),
                const SizedBox(height: 18),
                _QuickActions(
                  surface: surface,
                  accent: accent,
                  onTambah: _openTambahTransaksi,
                  onHistory: _openHistory,
                ),
                const SizedBox(height: 18),
                _StatsRow(
                  surface: surface,
                  accent: accent,
                  totalAmount: _totalAmount,
                  totalTransactions: _totalTransactions,
                  lastTransaction: _lastTransactionTitle,
                ),
                const SizedBox(height: 18),
                _RecentList(
                  surface: surface,
                  accent: accent,
                  loading: _loading,
                  history: _history,
                  onShowAll: _openHistory,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final Color background;
  final Color accent;
  final int totalAmount;
  final int totalTransactions;
  final String lastTransaction;
  final VoidCallback onAddTap;

  const _HeroCard({
    required this.background,
    required this.accent,
    required this.totalAmount,
    required this.totalTransactions,
    required this.lastTransaction,
    required this.onAddTap,
  });

  @override
  Widget build(BuildContext context) {
    final total = formatRupiahInt(totalAmount);
    return Container(
      padding: const EdgeInsets.all(20),
      height: 180,
      decoration: BoxDecoration(
        color: background.withOpacity(0.65),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D2B64), Color(0xFF1B2240)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withOpacity(0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Ringkasan Hari Ini",
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Rp $total",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _MiniPill(
                    label: "$totalTransactions transaksi",
                    icon: Icons.check_circle_outline,
                    accent: accent,
                  ),
                  const SizedBox(width: 8),
                  _MiniPill(
                    label: lastTransaction,
                    icon: Icons.flash_on_rounded,
                    accent: Colors.white70,
                  ),
                ],
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton.icon(
                  onPressed: onAddTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text("Tambah transaksi"),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final Color surface;
  final Color accent;
  final VoidCallback onTambah;
  final VoidCallback onHistory;

  const _QuickActions({
    required this.surface,
    required this.accent,
    required this.onTambah,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionTile(
            title: "Input cepat",
            subtitle: "Tambah transaksi baru",
            icon: Icons.edit_rounded,
            surface: surface,
            accent: accent,
            onTap: onTambah,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionTile(
            title: "History",
            subtitle: "Lihat catatan lengkap",
            icon: Icons.history_rounded,
            surface: surface,
            accent: Colors.white70,
            onTap: onHistory,
          ),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color surface;
  final Color accent;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.surface,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface.withOpacity(0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final Color surface;
  final Color accent;
  final int totalAmount;
  final int totalTransactions;
  final String lastTransaction;

  const _StatsRow({
    required this.surface,
    required this.accent,
    required this.totalAmount,
    required this.totalTransactions,
    required this.lastTransaction,
  });

  @override
  Widget build(BuildContext context) {
    final avg = totalTransactions == 0
        ? 0
        : (totalAmount / totalTransactions).round();

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: "Total transaksi",
            value: "$totalTransactions",
            icon: Icons.list_alt_rounded,
            surface: surface,
            accent: accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: "Rata-rata",
            value: "Rp ${formatRupiahInt(avg)}",
            icon: Icons.leaderboard_rounded,
            surface: surface,
            accent: Colors.orangeAccent,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color surface;
  final Color accent;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.surface,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  final Color surface;
  final Color accent;
  final bool loading;
  final List<Map<String, dynamic>> history;
  final VoidCallback onShowAll;

  const _RecentList({
    required this.surface,
    required this.accent,
    required this.loading,
    required this.history,
    required this.onShowAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Aktivitas terbaru",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: history.isEmpty ? null : onShowAll,
              child: const Text("Lihat semua"),
            )
          ],
        ),
        const SizedBox(height: 10),
        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        else if (history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: surface.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  child: const Icon(Icons.inbox_rounded, color: Colors.white70),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Belum ada transaksi tersimpan. Yuk mulai catat transaksi pertama!",
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                ),
              ],
            ),
          )
        else
          Column(
            children: history.take(5).map((item) {
              final nominal = formatRupiahInt((item['amount'] ?? 0) as int);
              final date = item['date']?.toString() ?? "";
              final name = item['name']?.toString() ?? "Tanpa nama";
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surface.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.payments_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date,
                            style: GoogleFonts.poppins(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "Rp $nominal",
                      style: GoogleFonts.poppins(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    )
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;

  const _MiniPill({
    required this.label,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: accent,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          )
        ],
      ),
    );
  }
}
