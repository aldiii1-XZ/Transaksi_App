import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// ===========================================================
//                        MAIN APP
// ===========================================================
void main() {
  runApp(const TransaksiApp());
}

class TransaksiApp extends StatelessWidget {
  const TransaksiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const RoleSelectPage(),
    );
  }
}

// =================================================================
//                        FUTURISTIC UI WRAPPER
// =================================================================
class FuturisticPage extends StatelessWidget {
  final String title;
  final Widget child;

  const FuturisticPage({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F0C29),
                  Color(0xFF302B63),
                  Color(0xFF24243E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          )
        ],
      ),
    );
  }
}

// =================================================================
//                      ROLE SELECT PAGE
// =================================================================
class RoleSelectPage extends StatelessWidget {
  const RoleSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FuturisticPage(
      title: "Pilih Role",
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _glassButton(
            label: "Login Owner",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginOwner()),
            ),
          ),
          const SizedBox(height: 20),
          _glassButton(
            label: "Masuk sebagai User",
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const HomePage(isOwner: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =================================================================
//                          GLASS BUTTON
// =================================================================
Widget _glassButton({
  required String label,
  required Function() onTap,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    ),
  );
}

// =================================================================
//                          LOGIN OWNER
// =================================================================
class LoginOwner extends StatefulWidget {
  const LoginOwner({super.key});

  @override
  State<LoginOwner> createState() => _LoginOwnerState();
}

class _LoginOwnerState extends State<LoginOwner> {
  final username = TextEditingController();
  final password = TextEditingController();
  bool show = false;

  void login() {
    if (username.text == "owner" && password.text == "12345") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage(isOwner: true)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Username/Password salah")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FuturisticPage(
      title: "Login Owner",
      child: Column(
        children: [
          TextField(
            controller: username,
            decoration: const InputDecoration(labelText: "Username"),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: password,
            obscureText: !show,
            decoration: InputDecoration(
              labelText: "Password",
              suffixIcon: IconButton(
                icon: Icon(show ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => show = !show),
              ),
            ),
          ),
          const SizedBox(height: 30),
          _glassButton(label: "Login", onTap: login),
        ],
      ),
    );
  }
}

// =================================================================
//                           HOME PAGE
// =================================================================
class HomePage extends StatefulWidget {
  final bool isOwner;
  const HomePage({super.key, required this.isOwner});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final nama = TextEditingController();
  final nominal = TextEditingController();
  List<Map<String, dynamic>> transaksi = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("transaksi");

    if (data != null) {
      transaksi = List<Map<String, dynamic>>.from(jsonDecode(data));
    }

    setState(() {});
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("transaksi", jsonEncode(transaksi));
  }

  Future<void> saveHistory(Map<String, dynamic> item) async {
    if (!widget.isOwner) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList("history") ?? [];

    history.add(jsonEncode(item));
    await prefs.setStringList("history", history);
  }

  @override
  Widget build(BuildContext context) {
    return FuturisticPage(
      title: widget.isOwner ? "Dashboard Owner" : "Dashboard User",
      child: Column(
        children: [
          TextField(
            controller: nama,
            decoration: const InputDecoration(labelText: "Nama Pemberi"),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: nominal,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Nominal (Rp)"),
          ),
          const SizedBox(height: 20),
          _glassButton(
            label: "Simpan",
            onTap: () {
              if (nama.text.isEmpty || nominal.text.isEmpty) return;

              final now = DateFormat("dd/MM/yyyy").format(DateTime.now());

              final item = {
                "name": nama.text,
                "amount": nominal.text,
                "date": now
              };

              transaksi.add(item);

              saveData();
              saveHistory(item);

              nama.clear();
              nominal.clear();

              setState(() {});
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: transaksi.length,
              itemBuilder: (context, i) {
                final item = transaksi[i];
                return _glassTile(
                  "${item['name']} - Rp ${item['amount']}",
                  "Tanggal: ${item['date']}",
                );
              },
            ),
          ),
          if (widget.isOwner)
            _glassButton(
              label: "Lihat History",
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _glassTile(String title, String subtitle) {
  return Container(
    padding: const EdgeInsets.all(18),
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.12),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.white.withOpacity(0.25)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 18)),
          Text(subtitle, style: const TextStyle(fontSize: 14)),
        ]),
      ],
    ),
  );
}

// =================================================================
//                           HISTORY PAGE
// =================================================================
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
    load();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList("history") ?? [];

    history = raw.map((e) => Map<String, dynamic>.from(jsonDecode(e))).toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FuturisticPage(
      title: "History Transaksi",
      child: ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, i) {
          final item = history[i];

          return _glassTile(
            "${item['name']} - Rp ${item['amount']}",
            "Tanggal: ${item['date']}",
          );
        },
      ),
    );
  }
}
