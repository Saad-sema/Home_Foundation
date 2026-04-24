import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final String _staticPassword = 'Admin@2025';
  bool _isLoading = false;
  bool _obscureText = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Request permissions after a small delay to ensure UI is ready
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _requestInitialPermissions();
    });
  }

  Future<void> _requestInitialPermissions() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        // Request both legacy and modern permissions in one go.
        // Android will automatically show the correct system dialog based on its version.
        await [
          Permission.storage,
          Permission.photos,
        ].request();
      }
    } catch (e) {
      debugPrint('Startup Permission Error: $e');
    }
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (_passwordController.text.trim() == _staticPassword) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const DashboardScreen(),
          transitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOut,
              ),
              child: child,
            );
          },
        ),
      );
    } else {
      _showErrorDialog();
    }

    setState(() => _isLoading = false);
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF25294A)
                : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade600,
                        Colors.orange.shade600,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Access Denied',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'The password you entered is incorrect. Please try again.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade400
                        : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667EEA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _passwordController.clear();
                          FocusScope.of(context).unfocus();
                        },
                        child: const Text(
                          'Try Again',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
      body: Container(
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
        child: Stack(
          children: [
            // Background decoration
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              top: 150,
              left: -50,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.03),
                ),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isSmallScreen ? 380 : 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo/Header Section
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                          margin: EdgeInsets.only(bottom: isSmallScreen ? 30 : 40),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.15),
                                      Colors.white.withOpacity(0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.25),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: Colors.white,
                                  size: isSmallScreen ? 42 : 52,
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 16 : 24),
                              Text(
                                'FOUNDATION ADMIN',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 24 : 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Secure Portal Access',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  color: Colors.white.withOpacity(0.85),
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Login Card
                        Container(
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF25294A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.15),
                                blurRadius: 40,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(isSmallScreen ? 28 : 40),
                            child: Form(
                              key: _formKey,
                              child: Column(
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
                                          Icons.lock_open_rounded,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                      SizedBox(width: isSmallScreen ? 12 : 16),
                                      Text(
                                        'Admin Authentication',
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 20 : 24,
                                          fontWeight: FontWeight.w700,
                                          color: isDarkMode
                                              ? Colors.white
                                              : const Color(0xFF2D3748),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isSmallScreen ? 8 : 12),
                                  Text(
                                    'Enter administrative password to access the dashboard',
                                    style: TextStyle(
                                      fontSize: isSmallScreen ? 13 : 15,
                                      color: isDarkMode
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 28 : 36),

                                  // Password Field
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? const Color(0xFF1A1A2E)
                                          : Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isDarkMode
                                            ? Colors.grey.shade800
                                            : Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscureText,
                                        style: TextStyle(
                                          fontSize: isSmallScreen ? 15 : 16,
                                          color: isDarkMode
                                              ? Colors.white
                                              : const Color(0xFF2D3748),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          labelText: 'Admin Password',
                                          labelStyle: TextStyle(
                                            color: isDarkMode
                                                ? Colors.grey.shade500
                                                : Colors.grey.shade500,
                                            fontSize: isSmallScreen ? 14 : 15,
                                          ),
                                          hintText: 'Enter your password',
                                          hintStyle: TextStyle(
                                            color: isDarkMode
                                                ? Colors.grey.shade600
                                                : Colors.grey.shade400,
                                          ),
                                          prefixIcon: Icon(
                                            Icons.password_rounded,
                                            color: isDarkMode
                                                ? Colors.grey.shade500
                                                : Colors.grey.shade500,
                                            size: 22,
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureText
                                                  ? Icons.visibility_off_rounded
                                                  : Icons.visibility_rounded,
                                              color: isDarkMode
                                                  ? Colors.grey.shade500
                                                  : Colors.grey.shade500,
                                              size: 22,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscureText = !_obscureText;
                                              });
                                            },
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Password is required';
                                          }
                                          return null;
                                        },
                                        onFieldSubmitted: (_) => _login(),
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: isSmallScreen ? 24 : 32),

                                  // Login Button
                                  SizedBox(
                                    width: double.infinity,
                                    height: isSmallScreen ? 52 : 58,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF667EEA),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        elevation: 0,
                                        shadowColor: Colors.transparent,
                                      ),
                                      child: _isLoading
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
                                          Text(
                                            'ACCESS DASHBOARD',
                                            style: TextStyle(
                                              fontSize: isSmallScreen ? 15 : 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          SizedBox(width: isSmallScreen ? 8 : 12),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: isSmallScreen ? 18 : 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: isSmallScreen ? 20 : 24),

                                  // Info Card
                                  Container(
                                    padding: EdgeInsets.all(isSmallScreen ? 14 : 16),
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? const Color(0xFF1A1A2E).withOpacity(0.5)
                                          : const Color(0xFF4299E1).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isDarkMode
                                            ? const Color(0xFF4299E1).withOpacity(0.3)
                                            : const Color(0xFF4299E1).withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.security_rounded,
                                          color: isDarkMode
                                              ? const Color(0xFF4299E1)
                                              : const Color(0xFF4299E1),
                                          size: 18,
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Restricted access. Contact system administrator for credentials.',
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
                          ),
                        ),

                        // Footer
                        SizedBox(height: isSmallScreen ? 32 : 40),
                        Column(
                          children: [
                            Text(
                              '© 2025 Foundation Management System',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: isSmallScreen ? 12 : 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Developed By Saad Sema',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: isSmallScreen ? 11 : 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}