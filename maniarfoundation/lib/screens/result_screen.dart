import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/food_record.dart';

class ResultScreen extends StatefulWidget {
  final List<FoodRecord> records;
  final String baseUrl;
  final List<bool>? initialClaimed;
  final List<String?>? claimedAtTimes;

  const ResultScreen({
    super.key,
    required this.records,
    required this.baseUrl,
    this.initialClaimed,
    this.claimedAtTimes,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late List<FoodRecord> _records;
  late List<bool> _loading;
  late List<bool> _isClaimed;
  late List<String?> _claimedAtTimes;

  @override
  void initState() {
    super.initState();
    _records = List.from(widget.records);
    _loading = List.filled(widget.records.length, false);
    _isClaimed = widget.initialClaimed != null
        ? List.from(widget.initialClaimed!)
        : List.filled(widget.records.length, false);
    _claimedAtTimes = widget.claimedAtTimes != null
        ? List.from(widget.claimedAtTimes!)
        : List.filled(widget.records.length, null);

    // If not pre-populated (e.g. manual search), fetch claim status for all records
    if (widget.initialClaimed == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchClaimStatuses());
    }
  }

  // Fetch claim status for each record from the API (used for manual search)
  Future<void> _fetchClaimStatuses() async {
    for (int i = 0; i < _records.length; i++) {
      try {
        final res = await http.get(
          Uri.parse('${widget.baseUrl}checkClaim.php?MF_Card_No=${_records[i].mfCardNo}'),
          headers: {'ngrok-skip-browser-warning': '69420'},
        );
        if (res.statusCode == 200 && res.body.isNotEmpty) {
          final raw = jsonDecode(res.body);
          final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
          final alreadyClaimed = data['success'] != true;
          final String? claimedAt = data['claimed_at'] as String?;
          if (alreadyClaimed && mounted) {
            setState(() {
              _isClaimed[i] = true;
              _claimedAtTimes[i] = claimedAt;
            });
          }
        }
      } catch (_) {}
    }
  }

  // ──────────────────────────────── CLAIM ────────────────────────────────────
  Future<void> _insertClaim(int index) async {
    final r = _records[index];
    setState(() => _loading[index] = true);

    try {
      final res = await http.post(
        Uri.parse('${widget.baseUrl}insertClaim.php'),
        headers: {'ngrok-skip-browser-warning': '69420'},
        body: {
          'Qr_srl': r.qrSrl.toString(),
          'MF_Card_No': r.mfCardNo,
          'Name_Full_name': r.name,
          'Ration_Card_number': r.rationCard,
          'Aadhar_Card_number': r.aadhar,
        },
      );

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final raw = jsonDecode(res.body);
        final data = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
        if (data['success'] == true) {
          // Get current time in 12-hour format for immediate display
          final now = DateTime.now();
          final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
          final minute = now.minute.toString().padLeft(2, '0');
          final period = now.hour < 12 ? 'AM' : 'PM';
          final day = now.day.toString().padLeft(2, '0');
          final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
          final month = months[now.month - 1];
          final claimedTime = '$day $month ${now.year}, $hour:$minute $period';
          setState(() {
            _isClaimed[index] = true;
            _claimedAtTimes[index] = claimedTime;
          });
          _showSuccessDialog();
        } else {
          _showErrorMsg(data['message']?.toString() ?? 'Unknown error');
        }
      } else {
        _showErrorMsg('Failed to connect to server');
      }
    } catch (e) {
      _showErrorMsg('An error occurred: $e');
    } finally {
      setState(() => _loading[index] = false);
    }
  }

