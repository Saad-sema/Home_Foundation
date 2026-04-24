import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum ListMode { claimed, remaining }

class MembersListScreen extends StatefulWidget {
  final String baseUrl;
  final ListMode mode;

  const MembersListScreen({
    super.key,
    required this.baseUrl,
    required this.mode,
  });

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  bool _isLoading = true;
  String? _errorMsg;
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filtered = [];
  final TextEditingController _searchCtrl = TextEditingController();

  bool get _isClaimed => widget.mode == ListMode.claimed;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final endpoint = _isClaimed ? 'getClaimedList.php' : 'getRemainingList.php';
      final res = await http.get(
        Uri.parse('${widget.baseUrl}$endpoint'),
        headers: {'ngrok-skip-browser-warning': '69420'},
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final raw = jsonDecode(res.body);
        if (raw is List) {
          final items = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          setState(() {
            _allItems = items;
            _filtered = items;
          });
        } else {
          setState(() => _errorMsg = 'Unexpected data format');
        }
      } else {
        setState(() => _errorMsg = 'Failed to load data');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applySearch(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? _allItems
          : _allItems.where((item) {
              final name = (item['Name_Full_name'] ?? '').toString().toLowerCase();
              final card = (item['MF_Card_No'] ?? '').toString().toLowerCase();
              final ration = (item['Ration_Card_number'] ?? '').toString().toLowerCase();
              final aadhar = (item['Aadhar_Card_number'] ?? '').toString().toLowerCase();
              return name.contains(q) || card.contains(q) || ration.contains(q) || aadhar.contains(q);
            }).toList();
    });
  }

  Future<void> _downloadExcel() async {
    if (_allItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No data to export'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      final buffer = StringBuffer();
      // Header
      if (_isClaimed) {
        buffer.writeln('Sr No,MF Card No,Name,Ration Card,Aadhar Card,Claimed At');
      } else {
        buffer.writeln('Sr No,MF Card No,Name,Ration Card,Aadhar Card,Mobile,Address');
      }

      // Rows
      for (int i = 0; i < _allItems.length; i++) {
        final item = _allItems[i];
        String escape(dynamic val) {
          final s = (val ?? '').toString().replaceAll('"', '""');
          return '"$s"';
        }

        if (_isClaimed) {
          buffer.writeln([
            i + 1,
            escape(item['MF_Card_No']),
            escape(item['Name_Full_name']),
            escape(item['Ration_Card_number']),
            escape(item['Aadhar_Card_number']),
            escape(item['claimed_at_fmt']),
          ].join(','));
        } else {
          buffer.writeln([
            i + 1,
            escape(item['MF_Card_No']),
            escape(item['Name_Full_name']),
            escape(item['Ration_Card_number']),
            escape(item['Aadhar_Card_number']),
            escape(item['Mobile_number_If_possible_WhatsApp']),
            escape(item['Address_Area_of_residence']),
          ].join(','));
        }
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = _isClaimed ? 'ClaimedMembers.csv' : 'RemainingMembers.csv';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(buffer.toString());

      await Share.shareXFiles([XFile(file.path)], text: _isClaimed ? 'Claimed Members List' : 'Remaining Members List');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final color = _isClaimed ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    final icon = _isClaimed ? Icons.verified_user_rounded : Icons.inventory_2_rounded;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          _isClaimed ? 'Total Claimed' : 'Remaining Members',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : const Color(0xFF2D3748),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading && _allItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.download_rounded),
              onPressed: _downloadExcel,
              tooltip: 'Download Excel',
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _fetch,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Header summary bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search bar
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF0F172A) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: _applySearch,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search by name, card no, ration, aadhar…',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
                        fontSize: 13,
                      ),
                      prefixIcon: Icon(Icons.search_rounded, color: color, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                _applySearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Count chip
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: color, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _isLoading
                                ? '...'
                                : '${_filtered.length} ${_filtered.length == 1 ? 'member' : 'members'}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_searchCtrl.text.isNotEmpty && _filtered.length != _allItems.length) ...[
                      const SizedBox(width: 8),
                      Text(
                        'of ${_allItems.length} total',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // ── Body ──
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: color))
                : _errorMsg != null
                    ? _buildErrorView(color)
                    : _filtered.isEmpty
                        ? _buildEmptyView(color, icon)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _filtered.length,
                            itemBuilder: (context, i) {
                              return _buildCard(_filtered[i], i, isDarkMode, color);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item, int i, bool isDarkMode, Color accentColor) {
    final name = item['Name_Full_name'] ?? '—';
    final cardNo = item['MF_Card_No'] ?? '—';
    final ration = item['Ration_Card_number'] ?? '—';
    final aadhar = item['Aadhar_Card_number'] ?? '—';
    final mobile = item['Mobile_number_If_possible_WhatsApp'] ?? '';
    final address = item['Address_Area_of_residence'] ?? '';
    final claimedAt = item['claimed_at_fmt'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF25294A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: accentColor.withOpacity(0.12),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: Name + badge ──
            Row(
              children: [
                // Avatar circle with initial
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor.withOpacity(0.8), accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Card: $cardNo',
                        style: TextStyle(
                          fontSize: 12,
                          color: accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Sr no badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#${i + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.8),
            const SizedBox(height: 12),

            // ── Row 2: Detail chips ──
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(Icons.credit_card_rounded, 'Ration', ration, isDarkMode),
                _chip(Icons.fingerprint_rounded, 'Aadhar', aadhar, isDarkMode),
                if (mobile.isNotEmpty)
                  _chip(Icons.phone_rounded, 'Mobile', mobile, isDarkMode),
                if (address.isNotEmpty)
                  _chip(Icons.location_on_rounded, 'Area', address, isDarkMode),
              ],
            ),

            // ── Claimed time (only for claimed list) ──
            if (_isClaimed && claimedAt != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Text(
                      'Distributed: $claimedAt',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, String value, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A2E) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value.length > 18 ? '${value.substring(0, 16)}…' : value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(Color color) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _errorMsg ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetch,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView(Color color, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: color.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),
            Text(
              _searchCtrl.text.isNotEmpty
                  ? 'No results for "${_searchCtrl.text}"'
                  : _isClaimed
                      ? 'No distributions recorded yet'
                      : 'All members have been distributed!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
