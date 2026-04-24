import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'search_scan_screen.dart';
import 'add_member_screen.dart';
import 'qr_generation_screen.dart';
import 'members_list_screen.dart';
import 'duplicates_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // server base 
  static const String baseUrl =
      'https://3f02-2401-4900-ac3f-9f97-14aa-bbcb-8d5a-799c.ngrok-free.app/FoundationProject/foundationApi/';

  int _taken = 0;
  int _remaining = 0;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final res = await http.get(
        Uri.parse('${baseUrl}getCounts.php'),
        headers: {'ngrok-skip-browser-warning': '69420'},
      );
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        final raw = jsonDecode(res.body);
        final data = raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};
        setState(() {
          _taken = data['total_claimed'] ?? 0;
          _remaining = data['remaining'] ?? 0;
        });
      } else {
        setState(() => _hasError = true);
      }
    } catch (_) {
      setState(() => _hasError = true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScanScreen(baseUrl: baseUrl),
      ),
    ).then((_) => _loadCounts());
  }

  void _openAddMember() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMemberScreen(baseUrl: baseUrl),
      ),
    ).then((_) => _loadCounts());
  }

  void _openQrSingle() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrGenerationScreen(baseUrl: baseUrl, mode: QrMode.single),
      ),
    );
  }

  void _openQrAll() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrGenerationScreen(baseUrl: baseUrl, mode: QrMode.all),
      ),
    );
  }

  void _openClaimedList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MembersListScreen(baseUrl: baseUrl, mode: ListMode.claimed),
      ),
    );
  }

  void _openRemainingList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MembersListScreen(baseUrl: baseUrl, mode: ListMode.remaining),
      ),
    );
  }

  void _openDuplicates() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DuplicatesScreen(baseUrl: baseUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: isSmallScreen ? 160 : 200,
            floating: false,
            pinned: true,
            backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
            foregroundColor: isDarkMode ? Colors.white : const Color(0xFF2D3748),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.black.withOpacity(0.6)
                      : Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Foundation Dashboard',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16 : 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDarkMode
                        ? [
                      const Color(0xFF0F3460),
                      const Color(0xFF1A1A2E),
                    ]
                        : [
                      const Color(0xFF667EEA),
                      const Color(0xFF764BA2),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Colors.white.withOpacity(0.2),
                  ),
                  child: Icon(
                    Icons.refresh,
                    color: _isLoading
                        ? Colors.grey
                        : isDarkMode
                        ? Colors.white
                        : Colors.white,
                    size: 22,
                  ),
                ),
                onPressed: _isLoading ? null : _loadCounts,
                tooltip: 'Refresh Data',
              ),
            ],
          ),

          // Main Content
          SliverPadding(
            padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Statistics Section
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF25294A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : const Color(0xFF667EEA).withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Distribution Summary',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
                            ),
                          ),
                          if (_hasError)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.red.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Error',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Responsive Stats Grid
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              GestureDetector(
                                onTap: _isLoading ? null : _openClaimedList,
                                child: SizedBox(
                                  width: constraints.maxWidth / 2 - 8,
                                  child: _buildModernStatCard(
                                    title: 'Total Claimed',
                                    value: _taken,
                                    icon: Icons.verified_user_rounded,
                                    color: const Color(0xFF10B981),
                                    isLoading: _isLoading,
                                    isDarkMode: isDarkMode,
                                    isSmallScreen: isSmallScreen,
                                    tappable: true,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: _isLoading ? null : _openRemainingList,
                                child: SizedBox(
                                  width: constraints.maxWidth / 2 - 8,
                                  child: _buildModernStatCard(
                                    title: 'Remaining',
                                    value: _remaining,
                                    icon: Icons.inventory_2_rounded,
                                    color: const Color(0xFFF59E0B),
                                    isLoading: _isLoading,
                                    isDarkMode: isDarkMode,
                                    isSmallScreen: isSmallScreen,
                                    tappable: true,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      if (_hasError) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.wifi_off_rounded,
                                color: Colors.red,
                                size: isSmallScreen ? 18 : 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Connection Issue',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 13 : 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDarkMode ? Colors.white : Colors.red.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Pull down or tap refresh button to retry',
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 11 : 12,
                                        color: isDarkMode ? Colors.grey.shade400 : Colors.red.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Operations Section
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF25294A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.1),
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
                            child: Icon(
                              Icons.dashboard_customize_rounded,
                              color: Colors.white,
                              size: isSmallScreen ? 18 : 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w700,
                              color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      _buildModernActionButton(
                        icon: Icons.search_rounded,
                        title: 'Search Member',
                        subtitle: 'Manual Search/QR code scanning',
                        gradient: const [
                          Color(0xFF667EEA),
                          Color(0xFF764BA2),
                        ],
                        onTap: _openSearch,
                        isDarkMode: isDarkMode,
                        isSmallScreen: isSmallScreen,
                      ),

                      const SizedBox(height: 12),

                      _buildModernActionButton(
                        icon: Icons.person_add_alt_1_rounded,
                        title: 'Add New Member',
                        subtitle: 'Register new foundation member',
                        gradient: const [
                          Color(0xFF10B981),
                          Color(0xFF34D399),
                        ],
                        onTap: _openAddMember,
                        isDarkMode: isDarkMode,
                        isSmallScreen: isSmallScreen,
                      ),

                      const SizedBox(height: 12),

                      _buildModernActionButton(
                        icon: Icons.copy_all_rounded,
                        title: 'Duplicate Correction',
                        subtitle: 'Find & fix duplicate member data',
                        gradient: const [
                          Color(0xFFF59E0B),
                          Color(0xFFFBBF24),
                        ],
                        onTap: _openDuplicates,
                        isDarkMode: isDarkMode,
                        isSmallScreen: isSmallScreen,
                      ),
                    ],
                  ),
                ),

                // ─────────────────── PREMIUM QR GENERATION SECTION ───────────────────
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 26),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF25294A) : Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: isDarkMode
                            ? Colors.black.withOpacity(0.4)
                            : const Color(0xFF667EEA).withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFF667EEA).withOpacity(0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF9A8B), Color(0xFFFF6A88)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF6A88).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: Colors.white,
                                  size: isSmallScreen ? 18 : 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'QR Identity Hub',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 18 : 21,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.5,
                                      color: isDarkMode ? Colors.white : const Color(0xFF1A202C),
                                    ),
                                  ),
                                  Text(
                                    'Manage member credentials',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Premium Action 1
                      _buildModernActionButton(
                        icon: Icons.badge_rounded,
                        title: 'Single ID Card',
                        subtitle: 'Generate ID card for individual member',
                        gradient: const [
                          Color(0xFF667EEA),
                          Color(0xFF764BA2),
                        ],
                        onTap: _openQrSingle,
                        isDarkMode: isDarkMode,
                        isSmallScreen: isSmallScreen,
                      ),

                      const SizedBox(height: 14),

                      // Premium Action 2
                      _buildModernActionButton(
                        icon: Icons.layers_rounded,
                        title: 'Bulk Generation',
                        subtitle: 'Generate & download all ID cards',
                        gradient: const [
                          Color(0xFF6B7FD7),
                          Color(0xFF81E6D9),
                        ],
                        onTap: _openQrAll,
                        isDarkMode: isDarkMode,
                        isSmallScreen: isSmallScreen,
                      ),
                    ],
                  ),
                ),

                // Status Card
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF25294A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
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
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_done_rounded,
                          color: Colors.white,
                          size: isSmallScreen ? 18 : 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Live Database',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 13 : 14,
                                fontWeight: FontWeight.w600,
                                color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Real-time updates',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 11 : 12,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Online',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Extra spacing at bottom for safety
                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required bool isDarkMode,
    required bool isSmallScreen,
    bool tappable = false,
  }) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: tappable
              ? color.withOpacity(0.25)
              : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : tappable
                    ? color.withOpacity(0.12)
                    : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: isSmallScreen ? 18 : 22),
              ),
              if (isLoading)
                SizedBox(
                  width: isSmallScreen ? 16 : 20,
                  height: isSmallScreen ? 16 : 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                )
              else if (tappable)
                Icon(Icons.arrow_forward_ios_rounded, size: 13, color: color.withOpacity(0.6)),
            ],
          ),
          SizedBox(height: isSmallScreen ? 12 : 16),
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Text(
            isLoading ? '...' : value.toString(),
            style: TextStyle(
              fontSize: isSmallScreen ? 26 : 32,
              fontWeight: FontWeight.w800,
              color: isDarkMode ? Colors.white : color,
              height: 1,
            ),
          ),
          if (tappable) ...[
            const SizedBox(height: 6),
            Text(
              'Tap to view details',
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradient,
    required VoidCallback onTap,
    required bool isDarkMode,
    required bool isSmallScreen,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color(0xFF1A1A2E)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDarkMode
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isSmallScreen ? 12 : 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
              SizedBox(width: isSmallScreen ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : const Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 13,
                        color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: gradient.first,
                size: isSmallScreen ? 14 : 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}