  // ──────────────────────────────── EDIT ─────────────────────────────────────
  void _openEditDialog(int index) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => MemberEditDialog(
        record: _records[index],
        baseUrl: widget.baseUrl,
        onUpdate: (updatedRecord) {
          if (mounted) {
            setState(() {
              _records[index] = updatedRecord;
            });
          }
        },
        showSnack: _showSnack,
      ),
    );
  }
  // ─────────────────────────────── DIALOGS ───────────────────────────────────
  void _showSuccessDialog() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF34D399)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                boxShadow: [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text('Claim Successful!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
            const SizedBox(height: 12),
            const Text('Food distribution has been recorded successfully.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Color(0xFF4B5563))),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
                ),
                child: const Text('RETURN TO DASHBOARD', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorMsg(String msg) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 60, height: 60,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.shade50),
                child: Icon(Icons.error_outline_rounded, color: Colors.red.shade600, size: 30)),
              const SizedBox(height: 16),
              const Text('Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667EEA), foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('OK'),
                )),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isSuccess ? const Color(0xFF10B981) : Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ──────────────────────────────── BUILD ────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = MediaQuery.of(context).size.height < 700;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_records.length > 1 ? 'Search Results (${_records.length})' : 'Member Details'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : const Color(0xFF2D3748),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: isDarkMode ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: isDarkMode
              ? [const Color(0xFF0F3460).withOpacity(0.3), const Color(0xFF1A1A2E)]
              : [Colors.grey.shade50, Colors.grey.shade100],
          ),
        ),
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            isSmallScreen ? 14 : 18,
            isSmallScreen ? 14 : 18,
            isSmallScreen ? 14 : 18,
            MediaQuery.of(context).padding.bottom + (isSmallScreen ? 14 : 18),
          ),
          itemCount: _records.length + 1, // +1 for header
          itemBuilder: (context, i) {
            if (i == 0) {
              // ── Header ──
              return Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF25294A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_records.length > 1 ? 'Multiple Members Found' : 'Member Information',
                            style: TextStyle(fontSize: isSmallScreen ? 18 : 22, fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : const Color(0xFF2D3748))),
                          const SizedBox(height: 4),
                          Text(
                            _records.length > 1
                              ? '${_records.length} members share this ration/aadhar card'
                              : 'Review and confirm food distribution',
                            style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            final index = i - 1;
            final r = _records[index];
            return _buildMemberCard(r, index, isDarkMode, isSmallScreen, screenWidth);
          },
        ),
      ),
      bottomNavigationBar: _records.length == 1 
        ? Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).padding.bottom + 20),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, -5))
              ],
            ),
            child: IntrinsicHeight(
              child: _buildConfirmButton(0, isDarkMode, isSmallScreen),
            ),
          )
        : null,
    );
  }

  int _getEmptyFieldsCount(FoodRecord r) {
    int count = 0;
    if (r.rationCard.isEmpty || r.rationCard == '—') count++;
    if (r.aadhar.isEmpty || r.aadhar == '—') count++;
    if (r.address.isEmpty || r.address.toLowerCase() == 'not provided') count++;
    if (r.mobile.isEmpty || r.mobile == '—') count++;
    return count;
  }

  Widget _buildMemberCard(FoodRecord r, int index, bool isDarkMode, bool isSmallScreen, double screenWidth) {
    final isClaimed = _isClaimed[index];
    final isLoading = _loading[index];
    
    // Calculate empty fields for highlighting
    final emptyCount = _getEmptyFieldsCount(r);
    
    Color borderColor = Colors.transparent;
    Color bgColor = isDarkMode ? const Color(0xFF25294A) : Colors.white;
    
    if (emptyCount >= 3) {
      borderColor = Colors.red.shade400;
      bgColor = isDarkMode ? Colors.red.shade900.withOpacity(0.15) : Colors.red.shade50;
    } else if (emptyCount >= 1) {
      borderColor = Colors.orange.shade400;
      bgColor = isDarkMode ? Colors.orange.shade900.withOpacity(0.1) : Colors.orange.shade50.withOpacity(0.5);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 4))],
        border: Border.all(
          color: borderColor != Colors.transparent 
            ? borderColor 
            : (_records.length > 1 ? const Color(0xFF667EEA).withOpacity(0.3) : Colors.transparent),
          width: borderColor != Colors.transparent ? 2.0 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card Header ──
          Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _records.length > 1
                  ? [const Color(0xFF667EEA).withOpacity(0.15), const Color(0xFF764BA2).withOpacity(0.05)]
                  : [Colors.transparent, Colors.transparent],
              ),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            ),
            child: Row(
              children: [
                // Member number badge
                if (_records.length > 1) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Member ${index + 1}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(r.name,
                    style: TextStyle(fontSize: isSmallScreen ? 15 : 17, fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white : const Color(0xFF2D3748)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                // Claimed badge
                if (isClaimed)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 13),
                            SizedBox(width: 4),
                            Text('Distributed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
                          ],
                        ),
                        if (_claimedAtTimes[index] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _claimedAtTimes[index]!,
                            style: const TextStyle(fontSize: 9, color: Color(0xFF10B981)),
                          ),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(width: 6),
                // Edit button
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.edit_rounded, color: Color(0xFF667EEA), size: 16),
                  ),
                  onPressed: () => _openEditDialog(index),
                  tooltip: 'Edit Member',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1),

          // ── Member Details ──
          Padding(
            padding: EdgeInsets.all(isSmallScreen ? 14 : 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grid of card details
                LayoutBuilder(
                  builder: (context, constraints) {
                    final cellWidth = (constraints.maxWidth - 12) / 2;
                    final fieldHighlight = borderColor.withOpacity(0.12);
                    
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(width: cellWidth, child: _buildDetailItem(icon: Icons.badge_rounded, label: 'Card No', value: r.mfCardNo, isDarkMode: isDarkMode)),
                        SizedBox(width: cellWidth, child: _buildDetailItem(
                          icon: Icons.credit_card_rounded, 
                          label: 'Ration Card', 
                          value: r.rationCard.isNotEmpty && r.rationCard != '—' ? r.rationCard : '—', 
                          isDarkMode: isDarkMode,
                          highlightColor: (r.rationCard.isEmpty || r.rationCard == '—') ? fieldHighlight : null,
                        )),
                        SizedBox(width: cellWidth, child: _buildDetailItem(
                          icon: Icons.fingerprint_rounded, 
                          label: 'Aadhar No', 
                          value: r.aadhar.isNotEmpty && r.aadhar != '—' ? r.aadhar : '—', 
                          isDarkMode: isDarkMode,
                          highlightColor: (r.aadhar.isEmpty || r.aadhar == '—') ? fieldHighlight : null,
                        )),
                        if (r.mobile.isNotEmpty)
                          SizedBox(width: cellWidth, child: _buildDetailItem(icon: Icons.phone_rounded, label: 'Mobile', value: r.mobile, isDarkMode: isDarkMode))
                        else
                          SizedBox(width: cellWidth, child: _buildDetailItem(
                            icon: Icons.phone_rounded, 
                            label: 'Mobile', 
                            value: '—', 
                            isDarkMode: isDarkMode,
                            highlightColor: fieldHighlight,
                          )),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 14),

                // Address
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (r.address.isEmpty || r.address.toLowerCase() == 'not provided') 
                        ? borderColor.withOpacity(0.12)
                        : (isDarkMode ? const Color(0xFF1A1A2E) : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (r.address.isEmpty || r.address.toLowerCase() == 'not provided')
                          ? borderColor.withOpacity(0.3)
                          : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
                      width: (r.address.isEmpty || r.address.toLowerCase() == 'not provided') ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Color(0xFFF59E0B), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Address', style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Text(r.address.isNotEmpty && r.address.toLowerCase() != 'not provided' ? r.address : 'Not provided',
                              style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : const Color(0xFF2D3748))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ── Confirm Distribution Button ──
                if (_records.length > 1) 
                  _buildConfirmButton(index, isDarkMode, isSmallScreen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton(int index, bool isDarkMode, bool isSmallScreen) {
    final isClaimed = _isClaimed[index];
    final isLoading = _loading[index];
    final claimedAt = _claimedAtTimes[index];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: double.infinity,
          height: isSmallScreen ? 50 : 54,
          child: ElevatedButton(
            onPressed: isClaimed ? null : (isLoading ? null : () => _insertClaim(index)),
            style: ElevatedButton.styleFrom(
              backgroundColor: isClaimed ? Colors.grey.shade300 : const Color(0xFF10B981),
              foregroundColor: isClaimed ? Colors.grey.shade600 : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: isClaimed ? 0 : 2,
            ),
            child: isLoading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isClaimed ? Icons.check_circle_rounded : Icons.how_to_reg_rounded, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      isClaimed ? 'ALREADY DISTRIBUTED' : 'CONFIRM DISTRIBUTION',
                      style: TextStyle(fontSize: isSmallScreen ? 13 : 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                    ),
                  ],
                ),
          ),
        ),
        if (isClaimed && claimedAt != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.access_time_rounded, size: 13, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text(
                'Distributed on: $claimedAt',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isDarkMode,
    Color? highlightColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlightColor ?? (isDarkMode ? const Color(0xFF1A1A2E) : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlightColor != null 
            ? highlightColor.withOpacity(0.5) 
            : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200),
          width: highlightColor != null ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500, size: 14),
              const SizedBox(width: 5),
              Flexible(child: Text(label, style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600))),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : const Color(0xFF2D3748)),
            overflow: TextOverflow.ellipsis, maxLines: 1),
        ],
      ),
    );
  }
}

