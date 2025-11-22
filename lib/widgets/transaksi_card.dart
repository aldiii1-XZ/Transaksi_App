import 'package:flutter/material.dart';
import '../models/transaksi_model.dart';
import '../utils/format.dart';

class TransaksiCard extends StatelessWidget {
  final TransaksiModel model;
  const TransaksiCard({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(children: [
        CircleAvatar(
            backgroundColor: const Color(0xFF1089FF),
            child: const Icon(Icons.person, color: Colors.white)),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(model.name,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Tanggal: ${model.date}',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
        ),
        Text('Rp ${formatRupiah(model.amount)}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
