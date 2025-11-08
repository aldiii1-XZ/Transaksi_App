import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const TransaksiApp());
}

class TransaksiApp extends StatelessWidget {
  const TransaksiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transaksi App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginPage(),
    );
  }
}

// ====================== LOGIN PAGE ==========================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  void _login() {
    if (usernameController.text == "owner" &&
        passwordController.text == "12345") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username atau password salah")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Owner")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: const Text("Login")),
          ],
        ),
      ),
    );
  }
}

// ====================== HOME PAGE ==========================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString('transactions');
    if (jsonData != null) {
      transactions = List<Map<String, dynamic>>.from(json.decode(jsonData));
    }
    filteredTransactions = List.from(transactions);
    setState(() {});
  }

  Future<void> _saveTransaction(String name, String amount) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final entry = {'name': name, 'amount': amount, 'date': now};

    transactions.add(entry);
    await prefs.setString('transactions', json.encode(transactions));
    _filterTransactions("Semua");
    setState(() {});
  }

  void _filterTransactions(String filter) {
    if (filter == "Semua") {
      filteredTransactions = List.from(transactions);
    } else if (filter == "Hari ini") {
      final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
      filteredTransactions =
          transactions.where((e) => e['date'] == today).toList();
    } else if (filter == "Nominal > 100000") {
      filteredTransactions = transactions.where((e) {
        final nominal = int.tryParse(e['amount'].replaceAll('.', '')) ?? 0;
        return nominal > 100000;
      }).toList();
    }
    setState(() {});
  }

  String formatNumber(String value) {
    if (value.isEmpty) return "";
    final number = int.tryParse(value.replaceAll('.', ''));
    if (number == null) return "";
    return NumberFormat("#,###", "id_ID")
        .format(number)
        .replaceAll(',', '.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaksi App"),
        actions: [
          PopupMenuButton<String>(
            onSelected: _filterTransactions,
            itemBuilder: (context) => [
              const PopupMenuItem(value: "Semua", child: Text("Semua")),
              const PopupMenuItem(value: "Hari ini", child: Text("Hari ini")),
              const PopupMenuItem(
                  value: "Nominal > 100000",
                  child: Text("Nominal > 100.000")),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Nama Pemberi"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: "Nominal (Rp)"),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final formatted = formatNumber(value);
                amountController.value = TextEditingValue(
                  text: formatted,
                  selection:
                      TextSelection.collapsed(offset: formatted.length),
                );
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    amountController.text.isNotEmpty) {
                  _saveTransaction(nameController.text, amountController.text);
                  nameController.clear();
                  amountController.clear();
                }
              },
              child: const Text("Simpan"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: filteredTransactions.length,
                itemBuilder: (context, index) {
                  final item = filteredTransactions[index];
                  return Card(
                    child: ListTile(
                      title:
                          Text("${item['name']} - Rp ${item['amount']}"),
                      subtitle: Text("Tanggal: ${item['date']}"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
