import 'package:flutter/material.dart';

import '../config/env_config.dart';
import '../services/connectivity_service.dart';
import 'main_home.dart' show MainHome;
import 'splash_screen.dart';
import 'offline_screen.dart';

class MyApp extends StatefulWidget {
  final String webUrl;
  final bool isBottomMenu;
  final bool isSplash;
  final String splashLogo;
  final String splashBg;
  final int splashDuration;
  final String splashTagline;
  final String splashAnimation;
  final bool isDomainUrl;
  final String backgroundColor;
  final String activeTabColor;
  final String textColor;
  final String iconColor;
  final String iconPosition;
  final String taglineColor;
  final String spbgColor;
  final bool isLoadIndicator;
  final String bottomMenuItems;
  final String taglineFont;
  final double taglineSize;
  final bool taglineBold;
  final bool taglineItalic;
  const MyApp(
      {super.key,
      required this.webUrl,
      required this.isBottomMenu,
      required this.isSplash,
      required this.splashLogo,
      required this.splashBg,
      required this.splashDuration,
      required this.splashAnimation,
      required this.bottomMenuItems,
      required this.isDomainUrl,
      required this.backgroundColor,
      required this.activeTabColor,
      required this.textColor,
      required this.iconColor,
      required this.iconPosition,
      required this.taglineColor,
      required this.spbgColor,
      required this.isLoadIndicator,
      required this.splashTagline,
      required this.taglineFont,
      required this.taglineSize,
      required this.taglineBold,
      required this.taglineItalic});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool showSplash = false;
  bool isOnline = true;
  bool _initializationComplete = false;
  bool _initializationFailed = false;
  String? _initializationError;
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    debugPrint('🚀 MyApp initializing...');
    debugPrint('   - Splash enabled: ${widget.isSplash}');
    debugPrint(
        '   - Initial connectivity: ${_connectivityService.isConnected}');

    setState(() {
      showSplash = widget.isSplash;
      isOnline = _connectivityService.isConnected;
    });

    debugPrint('   - State set - Splash: $showSplash, Online: $isOnline');

    // Listen to connectivity changes
    _connectivityService.connectivityStream.listen((connected) {
      if (mounted) {
        setState(() {
          isOnline = connected;
        });
      }
    });

    // Add a timeout to prevent getting stuck on offline screen
    Future.delayed(Duration(seconds: 10), () {
      if (mounted && !isOnline) {
        debugPrint(
            '⚠️ Connectivity timeout reached, forcing online status for better UX');
        setState(() {
          isOnline = true;
        });
      }
    });
  }

  void _handleInitializationComplete() {
    debugPrint('✅ App initialization completed successfully');
    if (mounted) {
      setState(() {
        _initializationComplete = true;
        showSplash = false;
      });
    }
  }

  void _handleInitializationFailed() {
    debugPrint('❌ App initialization failed');
    if (mounted) {
      setState(() {
        _initializationFailed = true;
        showSplash = false;
      });
    }
  }

  void _handleRetryConnection() async {
    debugPrint('🔄 Retrying connection...');
    try {
      // Force refresh connectivity status
      await _connectivityService.refreshConnectivity();
      setState(() {
        isOnline = _connectivityService.isConnected;
      });
      debugPrint('🔄 Connection retry completed. Online: $isOnline');
    } catch (e) {
      debugPrint('❌ Error during connection retry: $e');
      // Force set to online for better UX
      setState(() {
        isOnline = true;
      });
    }
  }

  void _retryInitialization() {
    debugPrint('🔄 Retrying app initialization...');
    setState(() {
      _initializationFailed = false;
      _initializationComplete = false;
      showSplash = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏗️ MyApp building...');
    debugPrint('   - Current state - Splash: $showSplash, Online: $isOnline');
    debugPrint(
        '   - Initialization - Complete: $_initializationComplete, Failed: $_initializationFailed');

    try {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _buildHomeScreen(),
      );
    } catch (e, stackTrace) {
      debugPrint("❌ Error in MyApp build: $e");
      debugPrint("Stack trace: $stackTrace");
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home:
            _buildErrorScreen("App Error", e.toString(), stackTrace.toString()),
      );
    }
  }

  Widget _buildHomeScreen() {
    // Show splash screen if enabled and initialization not complete
    if (widget.isSplash && !_initializationComplete && !_initializationFailed) {
      return SplashScreen(
        splashLogo: widget.splashLogo,
        splashBg: widget.splashBg,
        splashAnimation: widget.splashAnimation,
        spbgColor: widget.spbgColor,
        taglineColor: widget.taglineColor,
        splashTagline: widget.splashTagline,
        taglineFont: widget.taglineFont,
        taglineSize: widget.taglineSize,
        taglineBold: widget.taglineBold,
        taglineItalic: widget.taglineItalic,
        splashDuration: widget.splashDuration,
        onInitializationComplete: _handleInitializationComplete,
        onInitializationFailed: _handleInitializationFailed,
      );
    }

    // Show initialization failed screen
    if (_initializationFailed) {
      return _buildInitializationFailedScreen();
    }

    // Show offline screen if no internet
    if (!isOnline) {
      return OfflineScreen(
        onRetry: _handleRetryConnection,
        appName: EnvConfig.appName,
      );
    }

    // Show main app
    return MainHome(
      webUrl: widget.webUrl,
      isBottomMenu: widget.isBottomMenu,
      bottomMenuItems: widget.bottomMenuItems,
      isDomainUrl: widget.isDomainUrl,
      backgroundColor: widget.backgroundColor,
      activeTabColor: widget.activeTabColor,
      textColor: widget.textColor,
      iconColor: widget.iconColor,
      iconPosition: widget.iconPosition,
      taglineColor: widget.taglineColor,
      isLoadIndicator: widget.isLoadIndicator,
    );
  }

  Widget _buildInitializationFailedScreen() {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'App Initialization Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Unable to initialize the app properly',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _retryInitialization,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _initializationFailed = false;
                          _initializationComplete = true;
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                      ),
                      icon: const Icon(Icons.skip_next),
                      label: const Text('Skip'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Check your configuration and try again',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String title, String error, String stackTrace) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red.shade400,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _initializationFailed = false;
                      _initializationComplete = false;
                      showSplash = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restart App'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please check the configuration and try again',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
