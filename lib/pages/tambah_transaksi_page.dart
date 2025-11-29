import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_role.dart';
import '../utils/format.dart';

class TambahTransaksiPage extends StatefulWidget {
  final UserRole role;

  const TambahTransaksiPage({
    super.key,
    this.role = UserRole.user,
  });

  @override
  State<TambahTransaksiPage> createState() => _TambahTransaksiPageState();
}

class _TambahTransaksiPageState extends State<TambahTransaksiPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController nominalController = TextEditingController();
  final TextEditingController catatanController = TextEditingController();

  bool isSaving = false;
  bool tandaiPenting = false;
  String kategoriDipilih = "Lainnya";
  DateTime tanggalDipilih = DateTime.now();

  final List<String> _kategoriList = const [
    "Makanan & Minum",
    "Transportasi",
    "Belanja",
    "Tagihan",
    "Hiburan",
    "Lainnya",
  ];

  @override
  void dispose() {
    namaController.dispose();
    nominalController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  Future<void> saveTransaction() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();

    final rawNominal = nominalController.text.replaceAll('.', '');
    final parsedNominal = int.tryParse(rawNominal);

    if (parsedNominal == null || parsedNominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nominal tidak valid")),
      );
      return;
    }

    final confirmed = await _showConfirmation(parsedNominal);
    if (confirmed != true) return;

    setState(() => isSaving = true);

    final newItem = {
      "name": namaController.text.trim(),
      "amount": parsedNominal,
      "date": DateFormat("dd MMM yyyy, HH:mm").format(tanggalDipilih),
      "category": kategoriDipilih,
      "note": catatanController.text.trim().isEmpty
          ? null
          : catatanController.text.trim(),
      "important": tandaiPenting,
      "createdBy": widget.role.name,
      "createdAt": DateTime.now().toIso8601String(),
    };

    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList("history") ?? [];
    existing.add(jsonEncode(newItem));
    await prefs.setStringList("history", existing);

    if (!mounted) return;

    setState(() => isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Transaksi berhasil disimpan")),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Transaksi")),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bottomInset = MediaQuery.of(context).viewInsets.bottom;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          "Detail transaksi",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: namaController,
                          decoration: const InputDecoration(
                            labelText: "Nama Transaksi",
                            border: OutlineInputBorder(),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Nama wajib diisi";
                            }
                            if (value.trim().length < 3) {
                              return "Minimal 3 karakter";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: kategoriDipilih,
                          decoration: const InputDecoration(
                            labelText: "Kategori",
                            border: OutlineInputBorder(),
                          ),
                          items: _kategoriList
                              .map((item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => kategoriDipilih = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: nominalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Nominal",
                            border: OutlineInputBorder(),
                            prefixText: "Rp ",
                          ),
                          onChanged: (value) {
                            final formatted = formatRupiah(value);
                            nominalController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                  offset: formatted.length),
                            );
                          },
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Nominal wajib diisi";
                            }
                            final parsed = int.tryParse(
                                value.replaceAll('.', '').replaceAll(',', ''));
                            if (parsed == null || parsed <= 0) {
                              return "Nominal tidak valid";
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).nextFocus(),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: _pickDateTime,
                          icon: const Icon(Icons.calendar_month_rounded),
                          label: Text(
                            DateFormat("EEEE, dd MMM yyyy - HH:mm", "id")
                                .format(tanggalDipilih),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: catatanController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: "Catatan (opsional)",
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          textInputAction: TextInputAction.newline,
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: tandaiPenting,
                          title: const Text("Tandai sebagai penting"),
                          subtitle: const Text(
                              "Akan muncul dengan highlight pada daftar"),
                          onChanged: (value) {
                            setState(() => tandaiPenting = value);
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isSaving ? null : saveTransaction,
                            icon: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(isSaving ? "Menyimpan..." : "Simpan"),
                            style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: tanggalDipilih,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(tanggalDipilih),
    );

    if (pickedTime == null) return;

    setState(() {
      tanggalDipilih = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<bool?> _showConfirmation(int parsedNominal) {
    final formattedNominal = formatRupiahInt(parsedNominal);
    final note = catatanController.text.trim();

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    "Konfirmasi transaksi",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SummaryRow(label: "Nama", value: namaController.text.trim()),
              _SummaryRow(label: "Kategori", value: kategoriDipilih),
              _SummaryRow(label: "Nominal", value: "Rp $formattedNominal"),
              _SummaryRow(
                label: "Tanggal",
                value:
                    DateFormat("dd MMM yyyy, HH:mm").format(tanggalDipilih),
              ),
              if (note.isNotEmpty)
                _SummaryRow(label: "Catatan", value: note, multiline: true),
              _SummaryRow(
                label: "Prioritas",
                value: tandaiPenting ? "Penting" : "Biasa",
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Perbaiki dulu"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Simpan sekarang"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool multiline;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
