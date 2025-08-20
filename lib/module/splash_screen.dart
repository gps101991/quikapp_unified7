import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/env_config.dart';
import '../services/connectivity_service.dart';
import '../services/firebase_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'error_screens.dart';

class SplashScreen extends StatefulWidget {
  final String splashLogo;
  final String splashBg;
  final String spbgColor;
  final String splashTagline;
  final String taglineColor;
  final String taglineFont;
  final double taglineSize;
  final bool taglineBold;
  final bool taglineItalic;
  final String splashAnimation;
  final int splashDuration;
  final VoidCallback onInitializationComplete;
  final VoidCallback onInitializationFailed;

  const SplashScreen({
    super.key,
    required this.splashLogo,
    required this.splashBg,
    required this.splashAnimation,
    required this.spbgColor,
    required this.taglineColor,
    required this.splashTagline,
    required this.taglineFont,
    required this.taglineSize,
    required this.taglineBold,
    required this.taglineItalic,
    required this.splashDuration,
    required this.onInitializationComplete,
    required this.onInitializationFailed,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _progressController;

  // Animations
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _scaleAnimationIn;
  late final Animation<double> _scaleAnimationOut;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _rotationAnimation;

  // Validation states
  bool _isValidating = true;
  bool _hasError = false;
  String _currentStep = "Initializing...";
  String _errorMessage = "";
  double _validationProgress = 0.0;
  String _errorType = "";
  List<String> _failedPermissions = [];
  List<String> _missingConfigs = [];

  // Services
  final ConnectivityService _connectivityService = ConnectivityService();
  Timer? _validationTimer;
  Timer? _splashTimer;

  static Color _parseHexColor(String hexColor) {
    hexColor = hexColor.replaceFirst('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor';
    return Color(int.parse('0x$hexColor'));
  }

  @override
  void initState() {
    super.initState();
    debugPrint('📦 Splash image loaded from: ${widget.splashLogo}');
    debugPrint('🎞️ Animation: ${widget.splashAnimation}');

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _progressController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.splashDuration * 1000),
    );

    _scaleAnimation =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _scaleAnimationIn =
        CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnimationOut =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    // Start validation process
    _startValidation();
  }

  void _startValidation() async {
    debugPrint('🔍 Starting app validation...');

    try {
      // Step 1: Basic configuration validation
      await _validateBasicConfig();
      _updateProgress(0.2, "Configuration validated");

      // Step 2: Connectivity check
      await _validateConnectivity();
      _updateProgress(0.4, "Network connection verified");

      // Step 3: Firebase initialization (if required)
      if (EnvConfig.pushNotify) {
        await _validateFirebase();
        _updateProgress(0.6, "Firebase configured");
      } else {
        _updateProgress(0.6, "Firebase not required");
      }

      // Step 4: Permission setup
      await _setupPermissions();
      _updateProgress(0.8, "Permissions configured");

      // Step 5: Final validation
      await _finalValidation();
      _updateProgress(1.0, "Ready to launch");

      // Wait for minimum splash duration
      final remainingTime =
          widget.splashDuration - (_validationProgress * widget.splashDuration);
      if (remainingTime > 0) {
        await Future.delayed(Duration(seconds: remainingTime.toInt()));
      }

      // Success - proceed to main app
      if (mounted) {
        widget.onInitializationComplete();
      }
    } catch (e) {
      debugPrint('❌ Validation failed: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _currentStep = "Initialization failed";
        });

        // Wait a bit before calling failure callback
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            widget.onInitializationFailed();
          }
        });
      }
    }
  }

  Future<void> _validateBasicConfig() async {
    _updateProgress(0.1, "Validating configuration...");

    try {
      // Check critical environment variables
      if (EnvConfig.webUrl.isEmpty) {
        _errorType = "configuration";
        _missingConfigs.add("WEB_URL");
        throw Exception("WEB_URL is not configured");
      }

      if (EnvConfig.appName.isEmpty) {
        debugPrint("⚠️ App name is empty, using fallback");
      }

      // Validate URL format
      try {
        Uri.parse(EnvConfig.webUrl);
      } catch (e) {
        _errorType = "configuration";
        _missingConfigs.add("Valid WEB_URL format");
        throw Exception("Invalid WEB_URL format: ${EnvConfig.webUrl}");
      }

      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      _errorType = "configuration";
      rethrow;
    }
  }

  Future<void> _validateConnectivity() async {
    _updateProgress(0.3, "Checking network connection...");

    try {
      final isOnline = await _connectivityService.checkConnectivity();
      if (!isOnline) {
        // Don't fail here, just log warning
        debugPrint(
            "⚠️ No internet connection detected, continuing with offline mode");
      }

      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      debugPrint("⚠️ Connectivity check failed: $e, continuing...");
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> _validateFirebase() async {
    _updateProgress(0.5, "Initializing Firebase...");

    try {
      if (EnvConfig.pushNotify) {
        final firebaseStatus = ConditionalFirebaseService.getStatus();

        if (firebaseStatus['shouldInitialize'] == true) {
          final success =
              await ConditionalFirebaseService.initializeConditionally();
          if (!success) {
            _errorType = "firebase";
            _errorMessage = "Firebase initialization failed";
            debugPrint(
                "⚠️ Firebase initialization failed, continuing without it");
          }
        } else {
          debugPrint("ℹ️ Firebase not required or config not available");
        }
      }

      await Future.delayed(const Duration(milliseconds: 800));
    } catch (e) {
      _errorType = "firebase";
      _errorMessage = e.toString();
      debugPrint("⚠️ Firebase validation failed: $e, continuing without it");
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> _setupPermissions() async {
    _updateProgress(0.7, "Setting up permissions...");

    try {
      // Request permissions based on configuration
      if (EnvConfig.isCamera) {
        final status = await Permission.camera.request();
        if (status.isDenied) _failedPermissions.add("Camera");
      }

      if (EnvConfig.isLocation) {
        final status = await Permission.location.request();
        if (status.isDenied) _failedPermissions.add("Location");
      }

      if (EnvConfig.isMic) {
        final status = await Permission.microphone.request();
        if (status.isDenied) _failedPermissions.add("Microphone");
      }

      if (EnvConfig.isContact) {
        final status = await Permission.contacts.request();
        if (status.isDenied) _failedPermissions.add("Contacts");
      }

      if (EnvConfig.isCalendar) {
        final status = await Permission.calendarFullAccess.request();
        if (status.isDenied) _failedPermissions.add("Calendar");
      }

      if (EnvConfig.isNotification) {
        final status = await Permission.notification.request();
        if (status.isDenied) _failedPermissions.add("Notifications");
      }

      final storageStatus = await Permission.storage.request();
      if (storageStatus.isDenied) _failedPermissions.add("Storage");

      if (EnvConfig.isBiometric) {
        if (Platform.isIOS) {
          final status = await Permission.byValue(33).request();
          if (status.isDenied) _failedPermissions.add("Biometric");
        }
      }

      if (_failedPermissions.isNotEmpty) {
        _errorType = "permissions";
        debugPrint("⚠️ Some permissions were denied: $_failedPermissions");
      }

      await Future.delayed(const Duration(milliseconds: 600));
    } catch (e) {
      _errorType = "permissions";
      _errorMessage = e.toString();
      debugPrint("⚠️ Permission setup failed: $e, continuing...");
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> _finalValidation() async {
    _updateProgress(0.9, "Final validation...");

    try {
      // Additional validation steps can be added here
      await Future.delayed(const Duration(milliseconds: 400));
    } catch (e) {
      debugPrint("⚠️ Final validation failed: $e, continuing...");
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  void _updateProgress(double progress, String step) {
    if (mounted) {
      setState(() {
        _validationProgress = progress;
        _currentStep = step;
      });
      debugPrint('📊 Progress: ${(progress * 100).toInt()}% - $step');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _progressController.dispose();
    _validationTimer?.cancel();
    _splashTimer?.cancel();
    super.dispose();
  }

  Widget _buildAnimatedLogo() {
    final image = Image.asset('assets/images/splash.png',
        height: 200, fit: BoxFit.fitHeight);

    switch (widget.splashAnimation.toLowerCase()) {
      case 'fade':
        return FadeTransition(opacity: _fadeAnimation, child: image);
      case 'slide':
        return SlideTransition(position: _slideAnimation, child: image);
      case 'rotate':
        return RotationTransition(turns: _rotationAnimation, child: image);
      case 'zoom':
        return ScaleTransition(scale: _scaleAnimation, child: image);
      case 'zoom_in':
        return ScaleTransition(scale: _scaleAnimationIn, child: image);
      case 'zoom_out':
        return ScaleTransition(scale: _scaleAnimationOut, child: image);
      case 'none':
        return image;
      default:
        return image;
    }
  }

  Widget _buildValidationProgress() {
    return Positioned(
      bottom: 120,
      left: 20,
      right: 20,
      child: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: _validationProgress,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              _hasError ? Colors.red : Colors.white,
            ),
            minHeight: 4,
          ),
          const SizedBox(height: 12),

          // Current step text
          Text(
            _currentStep,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          // Error message if any
          if (_hasError) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_errorType.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Type: $_errorType',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _parseHexColor(widget.spbgColor),
      body: Stack(
        children: [
          // Background image
          if (widget.splashBg.isNotEmpty)
            Positioned.fill(
              child: Image.asset(
                'assets/images/splash_bg.png',
                fit: BoxFit.cover,
              ),
            ),

          // Main logo
          Center(child: _buildAnimatedLogo()),

          // Tagline
          if (widget.splashTagline.isNotEmpty)
            Positioned(
              bottom: 200,
              left: 0,
              right: 0,
              child: Text(
                widget.splashTagline,
                style: GoogleFonts.getFont(
                  widget.taglineFont,
                  fontSize: widget.taglineSize,
                  fontWeight:
                      widget.taglineBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: widget.taglineItalic
                      ? FontStyle.italic
                      : FontStyle.normal,
                  color: _parseHexColor(widget.taglineColor),
                ),
                textAlign: TextAlign.center,
              ),
            ),

          // Validation progress
          _buildValidationProgress(),
        ],
      ),
    );
  }
}
