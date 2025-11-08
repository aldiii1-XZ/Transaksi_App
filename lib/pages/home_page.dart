import 'package:flutter/material.dart';
import 'tambah_transaksi_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> _transaksiList = [];

  void _tambahTransaksi(String nama, double nominal) {
    setState(() {
      _transaksiList.add({'nama': nama, 'nominal': nominal});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catatan Transaksi')),
      body: ListView.builder(
        itemCount: _transaksiList.length,
        itemBuilder: (context, index) {
          final item = _transaksiList[index];
          return ListTile(
            leading: const Icon(Icons.person),
            title: Text(item['nama']),
            subtitle: Text('Rp ${item['nominal']}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final hasil = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const TambahTransaksiPage(),
            ),
          );
          if (hasil != null) {
            _tambahTransaksi(hasil['nama'], hasil['nominal']);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
