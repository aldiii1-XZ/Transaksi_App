import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/futuristic_page.dart';
import '../utils/format.dart';


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
_load();
}


Future<void> _load() async {
final prefs = await SharedPreferences.getInstance();
final raw = prefs.getStringList('history') ?? [];
final tmp = <Map<String, dynamic>>[];
for (final s in raw) {
try {
final m = jsonDecode(s);
if (m is Map) tmp.add(Map<String, dynamic>.from(m));
} catch (_) {}
}
history = tmp.reversed.toList();
setState(() {});
}


Future<void> _clearAll() async {
final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Hapus semua?'), content: const Text('Hapus seluruh history?'), actions: [TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Batal')), TextButton(onPressed: () => Navigator.pop(_, true), child: const Text('Hapus'))]));
if (ok == true) {
final prefs = await SharedPreferences.getInstance();
await prefs.remove('history');
setState(() => history = []);
}
}


@override
Widget build(BuildContext context) {
return FuturisticPage(
title: 'History Transaksi',
showBack: true,
child: Column(children: [
Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total: ${history.length}', style: const TextStyle(color: Colors.white70)), TextButton.icon(onPressed: history.isEmpty ? null : _clearAll, icon: const Icon(Icons.delete_forever, color: Colors.redAccent), label: const Text('Kosongkan', style: TextStyle(color: Colors.redAccent))) ]),
const SizedBox(height: 12),
Expanded(child: history.isEmpty ? const Center(child: Text('Belum ada history', style: TextStyle(co