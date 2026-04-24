import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'ration_conflict_screen.dart';
import 'add_confirm_screen.dart';
import '../models/food_record.dart';

class AddMemberScreen extends StatefulWidget {
  final String baseUrl;

  const AddMemberScreen({super.key, required this.baseUrl});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final TextEditingController _mfController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _rationController = TextEditingController();
  final TextEditingController _aadharController = TextEditingController();
  
  bool _loading = false;
  String _latestCardNo = '';
  bool _loadingCardNo = true;

  @override
  void initState() {
    super.initState();
    _fetchLatestCardNo();
  }

  Future<void> _fetchLatestCardNo() async {
    try {
      final res = await http.get(
        Uri.parse('${widget.baseUrl}getLatestCardNo.php'),
        headers: {'ngrok-skip-browser-warning': '69420'},
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final raw = jsonDecode(res.body);
        if (raw is Map && raw['success'] == true) {
          if (mounted) setState(() => _latestCardNo = raw['latest_card'] ?? '');
        }
      }
    } catch (_) {
      // silently fail — not critical
    } finally {
      if (mounted) setState(() => _loadingCardNo = false);
    }
  }

  Future<void> _next() async {
    if (!_formKey.currentState!.validate()) return;

    // Scroll to top if there's an error
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    final mf = _mfController.text.trim();
    final ration = _rationController.text.trim();

    setState(() => _loading = true);

    // 1) MF CARD CHECK
    try {
      final uri = Uri.parse('${widget.baseUrl}checkMF.php?MF_Card_No=$mf');
      final res = await http.get(
        uri,
        headers: {'ngrok-skip-browser-warning': '69420'},
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final raw = jsonDecode(res.body);
        final data = raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};
        final exists = data['exists'] == true;
        if (exists) {
          _showMsg('Duplicate Entry', 'Card Number is already in use');
          setState(() => _loading = false);
          return;
        }
      }
    } catch (e) {
      _showMsg('Connection Error', 'Failed to verify MF Card: $e');
      setState(() => _loading = false);
      return;
    }

    // 2) RATION CARD CHECK
    List<FoodRecord> rationMembers = [];
    if (ration.isNotEmpty) {
      try {
        final uri = Uri.parse(
            '${widget.baseUrl}searchByRationForAdd.php?Ration_Card_number=$ration');
        final res = await http.get(
          uri,
          headers: {'ngrok-skip-browser-warning': '69420'},
        );
        if (res.statusCode == 200 && res.body.isNotEmpty) {
          final raw = jsonDecode(res.body);
          if (raw is List) {
            rationMembers = raw
                .map((e) => FoodRecord.fromJson(
                Map<String, dynamic>.from(e as Map)))
                .toList();
          }
        }
      } catch (e) {
        _showMsg('Connection Error', 'Failed to check ration card: $e');
        setState(() => _loading = false);
        return;
      }
    }

    // NEW MEMBER DATA (Qr_String backend se auto banega)
    final newMemberData = <String, String>{
      'MF_Card_No': mf,
      'Name_Full_name': _nameController.text.trim(),
      'Address_Area_of_residence': _addressController.text.trim(),
      'Mobile_number_If_possible_WhatsApp': _mobileController.text.trim(),
      'Ration_Card_number': ration,
      'Aadhar_Card_number': _aadharController.text.trim(),
    };

    setState(() => _loading = false);

