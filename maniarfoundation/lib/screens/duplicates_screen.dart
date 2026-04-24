import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/food_record.dart';

enum DuplicateType { aadhaar, card_no, ration, name }

class DuplicatesScreen extends StatefulWidget {
  final String baseUrl;
  const DuplicatesScreen({super.key, required this.baseUrl});

  @override
  State<DuplicatesScreen> createState() => _DuplicatesScreenState();
}

class _DuplicatesScreenState extends State<DuplicatesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  List<FoodRecord> _allDuplicates = [];
  List<FoodRecord> _filteredDuplicates = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchDuplicates(DuplicateType.values[0]);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    _searchController.clear();
    _fetchDuplicates(DuplicateType.values[_tabController.index]);
  }

  Future<void> _fetchDuplicates(DuplicateType type) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _allDuplicates = [];
      _filteredDuplicates = [];
    });

    try {
      final typeStr = type.toString().split('.').last;
      final response = await http.get(
        Uri.parse('${widget.baseUrl}getDuplicates.php?type=$typeStr'),
        headers: {'ngrok-skip-browser-warning': '69420'},
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final records = data.map((json) => FoodRecord.fromJson(json)).toList();
        
        setState(() {
          _allDuplicates = records;
          _filteredDuplicates = records;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load duplicates. Server error.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  void _filterResults(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDuplicates = _allDuplicates;
      } else {
        _filteredDuplicates = _allDuplicates.where((r) {
          final q = query.toLowerCase();
          return r.name.toLowerCase().contains(q) ||
                 r.mfCardNo.toLowerCase().contains(q) ||
                 r.aadhar.toLowerCase().contains(q) ||
                 r.rationCard.toLowerCase().contains(q) ||
                 r.qrSrl.toString().contains(q);
        }).toList();
      }
    });
  }

  Future<void> _exportToExcel() async {
    if (_filteredDuplicates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export')),
      );
      return;
    }

    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Duplicates'];

      // Add Headers
      sheetObject.appendRow([
        TextCellValue('Srl No'),
        TextCellValue('Card No'),
        TextCellValue('Full Name'),
        TextCellValue('Aadhaar Card'),
        TextCellValue('Ration Card'),
        TextCellValue('Consensus Status'),
      ]);

      // Add Data
      for (var r in _filteredDuplicates) {
        sheetObject.appendRow([
          IntCellValue(r.qrSrl),
          TextCellValue(r.mfCardNo),
          TextCellValue(r.name),
          TextCellValue(r.aadhar),
          TextCellValue(r.rationCard),
          TextCellValue(r.isConsistent),
        ]);
      }

      var fileBytes = excel.save();
      String typeStr = DuplicateType.values[_tabController.index].toString().split('.').last;
      
      final directory = await getExternalStorageDirectory();
      final path = '${directory!.path}/Duplicates_${typeStr}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      
      File(path)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to $path'),
          action: SnackBarAction(
            label: 'Open/Share',
            onPressed: () => Share.shareXFiles([XFile(path)], text: 'Duplicate Data Export'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text('Duplicate Detection', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : const Color(0xFF2D3748),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF667EEA),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF667EEA),
          tabs: const [
            Tab(text: 'Aadhaar'),
            Tab(text: 'Card No'),
            Tab(text: 'Ration'),
            Tab(text: 'Name'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: _exportToExcel,
            tooltip: 'Export current list to Excel',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterResults,
              decoration: InputDecoration(
                hintText: 'Search within duplicates...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF667EEA)),
                filled: true,
                fillColor: isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ),

          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF667EEA)))
              : _errorMessage != null
                ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                : _filteredDuplicates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 80, color: Colors.green.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          const Text('No duplicates found in this category!', 
                                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredDuplicates.length,
                      itemBuilder: (context, index) {
                        final r = _filteredDuplicates[index];
                        
                        // Logic to detect grouping for visual clarity
                        bool isStartOfGroup = true;
                        if (index > 0) {
                          final prev = _filteredDuplicates[index - 1];
                          final type = DuplicateType.values[_tabController.index];
                          if (type == DuplicateType.aadhaar) {
                            isStartOfGroup = r.aadhar != prev.aadhar;
                          } else if (type == DuplicateType.card_no) {
                            isStartOfGroup = r.mfCardNo != prev.mfCardNo;
                          } else if (type == DuplicateType.ration) {
                            isStartOfGroup = r.rationCard != prev.rationCard;
                          } else if (type == DuplicateType.name) {
                            isStartOfGroup = r.name != prev.name;
                          }
                        }

                        return Column(
                          children: [
                            if (isStartOfGroup && index > 0)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Divider(thickness: 1, height: 1),
                              ),
                            Card(
                              elevation: 0,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                              ),
                              color: isDarkMode ? const Color(0xFF25294A) : Colors.white,
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFF667EEA).withValues(alpha: 0.1),
                                  child: Text(r.qrSrl.toString(), 
                                              style: const TextStyle(color: Color(0xFF667EEA), fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                                title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Card: ${r.mfCardNo} | Ration: ${r.rationCard}'),
                                    Text('Aadhaar: ${r.aadhar}', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                trailing: r.isConsistent.toLowerCase().trim() == 'no'
                                  ? const Icon(Icons.warning_amber_rounded, color: Colors.orange)
                                  : const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
