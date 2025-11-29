import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_role.dart';
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

  List<int> get _recentAmounts => _history
      .take(7)
      .map((item) => (item['amount'] ?? 0) as int)
      .where((value) => value >= 0)
      .toList();

  Future<void> _openTambahTransaksi() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TambahTransaksiPage(role: UserRole.user),
      ),
    );

    if (result == true) {
      _loadHistory();
    }
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HistoryPage(role: UserRole.user),
      ),
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
        child: Stack(
          children: [
            const _BrandBackdrop(),
            SafeArea(
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
                    _MomentumPanel(
                      surface: surface,
                      accent: accent,
                      amounts: _recentAmounts,
                      onAdd: _openTambahTransaksi,
                      onHistory: _openHistory,
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
          ],
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
      height: 200,
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D2B64), Color(0xFF1B2240)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
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
                color: Colors.white.withValues(alpha: 0.04),
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
                color: accent.withValues(alpha: 0.08),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ringkasan Hari Ini",
                    style: GoogleFonts.poppins(
                      color: Colors.white.withValues(alpha: 0.9),
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
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
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
                ],
              ),
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
          color: surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
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
        color: surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
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

class _MomentumPanel extends StatelessWidget {
  final Color surface;
  final Color accent;
  final List<int> amounts;
  final VoidCallback onAdd;
  final VoidCallback onHistory;

  const _MomentumPanel({
    required this.surface,
    required this.accent,
    required this.amounts,
    required this.onAdd,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = amounts.isNotEmpty;
    final total = amounts.fold<int>(0, (sum, value) => sum + value);
    final avg = hasData ? (total / amounts.length).round() : 0;
    final best = hasData ? amounts.reduce(max) : 0;
    final momentum = hasData && amounts.length > 1
        ? ((amounts.first - amounts.last) / max(amounts.last, 1)) * 100
        : 0.0;
    final trendingUp = momentum >= 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2A55), Color(0xFF111A33)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 16),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Momentum",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasData
                        ? "7 transaksi terakhir, real time"
                        : "Belum ada data, ayo isi satu transaksi",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: hasData ? onHistory : onAdd,
                icon: Icon(
                  hasData ? Icons.auto_graph_rounded : Icons.bolt_rounded,
                  color: Colors.white,
                ),
                tooltip: hasData ? "Buka history" : "Tambah transaksi",
              )
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  color: surface.withValues(alpha: 0.45),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                ),
                child: hasData
                    ? _Sparkline(amounts: amounts, accent: accent)
                    : Center(
                        child: ElevatedButton.icon(
                          onPressed: onAdd,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text("Tambah transaksi pertama"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.black,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            tween: Tween(begin: 0, end: 1),
            builder: (context, value, _) {
              final displayMomentum = (momentum * value).roundToDouble();
              return Row(
                children: [
                  Icon(
                    trendingUp ? Icons.trending_up : Icons.trending_down,
                    color: trendingUp ? Colors.greenAccent : Colors.orangeAccent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${trendingUp ? 'Laju naik' : 'Laju turun'} ${displayMomentum.abs().toStringAsFixed(0)}%",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MetricChip(
                label: "Total 7 terakhir",
                value: "Rp ${formatRupiahInt(total)}",
                color: accent,
              ),
              const SizedBox(width: 8),
              _MetricChip(
                label: "Rata-rata",
                value: "Rp ${formatRupiahInt(avg)}",
                color: Colors.cyanAccent,
              ),
              const SizedBox(width: 8),
              _MetricChip(
                label: "Puncak",
                value: "Rp ${formatRupiahInt(best)}",
                color: Colors.amberAccent,
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<int> amounts;
  final Color accent;

  const _Sparkline({required this.amounts, required this.accent});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(amounts, accent),
      child: const SizedBox.expand(),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<int> amounts;
  final Color accent;

  _SparklinePainter(this.amounts, this.accent);

  @override
  void paint(Canvas canvas, Size size) {
    if (amounts.isEmpty) return;

    final maxValue = amounts.reduce(max).toDouble();
    final minValue = amounts.reduce(min).toDouble();
    final range = max(maxValue - minValue, 1);
    final singlePoint = amounts.length == 1;
    final step = singlePoint ? 0.0 : size.width / (amounts.length - 1);

    final path = Path();
    final fillPath = Path();
    final points = <Offset>[];

    for (var i = 0; i < amounts.length; i++) {
      final x = singlePoint ? size.width / 2 : step * i.toDouble();
      final normalized = (amounts[i] - minValue) / range;
      final y = size.height - (normalized * size.height);
      points.add(Offset(x, y));
    }

    for (var i = 0; i < points.length; i++) {
      if (i == 0) {
        path.moveTo(points[i].dx, points[i].dy);
        fillPath.moveTo(points[i].dx, size.height);
        fillPath.lineTo(points[i].dx, points[i].dy);
      } else {
        path.lineTo(points[i].dx, points[i].dy);
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
    }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final paintFill = Paint()
      ..shader = LinearGradient(
        colors: [accent.withValues(alpha: 0.3), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, paintFill);

    final paintLine = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, paintLine);

    final glowPaint = Paint()
      ..color = accent.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(points.last, 6, glowPaint);
    canvas.drawCircle(points.last, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.amounts != amounts || oldDelegate.accent != accent;
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandBackdrop extends StatelessWidget {
  const _BrandBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _BrandBackdropPainter(),
        size: Size.infinite,
      ),
    );
  }
}

class _BrandBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF0B1023).withValues(alpha: 0.0),
          const Color(0xFF1E2A55).withValues(alpha: 0.12),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawRect(rect, bgPaint);

    final glowShader = RadialGradient(
      colors: [
        const Color(0xFF6BD1FF).withValues(alpha: 0.12),
        Colors.transparent,
      ],
      stops: const [0.0, 1.0],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.25, size.height * 0.35),
      radius: size.width * 0.45,
    ));
    canvas.drawRect(rect, Paint()..shader = glowShader);

    final glowShader2 = RadialGradient(
      colors: [
        Colors.purpleAccent.withValues(alpha: 0.09),
        Colors.transparent,
      ],
      stops: const [0.0, 1.0],
    ).createShader(Rect.fromCircle(
      center: Offset(size.width * 0.85, size.height * 0.55),
      radius: size.width * 0.5,
    ));
    canvas.drawRect(rect, Paint()..shader = glowShader2);

    final textPainter = TextPainter(
      text: TextSpan(
        text: "Aldi Yonatan",
        style: GoogleFonts.montserrat(
          fontSize: size.width * 0.12,
          fontWeight: FontWeight.w800,
          letterSpacing: 2,
          foreground: Paint()
            ..shader = LinearGradient(
              colors: [
                const Color(0xFF6BD1FF).withValues(alpha: 0.22),
                Colors.white.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(rect),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.9);

    final textOffset = Offset(
      (size.width - textPainter.width) / 2,
      (size.height - textPainter.height) / 2,
    );

    canvas.save();
    canvas.translate(0, -30);
    canvas.skew(-0.08, 0);
    textPainter.paint(canvas, textOffset);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
              color: surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
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
              final category = item['category']?.toString();
              final important = item['important'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surface.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
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
                        Row(
                          children: [
                            if (category != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  category,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            if (important) ...[
                              if (category != null) const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.black87,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Penting",
                                      style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
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
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
