import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/food_record.dart';
import 'result_screen.dart';
import 'qr_scanner_screen.dart';

class SearchScanScreen extends StatefulWidget {
  final String baseUrl;

  const SearchScanScreen({super.key, required this.baseUrl});

  @override
  State<SearchScanScreen> createState() => _SearchScanScreenState();
}

class _SearchScanScreenState extends State<SearchScanScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedField = 'MF_Card_No';
  bool _isSearching = false;
  bool _isQrSearching = false;

  Future<void> _searchByQr(String qr) async {
    setState(() => _isQrSearching = true);
    try {
      final res = await http.get(
        Uri.parse('${widget.baseUrl}searchByQrString.php?qr=$qr'),
        headers: {'ngrok-skip-browser-warning': '69420'},
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final raw = jsonDecode(res.body);
        if (raw is Map && raw.isNotEmpty) {
          final data = Map<String, dynamic>.from(raw);
          final record = FoodRecord.fromJson(data);
          await _checkClaimAndOpen(record, fromQr: true);
        } else {
          _showMsg('Record Not Found');
        }
      } else {
        _showMsg('Record Not Found');
      }
    } catch (e) {
      _showMsg('Error: $e');
    } finally {
      setState(() => _isQrSearching = false);
    }
  }

  Future<void> _manualSearch() async {
    final value = _searchController.text.trim();
    if (value.isEmpty) {
      _showMsg('Please enter a value');
      return;
    }

    setState(() => _isSearching = true);

    try {
      final uri = Uri.parse(
          '${widget.baseUrl}search.php?field=$_selectedField&value=$value');
      final res = await http.get(
        uri,
        headers: {'ngrok-skip-browser-warning': '69420'},
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final raw = jsonDecode(res.body);
        // search.php now returns an array of records
        if (raw is List && raw.isNotEmpty) {
          final records = raw
              .map((e) => FoodRecord.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ResultScreen(
                records: records,
                baseUrl: widget.baseUrl,
              ),
            ),
          ).then((_) {
            _searchController.clear();
          });
        } else {
          _showMsg('Record Not Found');
        }
      } else {
        _showMsg('Record Not Found');
      }
    } catch (e) {
      _showMsg('Error: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _checkClaimAndOpen(FoodRecord record,
      {required bool fromQr}) async {
    try {
      final uri = Uri.parse(
          '${widget.baseUrl}checkClaim.php?MF_Card_No=${record.mfCardNo}');
      final res = await http.get(
        uri,
        headers: {'ngrok-skip-browser-warning': '69420'},
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final raw = jsonDecode(res.body);
        final data = raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};
        final success = data['success'] == true;
        final String? claimedAt = data['claimed_at'] as String?;

        if (fromQr && success) _showMsg('Ready to Claim');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              records: [record],
              baseUrl: widget.baseUrl,
              initialClaimed: [!success],
              claimedAtTimes: [claimedAt],
            ),
          ),
        ).then((_) {
          _searchController.clear();
        });
      } else {
        _showMsg('Error checking claim status');
      }
    } catch (e) {
      _showMsg('Error: $e');
    }
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRScannerScreen(
          onScanned: (code) async {
            Navigator.pop(context);
            await _searchByQr(code);
          },
        ),
      ),
    );
  }

  void _showMsg(String msg) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(
              msg.contains('Error') || msg.contains('Not Found')
                  ? Icons.error_outline_rounded
                  : msg.contains('Ready')
                  ? Icons.check_circle_outline_rounded
                  : Icons.info_outline_rounded,
              color: msg.contains('Error') || msg.contains('Not Found')
                  ? Colors.red
                  : msg.contains('Ready')
                  ? Colors.green
                  : Colors.blue,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF667EEA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Search'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : const Color(0xFF2D3748),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDarkMode
                ? [
              const Color(0xFF0F3460).withOpacity(0.3),
              const Color(0xFF1A1A2E),
            ]
                : [
              Colors.grey.shade50,
              Colors.grey.shade100,
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF25294A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF667EEA),
                                  const Color(0xFF764BA2),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.search_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Find Member',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Scan QR code or search manually to find member details',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 15,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // QR Scanner Card
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF25294A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF667EEA).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.qr_code_scanner_rounded,
                              color: const Color(0xFF667EEA),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Quick Scan',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Scan member QR code for instant lookup',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: isSmallScreen ? 52 : 56,
                        child: ElevatedButton(
                          onPressed: _isQrSearching ? null : _openScanner,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667EEA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isQrSearching
                              ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: const AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_scanner_rounded,
                                size: isSmallScreen ? 20 : 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'SCAN QR CODE',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 15 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Manual Search Card
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF25294A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.search_rounded,
                              color: const Color(0xFF10B981),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Manual Search',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Search by document number',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 13 : 14,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Search Field Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF1A1A2E)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedField,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelText: 'Search By',
                            labelStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                          dropdownColor: isDarkMode
                              ? const Color(0xFF25294A)
                              : Colors.white,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
                            fontSize: 15,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'MF_Card_No',
                              child: Text('Card Number'),
                            ),
                            DropdownMenuItem(
                              value: 'Ration_Card_number',
                              child: Text('Ration Card Number'),
                            ),
                            DropdownMenuItem(
                              value: 'Aadhar_Card_number',
                              child: Text('Aadhar Card Number'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _selectedField = v);
                              _searchController.clear();
                            }
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Search Input Field
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF1A1A2E)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _searchController,
                            style: TextStyle(
                              fontSize: 15,
                              color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              labelText: 'Enter Search Value',
                              labelStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                              hintText: 'Enter the document number...',
                              hintStyle: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade400,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: isDarkMode
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade500,
                                ),
                                onPressed: () => _searchController.clear(),
                              ),
                            ),
                            onSubmitted: (_) => _manualSearch(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Search Button
                      SizedBox(
                        width: double.infinity,
                        height: isSmallScreen ? 52 : 56,
                        child: ElevatedButton(
                          onPressed: _isSearching ? null : _manualSearch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _isSearching
                              ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                              const AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: isSmallScreen ? 20 : 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'SEARCH RECORD',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 15 : 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Help Text
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? const Color(0xFF1A1A2E).withOpacity(0.5)
                              : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode
                                ? const Color(0xFF4299E1).withOpacity(0.3)
                                : const Color(0xFF4299E1).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: isDarkMode
                                  ? const Color(0xFF4299E1)
                                  : const Color(0xFF4299E1),
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ensure document numbers are entered accurately for best results',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 13,
                                  color: isDarkMode
                                      ? Colors.grey.shade400
                                      : const Color(0xFF4299E1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom padding for safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}