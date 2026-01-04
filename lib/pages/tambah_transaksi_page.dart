import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_role.dart';
import '../utils/format.dart';

class TambahTransaksiPage extends StatefulWidget {
  final UserRole role;
  final bool autoScanOnStart;

  const TambahTransaksiPage({
    super.key,
    this.role = UserRole.user,
    this.autoScanOnStart = false,
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
  bool scanningReceipt = false;
  String? scanInfo;
  String? lastScanSummary;
  String? rawScanText;
  List<String> rawScanLines = [];
  String kategoriDipilih = "Lainnya";
  DateTime tanggalDipilih = DateTime.now();
  final ImagePicker _picker = ImagePicker();
  bool _hasAutoScanRun = false;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.autoScanOnStart && !_hasAutoScanRun) {
      _hasAutoScanRun = true;
      Future.microtask(_startScanFlow);
    }
  }

  Future<void> _startScanFlow() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Scan struk belum tersedia di web, gunakan perangkat mobile."),
        ),
      );
      return;
    }

    final source = await _chooseImageSource();
    if (!mounted || source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
      // Pakai resolusi penuh supaya OCR lebih akurat; biar tidak crop
      imageQuality: 100,
    );
    if (picked == null) return;

    setState(() {
      scanningReceipt = true;
      scanInfo = "Memindai teks dari struk...";
      lastScanSummary = null;
      rawScanText = null;
      rawScanLines = [];
    });

    final textRecognizer =
        TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognized = await textRecognizer
          .processImage(InputImage.fromFilePath(picked.path));
      final result = _extractReceiptData(recognized.text);
      _applyReceiptData(result);

      if (!mounted) return;
      setState(() {
        scanInfo = "Periksa kembali hasil baca sebelum disimpan.";
        lastScanSummary = _buildScanSummary(result);
        rawScanText = result.rawText;
        rawScanLines = result.rawLines ?? [];
      });

      final message =
          lastScanSummary ?? "Struk dipindai. Pastikan data sudah sesuai.";
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => scanInfo = "Gagal memindai struk");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal membaca struk: $e")),
      );
    } finally {
      await textRecognizer.close();
      if (mounted) {
        setState(() => scanningReceipt = false);
      }
    }
  }

  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text("Ambil foto struk"),
                subtitle: const Text("Gunakan kamera untuk memindai langsung"),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text("Pilih dari galeri"),
                subtitle: const Text("Gunakan foto struk yang sudah ada"),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  _ReceiptExtraction _extractReceiptData(String text) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final keywordTotals = ['total', 'jumlah', 'bayar', 'tagihan', 'grand'];
    int? biggestTotal;
    int? keywordTotal;

    for (final line in lines) {
      final numbers = _captureNumbers(line);
      if (numbers.isEmpty) continue;

      for (final value in numbers) {
        if (biggestTotal == null || value > biggestTotal) {
          biggestTotal = value;
        }

        final lower = line.toLowerCase();
        if (keywordTotals.any((k) => lower.contains(k))) {
          if (keywordTotal == null || value > keywordTotal) {
            keywordTotal = value;
          }
        }
      }
    }

    final pickedTotal = keywordTotal ?? biggestTotal;
    final pickedDate = _extractDateFromText(text);
    final storeName = _guessStoreName(lines);

    final quickNoteParts = <String>[];
    if (storeName != null) quickNoteParts.add(storeName);
    if (pickedDate != null) {
      quickNoteParts.add(DateFormat("dd MMM yyyy").format(pickedDate));
    }
    if (pickedTotal != null) {
      quickNoteParts.add("Rp ${formatRupiahInt(pickedTotal)}");
    }

    return _ReceiptExtraction(
      total: pickedTotal,
      storeName: storeName,
      date: pickedDate,
      note: quickNoteParts.isEmpty ? null : quickNoteParts.join(" | "),
      preview: lines.take(5).join(' · '),
      rawText: text,
      rawLines: lines,
    );
  }

  List<int> _captureNumbers(String line) {
    final cleaned =
        line.replaceAll(RegExp('rp', caseSensitive: false), '').replaceAll(' ', '');
    final reg = RegExp(r'(\d{1,3}(?:[.,]\d{3})+|\d{4,})');
    final matches = reg.allMatches(cleaned);
    final results = <int>[];

    for (final match in matches) {
      final raw = match.group(0);
      if (raw == null) continue;
      final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
      final value = int.tryParse(digits);
      if (value != null && value > 0) {
        results.add(value);
      }
    }

    return results;
  }

  String? _guessStoreName(List<String> lines) {
    const blockedWords = [
      'total',
      'jumlah',
      'bayar',
      'tagihan',
      'tanggal',
      'jam',
      'cashier',
      'kasir'
    ];

    for (final line in lines.take(5)) {
      final lower = line.toLowerCase();
      if (blockedWords.any((k) => lower.contains(k))) continue;
      if (RegExp(r'\d').hasMatch(line)) continue;
      if (line.length > 30) continue;
      return line;
    }

    if (lines.isNotEmpty) {
      return lines.first.length > 30 ? lines.first.substring(0, 30) : lines.first;
    }
    return null;
  }

  DateTime? _extractDateFromText(String text) {
    final merged = text.replaceAll('\n', ' ');
    final dayMonthYear =
        RegExp(r'(\d{1,2})[\/\-\.\s](\d{1,2})[\/\-\.\s](\d{2,4})');
    final monthNamePattern =
        RegExp(r'(\d{1,2})\s+([A-Za-z]+)\s+(\d{2,4})', caseSensitive: false);

    final matchNumeric = dayMonthYear.firstMatch(merged);
    if (matchNumeric != null) {
      final day = int.tryParse(matchNumeric.group(1) ?? '');
      final month = int.tryParse(matchNumeric.group(2) ?? '');
      final year = int.tryParse(matchNumeric.group(3) ?? '');
      if (day != null && month != null && year != null) {
        return _buildDate(day: day, month: month, year: year);
      }
    }

    final matchMonthName = monthNamePattern.firstMatch(merged);
    if (matchMonthName != null) {
      final day = int.tryParse(matchMonthName.group(1) ?? '');
      final monthName = matchMonthName.group(2)?.toLowerCase();
      final year = int.tryParse(matchMonthName.group(3) ?? '');
      final month = _monthFromName(monthName);
      if (day != null && year != null && month != null) {
        return _buildDate(day: day, month: month, year: year);
      }
    }

    return null;
  }

  DateTime? _buildDate({
    required int day,
    required int month,
    required int year,
  }) {
    final normalizedYear = year < 100 ? 2000 + year : year;
    try {
      return DateTime(
        normalizedYear,
        month,
        day,
        tanggalDipilih.hour,
        tanggalDipilih.minute,
      );
    } catch (_) {
      return null;
    }
  }

  int? _monthFromName(String? raw) {
    if (raw == null) return null;
    const months = {
      'january': 1,
      'jan': 1,
      'januari': 1,
      'february': 2,
      'feb': 2,
      'februari': 2,
      'march': 3,
      'mar': 3,
      'maret': 3,
      'april': 4,
      'apr': 4,
      'may': 5,
      'mei': 5,
      'june': 6,
      'jun': 6,
      'juli': 7,
      'july': 7,
      'jul': 7,
      'august': 8,
      'aug': 8,
      'agustus': 8,
      'september': 9,
      'sept': 9,
      'sep': 9,
      'october': 10,
      'oktober': 10,
      'oct': 10,
      'okt': 10,
      'november': 11,
      'nov': 11,
      'december': 12,
      'desember': 12,
      'dec': 12,
      'des': 12,
    };
    return months[raw.toLowerCase()];
  }

  String? _buildScanSummary(_ReceiptExtraction data) {
    final parts = <String>[];
    if (data.total != null) {
      parts.add("Total Rp ${formatRupiahInt(data.total!)}");
    }
    if (data.date != null) {
      parts.add(DateFormat("dd MMM yyyy").format(data.date!));
    }
    if (data.storeName != null) {
      parts.add(data.storeName!);
    }

    if (parts.isEmpty) {
      return "Tidak ada data otomatis, lengkapi manual.";
    }

    return parts.join(" · ");
  }

  void _applyReceiptData(_ReceiptExtraction data) {
    setState(() {
      if (data.total != null) {
        final formatted = formatRupiahInt(data.total!);
        nominalController.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
        kategoriDipilih = "Belanja";
      }

      if (data.storeName != null && namaController.text.trim().isEmpty) {
        namaController.text = data.storeName!;
      }

      if (data.date != null) {
        tanggalDipilih = data.date!;
      }

      if (data.note != null && catatanController.text.trim().isEmpty) {
        catatanController.text = data.note!;
      }

      rawScanText = data.rawText ?? rawScanText;
      rawScanLines = data.rawLines ?? rawScanLines;
    });
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
      "receiptText": rawScanText,
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.receipt_long_rounded,
                                      color: Colors.lightBlueAccent),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Scan struk otomatis",
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w700),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Foto atau pilih gambar struk untuk mengisi nama, nominal, dan tanggal secara otomatis.",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed:
                                        scanningReceipt ? null : _startScanFlow,
                                    icon: const Icon(Icons.camera_alt_rounded),
                                    label: Text(
                                        scanningReceipt ? "Memindai..." : "Scan Struk"),
                                  ),
                                  const SizedBox(width: 12),
                                  if (scanningReceipt)
                                    const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  else if (lastScanSummary != null)
                                    Expanded(
                                      child: Text(
                                        lastScanSummary!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                              ),
                              if (scanInfo != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  scanInfo!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ],
                              if (rawScanLines.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Teks struk penuh",
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        if (rawScanText != null) {
                                          Clipboard.setData(
                                              ClipboardData(text: rawScanText!));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(const SnackBar(
                                            content: Text("Teks struk disalin"),
                                          ));
                                        }
                                      },
                                      icon: const Icon(Icons.copy, size: 16),
                                      label: const Text("Salin"),
                                    ),
                                  ],
                                ),
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 240),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white12),
                                  ),
                                  child: Scrollbar(
                                    thumbVisibility: true,
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: rawScanLines.length,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Text(
                                            rawScanLines[index],
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
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

class _ReceiptExtraction {
  final int? total;
  final String? storeName;
  final DateTime? date;
  final String? note;
  final String? preview;
  final String? rawText;
  final List<String>? rawLines;

  const _ReceiptExtraction({
    this.total,
    this.storeName,
    this.date,
    this.note,
    this.preview,
    this.rawText,
    this.rawLines,
  });
}
