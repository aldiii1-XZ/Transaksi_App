import 'package:flutter/material.dart';

class OwnerPage extends StatelessWidget {
  const OwnerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu Owner')),
      body: const Center(
          child: Text('Halaman Owner — dapat melihat histori transaksi')),
    );
  }
}