    if (rationMembers.isNotEmpty) {
      // EXISTING RATION MEMBERS -> SHOW CONFLICT SCREEN
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RationConflictScreen(
            baseUrl: widget.baseUrl,
            existingMembers: rationMembers,
            newMemberData: newMemberData,
          ),
        ),
      );
    } else {
      // DIRECTLY CONFIRM
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddConfirmScreen(
            baseUrl: widget.baseUrl,
            newMemberData: newMemberData,
          ),
        ),
      );
    }
  }

  void _showMsg(String title, String msg) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.shade50,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: Colors.red.shade600,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                msg,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
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
      ),
    );
  }

  @override
  void dispose() {
    _mfController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _rationController.dispose();
    _aadharController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register New Member'),
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            child: Column(
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
                              Icons.person_add_alt_1_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'New Member Registration',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 24,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter member details to register in the foundation',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 15,
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      // Latest Card No display
                      if (_latestCardNo.isNotEmpty || _loadingCardNo) ...[  
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF667EEA).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline_rounded, color: Color(0xFF667EEA), size: 16),
                              const SizedBox(width: 8),
                              Text(
                                _loadingCardNo ? 'Fetching latest card no...' : 'Latest Card No: $_latestCardNo',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF667EEA),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Form Fields Card
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
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
                      // Required Fields Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4299E1).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF4299E1).withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: const Color(0xFF4299E1),
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Fields marked with * are required',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 13 : 14,
                                  color: const Color(0xFF4299E1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Form Fields
                      _buildFormField(
                        controller: _mfController,
                        label: 'Card Number *',
                        hintText: 'Enter card number',
                        icon: Icons.badge_rounded,
                        validator: (v) =>
                        v == null || v.trim().isEmpty ? 'This field is required' : null,
                        isDarkMode: isDarkMode,
                        keyboardType: TextInputType.text,
                      ),

                      const SizedBox(height: 16),

                      _buildFormField(
                        controller: _nameController,
                        label: 'Full Name *',
                        hintText: 'Enter member\'s full name',
                        icon: Icons.person_rounded,
                        validator: (v) =>
                        v == null || v.trim().isEmpty ? 'This field is required' : null,
                        isDarkMode: isDarkMode,
                        keyboardType: TextInputType.name,
                      ),

                      const SizedBox(height: 16),

                      _buildFormField(
                        controller: _addressController,
                        label: 'Address',
                        hintText: 'Enter complete address',
                        icon: Icons.location_on_rounded,
                        validator: null,
                        isDarkMode: isDarkMode,
                        keyboardType: TextInputType.streetAddress,
                      ),

                      const SizedBox(height: 16),

                      _buildFormField(
                        controller: _mobileController,
                        label: 'Mobile / WhatsApp',
                        hintText: 'Enter 10-digit mobile number',
                        icon: Icons.phone_rounded,
                        validator: null,
                        isDarkMode: isDarkMode,
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 16),

                      _buildFormField(
                        controller: _rationController,
                        label: 'Ration Card Number',
                        hintText: 'Enter ration card number',
                        icon: Icons.credit_card_rounded,
                        validator: null,
                        isDarkMode: isDarkMode,
                        keyboardType: TextInputType.text,
                      ),

                      const SizedBox(height: 16),

                      _buildFormField(
                        controller: _aadharController,
                        label: 'Aadhar Number',
                        hintText: 'Enter 12-digit Aadhar number',
                        icon: Icons.fingerprint_rounded,
                        validator: null,
                        isDarkMode: isDarkMode,
                        keyboardType: TextInputType.number,
                      ),

                      const SizedBox(height: 32),

                      // Next Button
                      SizedBox(
                        width: double.infinity,
                        height: isSmallScreen ? 52 : 56,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667EEA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _loading
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
                              const Text(
                                'VERIFY & CONTINUE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: isSmallScreen ? 18 : 20,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Process Info
                      Container(
                        padding: const EdgeInsets.all(16),
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
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              color: isDarkMode
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFF59E0B),
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Verification Process',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Card will be checked for duplicates before proceeding',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom padding
                SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    required String? Function(String?)? validator,
    required bool isDarkMode,
    required TextInputType keyboardType,
  }) {
    return Container(
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
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 15,
            color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            labelText: label,
            labelStyle: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            prefixIcon: Icon(
              icon,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              size: 20,
            ),
            errorStyle: const TextStyle(
              fontSize: 12,
            ),
          ),
          validator: validator,
        ),
      ),
    );
  }
}