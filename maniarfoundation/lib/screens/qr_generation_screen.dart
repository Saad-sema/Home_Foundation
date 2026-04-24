import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/food_record.dart';

enum QrMode { single, all }

class QrGenerationScreen extends StatefulWidget {
  final String baseUrl;
  final QrMode mode;

  const QrGenerationScreen({
    super.key,
    required this.baseUrl,
    required this.mode,
  });

  @override
  State<QrGenerationScreen> createState() => _QrGenerationScreenState();
}

class _QrGenerationScreenState extends State<QrGenerationScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _cardCtrl = TextEditingController();
  late AnimationController _animCtrl;

  // Single mode
  bool _searching = false;
  FoodRecord? _singleRecord;
  String? _errorMsg;
  final GlobalKey _singleKey = GlobalKey();

  // All mode
  bool _loadingAll = false;
  List<FoodRecord> _allRecords = [];
  final Map<int, GlobalKey> _cardKeys = {};


  // ALL mode features
  String _searchQuery = "";
  final Set<int> _selectedIndices = {};

  List<FoodRecord> get _filteredRecords {
    return _allRecords.where((r) {
      final matchesSearch = r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            r.mfCardNo.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    if (widget.mode == QrMode.all) {
      _fetchAllMembers();
    } else {
      _animCtrl.forward();
    }
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  // ─────────────────── Capture widget as PNG bytes ─────────────────────────
  Future<Uint8List?> _captureWidget(GlobalKey key) async {
    try {
      final RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print('Capture Error: $e');
      return null;
    }
  }

  // ───────────────────── Consolidated Download ──────────────────────────────
  Future<void> _downloadConsolidated() async {
    if (_selectedIndices.isEmpty) {
      _showSnack('Please select at least one card to download', isError: true);
      return;
    }

    _showSnack('Generating PDF for ${_selectedIndices.length} cards...', isError: false);

    try {
      final pdf = pw.Document();
      // Load the new branding logos
      final maniarLogoData = await rootBundle.load('assets/maniar_logo.png');
      final pwManiarLogo = pw.MemoryImage(maniarLogoData.buffer.asUint8List());
      final careLogoData = await rootBundle.load('assets/care_home_logo.png');
      final pwCareLogo = pw.MemoryImage(careLogoData.buffer.asUint8List());

      final sortedSelected = _selectedIndices.toList()..sort();
      for (final index in sortedSelected) {
        final r = _allRecords[index];
        _addCardToPdf(pdf, r, pwManiarLogo, pwCareLogo);
      }

      final bytes = await pdf.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'MF_Cards_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      _showSnack('Consolidated PDF generated (${_selectedIndices.length} cards)');
    } catch (e) {
      _showSnack('PDF Generation failed: $e', isError: true);
    }
  }

  // ─────────────────── PDF card builder (matches UI exactly) ───────────────
  void _addCardToPdf(pw.Document pdf, FoodRecord r, pw.MemoryImage logo, pw.MemoryImage careLogo) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(60),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Container(
              width: 320,
              padding: const pw.EdgeInsets.all(28),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [

                  // ── Header: two columns separated by a vertical line ──
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [

                      // Left: MANIAR FOUNDATION + Reg ID
                      pw.Expanded(
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Image(logo, height: 60, fit: pw.BoxFit.contain),
                            pw.SizedBox(height: 10),
                            pw.Text(
                              'MANIAR FOUNDATION',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 13,
                                color: PdfColor.fromInt(0xFF1E293B),
                              ),
                            ),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              'Reg ID: 3007',
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                fontSize: 11,
                                color: PdfColor.fromInt(0xFF667EEA),
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Center: Vertical separator (fixed height)
                      pw.Container(
                        width: 1,
                        height: 80,
                        color: PdfColors.grey300,
                        margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                      ),

                      // Right: Logo + HOME FOUNDATION + Reg ID
                        pw.Expanded(
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Image(careLogo, height: 60, fit: pw.BoxFit.contain),
                              pw.SizedBox(height: 10),
                              pw.Text(
                                'HOME FOUNDATION',
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 13,
                                  color: PdfColor.fromInt(0xFF1E293B),
                                ),
                              ),
                              pw.SizedBox(height: 6),
                              pw.Text(
                                'Reg ID: 3134',
                                style: pw.TextStyle(fontSize: 11, color: PdfColor.fromInt(0xFF667EEA), fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // Horizontal divider
                  pw.SizedBox(height: 14),
                  pw.Divider(thickness: 0.8, color: PdfColors.grey300),
                  pw.SizedBox(height: 14),

                  // QR Code
                  pw.Container(
                    width: 180, height: 180,
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: r.qrString,
                    ),
                  ),

                  pw.SizedBox(height: 24),

                  // Card No directly above Red Name
                  pw.Text(
                    'Card No: ${r.mfCardNo}',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 20, color: PdfColor.fromInt(0xFF667EEA), fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    r.name.toUpperCase(),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.red),
                  ),

                  pw.SizedBox(height: 24),
                  pw.Text(
                    'IDENTITY CARD',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey, letterSpacing: 3),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveAsPdf(FoodRecord r) async {
    final pdf = pw.Document();
    final logoData = await rootBundle.load('assets/maniar_logo.png');
    final pwLogo = pw.MemoryImage(logoData.buffer.asUint8List());
    final careLogoData = await rootBundle.load('assets/care_home_logo.png');
    final pwCareLogo = pw.MemoryImage(careLogoData.buffer.asUint8List());
    _addCardToPdf(pdf, r, pwLogo, pwCareLogo);
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'ID_${r.mfCardNo}.pdf');
  }

  // ─────────────────────── Fetch single record ─────────────────────────────
  Future<void> _searchByCard() async {
    final cardNo = _cardCtrl.text.trim();
    if (cardNo.isEmpty) {
      setState(() => _errorMsg = 'Please enter a card number');
      return;
    }
    setState(() {
      _searching = true;
      _errorMsg = null;
      _singleRecord = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${widget.baseUrl}search.php?field=MF_Card_No&value=$cardNo'),
        headers: {'ngrok-skip-browser-warning': '69420'},
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final raw = jsonDecode(res.body);
        if (raw is List && raw.isNotEmpty) {
          final rec = FoodRecord.fromJson(Map<String, dynamic>.from(raw[0] as Map));
          if (rec.isConsistent.toLowerCase().trim() == 'no') {
            setState(() => _errorMsg = 'This member is marked as inconsistent and card cannot be generated.');
          } else if (rec.qrString.isEmpty) {
            setState(() => _errorMsg = 'QR string not found for this member.');
          } else {
            setState(() {
              _singleRecord = rec;
              _errorMsg = null;
            });
          }
        } else {
          setState(() => _errorMsg = 'Member not found for "$cardNo"');
        }
      } else {
        setState(() => _errorMsg = 'Server connection failed');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Error: $e');
    } finally {
      setState(() => _searching = false);
    }
  }

  // ─────────────────────── Fetch all records ────────────────────────────────
  Future<void> _fetchAllMembers() async {
    setState(() {
      _loadingAll = true;
      _errorMsg = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${widget.baseUrl}getAllMembersQr.php'),
        headers: {'ngrok-skip-browser-warning': '69420'},
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final raw = jsonDecode(res.body);
        if (raw is List) {
          final records = raw
              .map((e) => FoodRecord.fromJson(Map<String, dynamic>.from(e as Map)))
              .where((r) => r.qrString.isNotEmpty)
              .where((r) => r.isConsistent.toLowerCase().trim() != 'no')
              .toList();

          setState(() {
            _allRecords = records;
            _cardKeys.clear();
            for (int i = 0; i < records.length; i++) {
              _cardKeys[i] = GlobalKey();
            }
          });
          _animCtrl.forward();
        }
      } else {
        setState(() => _errorMsg = 'Failed to load members');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Error: $e');
    } finally {
      setState(() => _loadingAll = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF667EEA),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(20),
    ));
  }

  // ──────────────────────────────── BUILD ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.mode == QrMode.single ? 'Identity Generator' : 'Bulk Generation',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : const Color(0xFF2D3748),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: widget.mode == QrMode.all && _allRecords.isNotEmpty
            ? [
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF667EEA)),
                  onPressed: _downloadConsolidated,
                  tooltip: 'Download Selected (Single PDF)',
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: SafeArea(
        child: widget.mode == QrMode.single
            ? _buildSingleMode(isDarkMode)
            : _buildAllMode(isDarkMode),
      ),
    );
  }

  // ────────────────────────── SINGLE MODE ───────────────────────────────────
  Widget _buildSingleMode(bool isDarkMode) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _cardCtrl,
                  decoration: InputDecoration(
                    hintText: 'Enter MF Card No...',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onSubmitted: (_) => _searchByCard(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _searching ? null : _searchByCard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _searching
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('GENERATE CARD'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          if (_singleRecord != null) ...[
            RepaintBoundary(
              key: _singleKey,
              child: _buildIdCard(_singleRecord!),
            ),
            const SizedBox(height: 24),
            IconButton(
              onPressed: () => _saveAsPdf(_singleRecord!),
              icon: const Icon(Icons.download_for_offline_rounded, size: 60, color: Color(0xFF667EEA)),
            ),
          ],
        ],
      ),
    );
  }

  // ──────────────────────────── ALL MODE ───────────────────────────────────
  Widget _buildAllMode(bool isDarkMode) {
    if (_loadingAll) return const Center(child: CircularProgressIndicator());

    final filtered = _filteredRecords;
    final selectedCount = _selectedIndices.length;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by Name or Card No...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$selectedCount selected',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: selectedCount > 0 ? const Color(0xFF667EEA) : Colors.grey)),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            for (int i = 0; i < _allRecords.length; i++) {
                              _selectedIndices.add(i);
                            }
                          });
                        },
                        icon: const Icon(Icons.select_all, size: 18),
                        label: const Text('Select All', style: TextStyle(fontSize: 12)),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _selectedIndices.clear()),
                        icon: const Icon(Icons.deselect, size: 18),
                        label: const Text('Clear', style: TextStyle(fontSize: 12)),
                        style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final r = filtered[index];
              final originalIndex = _allRecords.indexOf(r);
              final isSelected = _selectedIndices.contains(originalIndex);

              return Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('CARD #${originalIndex + 1}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Individual download — downloads THIS specific card only
                            IconButton(
                              icon: const Icon(Icons.download_rounded,
                                  color: Color(0xFF10B981), size: 22),
                              tooltip: 'Download this card',
                              onPressed: () => _saveAsPdf(r),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            Checkbox(
                              value: isSelected,
                              activeColor: const Color(0xFF667EEA),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedIndices.add(originalIndex);
                                  } else {
                                    _selectedIndices.remove(originalIndex);
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    RepaintBoundary(
                      key: _cardKeys[originalIndex],
                      child: _buildIdCard(r),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────── VERTICAL ID CARD ────────────────────────────────
  Widget _buildIdCard(FoodRecord r) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.grey.shade200, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header: Text (left) | Separator | Logo (right) ──
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Maniar Foundation — centered
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/maniar_logo.png', height: 70, fit: BoxFit.contain),
                      const SizedBox(height: 10),
                      const Text(
                        'MANIAR FOUNDATION',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                          fontSize: 13,
                          letterSpacing: 0.5,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Reg ID: 3007',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF667EEA),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Center: Vertical gray separator (low opacity)
                Container(
                  width: 1.2,
                  height: double.infinity,
                  color: Colors.grey.withOpacity(0.25),
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),

                // Right: Logo → CARE HOME FOUNDATION → Reg ID — all centered
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset('assets/care_home_logo.png', height: 70, fit: BoxFit.contain),
                      const SizedBox(height: 10),
                      const Text(
                        'HOME FOUNDATION',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                          fontSize: 13,
                          letterSpacing: 0.5,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Reg ID: 3134',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF667EEA),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Horizontal divider below header
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(thickness: 1.2, height: 1, color: Color(0xFFE8ECF0)),
          ),

          // QR Code
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: QrImageView(
              data: r.qrString,
              version: QrVersions.auto,
              size: 160,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
              dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square, color: Colors.black),
            ),
          ),

          const SizedBox(height: 24),
          Text('Card No: ${r.mfCardNo}',
              style: const TextStyle(
                  fontSize: 20, color: Color(0xFF667EEA), fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(r.name.toUpperCase(),
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.red)),

          const SizedBox(height: 20),
          const Text('IDENTITY CARD',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 3)),
        ],
      ),
    );
  }
}