class MemberEditDialog extends StatefulWidget {
  final FoodRecord record;
  final String baseUrl;
  final Function(FoodRecord) onUpdate;
  final Function(String, {bool isSuccess}) showSnack;

  const MemberEditDialog({
    super.key,
    required this.record,
    required this.baseUrl,
    required this.onUpdate,
    required this.showSnack,
  });

  @override
  State<MemberEditDialog> createState() => _MemberEditDialogState();
}

class _MemberEditDialogState extends State<MemberEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _mfCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _addCtrl;
  late TextEditingController _mobCtrl;
  late TextEditingController _rationCtrl;
  late TextEditingController _aadharCtrl;

  bool _saving = false;
  String? _errorMsg;
  late String _isConsistent;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _mfCtrl = TextEditingController(text: r.mfCardNo);
    _nameCtrl = TextEditingController(text: r.name);
    _addCtrl = TextEditingController(text: r.address);
    _mobCtrl = TextEditingController(text: r.mobile);
    _rationCtrl = TextEditingController(text: r.rationCard);
    _aadharCtrl = TextEditingController(text: r.aadhar);
    _isConsistent = (r.isConsistent.toLowerCase() == 'no') ? 'No' : 'Yes';
  }

  @override
  void dispose() {
    _mfCtrl.dispose();
    _nameCtrl.dispose();
    _addCtrl.dispose();
    _mobCtrl.dispose();
    _rationCtrl.dispose();
    _aadharCtrl.dispose();
    super.dispose();
  }

  Future<void> _save({bool ignoreConflict = false}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _errorMsg = null;
    });

    try {
      final res = await http.post(
        Uri.parse('${widget.baseUrl}updateMember.php'),
        headers: {'ngrok-skip-browser-warning': '69420'},
        body: {
          'Qr_srl': widget.record.qrSrl.toString(),
          'MF_Card_No': _mfCtrl.text.trim(),
          'Name_Full_name': _nameCtrl.text.trim(),
          'Address_Area_of_residence': _addCtrl.text.trim(),
          'Mobile_number_If_possible_WhatsApp': _mobCtrl.text.trim(),
          'Ration_Card_number': _rationCtrl.text.trim(),
          'Aadhar_Card_number': _aadharCtrl.text.trim(),
          'Is_Consistent': _isConsistent,
          'ignore_conflict': ignoreConflict ? 'true' : 'false',
        },
      );

      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          final updated = widget.record.copyWith(
            mfCardNo: _mfCtrl.text.trim(),
            name: _nameCtrl.text.trim(),
            address: _addCtrl.text.trim(),
            mobile: _mobCtrl.text.trim(),
            rationCard: _rationCtrl.text.trim(),
            aadhar: _aadharCtrl.text.trim(),
            isConsistent: _isConsistent,
          );
          widget.onUpdate(updated);
          if (mounted) Navigator.of(context).pop();
          widget.showSnack('Member updated successfully!', isSuccess: true);
        } else if (data['error_type'] == 'duplicate') {
          _showConflictDialog(data['conflict_member']);
        } else {
          setState(() => _errorMsg = data['message']?.toString() ?? 'Update failed');
        }
      } else {
        setState(() => _errorMsg = 'Server connection failed');
      }
    } catch (e) {
      setState(() => _errorMsg = 'Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showConflictDialog(Map<String, dynamic> conflict) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 28),
            SizedBox(width: 12),
            Text('Duplicate Detection', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This ration card is already assigned to:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  _conflictRow(Icons.person, 'Name', conflict['name'] ?? 'Unknown'),
                  const Divider(height: 16),
                  _conflictRow(Icons.badge, 'MF Card', conflict['mf_card'] ?? 'N/A'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('How would you like to proceed?', style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _save(ignoreConflict: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667EEA),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _conflictRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF667EEA)),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.black54)),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2D3748)))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDarkMode ? const Color(0xFF1E2235) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dialog Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Edit Member',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMsg != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(_errorMsg!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                            ],
                          ),
                        ),
                      ],
                      _editField(
                          ctrl: _mfCtrl,
                          label: 'Card Number *',
                          icon: Icons.badge_rounded,
                          isDark: isDarkMode,
                          required: true),
                      const SizedBox(height: 14),
                      _editField(
                          ctrl: _nameCtrl,
                          label: 'Full Name *',
                          icon: Icons.person_rounded,
                          isDark: isDarkMode,
                          required: true,
                          capitalization: TextCapitalization.words),
                      const SizedBox(height: 14),
                      _editField(
                          ctrl: _addCtrl,
                          label: 'Address',
                          icon: Icons.location_on_rounded,
                          isDark: isDarkMode,
                          maxLines: 2),
                      const SizedBox(height: 14),
                      _editField(
                          ctrl: _mobCtrl,
                          label: 'Mobile / WhatsApp',
                          icon: Icons.phone_rounded,
                          isDark: isDarkMode,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 14),
                      _editField(
                          ctrl: _rationCtrl,
                          label: 'Ration Card Number',
                          icon: Icons.credit_card_rounded,
                          isDark: isDarkMode),
                      const SizedBox(height: 14),
                      _editField(
                          ctrl: _aadharCtrl,
                          label: 'Aadhar Number',
                          icon: Icons.fingerprint_rounded,
                          isDark: isDarkMode,
                          keyboardType: TextInputType.number),
                      const SizedBox(height: 20),
                      const Text('Consistency Status', 
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF667EEA))),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _isConsistent,
                        style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white : const Color(0xFF2D3748)),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 18, color: Color(0xFF667EEA)),
                          filled: true,
                          fillColor: isDarkMode ? const Color(0xFF2A2F4A) : Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        dropdownColor: isDarkMode ? const Color(0xFF2A2F4A) : Colors.white,
                        items: const [
                          DropdownMenuItem(value: 'Yes', child: Text('Yes (Will generate QR)')),
                          DropdownMenuItem(value: 'No', child: Text('No (Will hide from QR list)')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _isConsistent = val);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                      child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667EEA),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editField({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    required bool isDark,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      textCapitalization: capitalization,
      maxLines: maxLines,
      style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF2D3748)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF667EEA)),
        filled: true,
        fillColor: isDark ? const Color(0xFF2A2F4A) : Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2)),
        labelStyle: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
    );
  }
}