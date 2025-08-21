import 'dart:async';
import 'dart:convert';

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../config/env_config.dart';
import '../services/notification_service.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/connectivity_service.dart';
import '../services/firebase_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../chat/chat_widget.dart';

import '../config/trusted_domains.dart';
import '../utils/menu_parser.dart';

class MainHome extends StatefulWidget {
  final String webUrl;
  final bool isBottomMenu;
  final String bottomMenuItems;
  final bool isDomainUrl;
  final String backgroundColor;
  final String activeTabColor;
  final String textColor;
  final String iconColor;
  final String iconPosition;
  final String taglineColor;
  final bool isLoadIndicator;
  const MainHome(
      {super.key,
      required this.webUrl,
      required this.isBottomMenu,
      required this.bottomMenuItems,
      required this.isDomainUrl,
      required this.backgroundColor,
      required this.activeTabColor,
      required this.textColor,
      required this.iconColor,
      required this.iconPosition,
      required this.taglineColor,
      required this.isLoadIndicator});

  @override
  State<MainHome> createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  final GlobalKey webViewKey = GlobalKey();

  late bool isBottomMenu;

  int _currentIndex = 0;

  InAppWebViewController? webViewController;
  late PullToRefreshController? pullToRefreshController;

  // 🔧 FIX: Add icon cache to prevent flickering
  final Map<String, Widget> _iconCache = {};
  final Map<String, Widget> _activeIconCache = {};

  static Color _parseHexColor(String hexColor) {
    hexColor = hexColor.replaceFirst('#', '');
    if (hexColor.length == 6) hexColor = 'FF$hexColor';
    return Color(int.parse('0x$hexColor'));
  }

  bool? hasInternet;
// Convert the JSON string into a List of menu objects
  List<Map<String, dynamic>> bottomMenuItems = [];

  String url = "";
  double progress = 0;
  final urlController = TextEditingController();
  DateTime? _lastBackPressed;
  String? _pendingInitialUrl; // 🔹 NEW
  bool isChatVisible = false;

  String myDomain = "";

  InAppWebViewSettings settings = InAppWebViewSettings(
    useShouldOverrideUrlLoading: true,
    mediaPlaybackRequiresUserGesture: false,
    useOnLoadResource: true,
    userAgent:
        "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36",
    // Add better error handling settings
    allowsInlineMediaPlayback: true,
    allowsLinkPreview: false,
    // Better cache settings
    cacheEnabled: true,
    // Security settings
    allowsBackForwardNavigationGestures: true,
    // Better rendering
    useWideViewPort: true,
    loadWithOverviewMode: true,
  );

  Offset _dragPosition =
      const Offset(16, 300); // Initial position for chat toggle
  String get InitialCurrentURL => widget.webUrl;

  // Environment variables with defaults
  final bool pushNotify =
      bool.fromEnvironment('PUSH_NOTIFY', defaultValue: false);

  // Chat icon boundary constraints
  late Size _screenSize;
  late double _chatIconSize;
  late double _bottomMenuHeight;

  // Method to set initial position based on screen size
  void _setInitialChatPosition() {
    if (_screenSize.width > 0) {
      // Position in bottom-right corner with proper spacing
      _dragPosition = Offset(
        _screenSize.width - _chatIconSize - 16, // Right edge with padding
        _screenSize.height -
            _chatIconSize -
            _bottomMenuHeight -
            80, // Above bottom menu
      );
    }
  }

  // Method to ensure chat icon is within bounds
  void _ensureChatIconInBounds() {
    if (_screenSize.width > 0) {
      double maxX = _screenSize.width - _chatIconSize - 16;
      double minX = 16;
      double maxY = _screenSize.height - _chatIconSize - _bottomMenuHeight - 16;
      double minY = MediaQuery.of(context).padding.top + 16;

      _dragPosition = Offset(
        _dragPosition.dx.clamp(minX, maxX),
        _dragPosition.dy.clamp(minY, maxY),
      );
    }
  }

  // 🔧 FIX: Pre-build and cache all icons to prevent flickering
  void _prebuildIcons() {
    if (bottomMenuItems.isEmpty) return;

    debugPrint("🔧 Pre-building bottom menu icons to prevent flickering...");

    for (int i = 0; i < bottomMenuItems.length; i++) {
      final item = bottomMenuItems[i];
      final cacheKey = '${item['label']}_${item['icon']}';

      // Build inactive icon
      _buildMenuIconSync(item, false, _parseHexColor(widget.activeTabColor),
              _parseHexColor(widget.iconColor))
          .then((icon) {
        if (mounted) {
          _iconCache[cacheKey] = icon;
        }
      });

      // Build active icon
      _buildMenuIconSync(item, true, _parseHexColor(widget.activeTabColor),
              _parseHexColor(widget.iconColor))
          .then((icon) {
        if (mounted) {
          _activeIconCache[cacheKey] = icon;
        }
      });
    }

    debugPrint("✅ Icon pre-building completed");
  }

  // 🔧 FIX: Synchronous icon building for caching
  Future<Widget> _buildMenuIconSync(Map<String, dynamic> item, bool isActive,
      Color activeColor, Color defaultColor) async {
    final iconData = item['icon'];
    if (iconData == null) {
      return Icon(Icons.error, color: isActive ? activeColor : defaultColor);
    }

    // Handle legacy string-based icon name for backward compatibility
    if (iconData is String) {
      return Icon(
        _getIconByName(iconData),
        color: isActive ? activeColor : defaultColor,
      );
    }

    if (iconData is! Map<String, dynamic>) {
      debugPrint("Invalid bottom menu icon format: $iconData");
      return Icon(Icons.error_outline,
          color: isActive ? activeColor : defaultColor);
    }

    if (iconData['type'] == 'preset') {
      return Icon(
        _getIconByName(iconData['name'] ?? ''),
        color: isActive ? activeColor : defaultColor,
      );
    }

    if (iconData['type'] == 'custom' && iconData['icon_url'] != null) {
      final labelSanitized = (item['label'] as String)
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), '_');
      final fileName = '$labelSanitized.svg';
      final assetPath = 'assets/icons/$fileName';

      // Use SvgPicture.asset to load from pre-downloaded assets folder
      // Icons are downloaded during build process by download_custom_icons.sh
      return SvgPicture.asset(
        assetPath,
        width: double.tryParse(iconData['icon_size']?.toString() ?? '24') ?? 24,
        height:
            double.tryParse(iconData['icon_size']?.toString() ?? '24') ?? 24,
        colorFilter: ColorFilter.mode(
            isActive ? activeColor : defaultColor, BlendMode.srcIn),
        placeholderBuilder: (_) => Icon(Icons.image_not_supported,
            color: isActive ? activeColor : defaultColor), // Fallback icon
      );
    }

    // Fallback for unknown icon type
    return Icon(Icons.help_outline,
        color: isActive ? activeColor : defaultColor);
  }

  // 🔧 FIX: Get cached icon or build if not cached
  Widget _getCachedIcon(Map<String, dynamic> item, bool isActive) {
    final cacheKey = '${item['label']}_${item['icon']}';
    final cache = isActive ? _activeIconCache : _iconCache;

    if (cache.containsKey(cacheKey)) {
      return cache[cacheKey]!;
    }

    // Fallback to building icon if not cached
    return FutureBuilder<Widget>(
      future: _buildMenuIconSync(
          item,
          isActive,
          _parseHexColor(widget.activeTabColor),
          _parseHexColor(widget.iconColor)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          // Cache the built icon
          cache[cacheKey] = snapshot.data!;
          return snapshot.data!;
        }
        if (snapshot.hasError) {
          return Icon(Icons.error, color: _parseHexColor(widget.iconColor));
        }
        // Show a placeholder while loading custom icons
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.0),
        );
      },
    );
  }

  void requestPermissions() async {
    if (EnvConfig.isCamera) await Permission.camera.request();
    if (EnvConfig.isLocation) await Permission.location.request(); // GPS
    if (EnvConfig.isMic) await Permission.microphone.request();
    if (EnvConfig.isContact) await Permission.contacts.request();
    if (EnvConfig.isCalendar) await Permission.calendar.request();
    if (EnvConfig.isNotification) await Permission.notification.request();

    // Always request storage (as per your logic)
    await Permission.storage.request();
    if (isBiometricEnabled) {
      if (Platform.isIOS) {
        // Use raw value 33 for faceId (iOS)
        await Permission.byValue(33).request();
      } else if (Platform.isAndroid) {
        // No need to request biometric permission manually on Android
        // It's requested automatically by biometric plugins like local_auth
      }
    }
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();
    try {
      debugPrint("🚀 MainHome initializing...");
      debugPrint("   - Push Notify: ${EnvConfig.pushNotify}");
      debugPrint(
          "   - Firebase apps count: ${ConditionalFirebaseService.getStatus()['appsCount']}");

      // Initialize chat icon constraints
      _chatIconSize = 56.0; // Standard FAB size
      _bottomMenuHeight =
          widget.isBottomMenu ? 80.0 : 0.0; // Bottom menu height if enabled

      // Firebase is already initialized by splash screen, just verify status
      if (EnvConfig.pushNotify) {
        try {
          if (ConditionalFirebaseService.isFirebaseAvailableSafe) {
            debugPrint("✅ Firebase already initialized in MainHome");

            Future.delayed(Duration.zero, () async {
              try {
                final token = await FirebaseMessaging.instance.getToken();
                if (kDebugMode) {
                  print("🔑 Firebase Token: $token");
                }
              } catch (e) {
                if (kDebugMode) {
                  print("🚨 Error getting Firebase token: $e");
                }
              }
            });
          } else {
            debugPrint(
                "⚠️ Firebase not available, skipping Firebase setup in MainHome");
          }
        } catch (e) {
          if (kDebugMode) {
            print("🚨 Error checking Firebase in MainHome: $e");
          }
        }
      }

      // Permissions are already requested by splash screen
      debugPrint("✅ Permissions already handled by splash screen");

      if (EnvConfig.pushNotify &&
          ConditionalFirebaseService.isFirebaseAvailableSafe) {
        try {
          setupFirebaseMessaging();
          FirebaseMessaging.instance.getInitialMessage().then((message) async {
            if (message != null) {
              final internalUrl = message.data['url'];
              if (internalUrl != null && internalUrl.isNotEmpty) {
                _pendingInitialUrl = internalUrl;
              }
              await _showLocalNotification(message);
            }
          });
        } catch (e) {
          debugPrint("🚨 Error setting up Firebase messaging: $e");
        }
      } else if (EnvConfig.pushNotify) {
        debugPrint(
            "⚠️ Firebase not available, skipping push notification setup");
      }

      isBottomMenu = widget.isBottomMenu;

      if (widget.bottomMenuItems.isNotEmpty) {
        try {
          debugPrint("🔧 Parsing bottom menu items...");
          debugPrint("   Raw: ${widget.bottomMenuItems}");

          // Use the robust MenuParser utility
          bottomMenuItems = MenuParser.parseMenuItems(widget.bottomMenuItems);

          // Clean and validate the parsed items
          bottomMenuItems = MenuParser.cleanMenuItems(bottomMenuItems);

          debugPrint(
              "✅ Bottom menu items parsed successfully: ${bottomMenuItems.length} items");

          // Ensure current index is valid
          if (_currentIndex >= bottomMenuItems.length) {
            _currentIndex = 0;
          }

          // Set bottom menu as enabled since parsing succeeded
          setState(() {
            isBottomMenu = true;
          });

          // 🔧 FIX: Pre-build icons to prevent flickering
          _prebuildIcons();
        } catch (e) {
          debugPrint("❌ Error parsing bottom menu items: $e");
          debugPrint("🚫 Bottom menu hidden due to parsing error");

          // Hide bottom menu instead of using fallback items
          setState(() {
            isBottomMenu = false;
          });
        }
      } else {
        debugPrint("ℹ️ No bottom menu items provided");
        setState(() {
          isBottomMenu = false;
        });
      }

      // Listen to connectivity changes using our service
      ConnectivityService().connectivityStream.listen((isOnline) {
        if (mounted) {
          setState(() {
            hasInternet = isOnline;
          });
          debugPrint('🌐 MainHome connectivity stream update: $isOnline');
        }
      });

      _checkInternetConnection();

      // Add a timeout to prevent getting stuck on loading screen
      Future.delayed(Duration(seconds: 5), () {
        if (mounted && hasInternet == null) {
          debugPrint(
              '⚠️ Connectivity timeout reached, forcing online status for better UX');
          setState(() {
            hasInternet = true;
          });
        }
      });

      if (!kIsWeb &&
          [TargetPlatform.android, TargetPlatform.iOS]
              .contains(defaultTargetPlatform) &&
          EnvConfig.isPulldown) {
        pullToRefreshController = PullToRefreshController(
          settings: PullToRefreshSettings(
            color: Colors.blue,
          ),
          onRefresh: () async {
            if (Platform.isAndroid) {
              webViewController?.reload();
            } else if (Platform.isIOS) {
              webViewController?.loadUrl(
                urlRequest: URLRequest(url: WebUri(widget.webUrl)),
              );
            }
          },
        );
      } else {
        pullToRefreshController = null;
      }

      Uri parsedUri = Uri.parse(widget.webUrl);
      myDomain = parsedUri.host;
      if (myDomain.startsWith('www.')) {
        myDomain = myDomain.substring(4);
      }

      debugPrint("✅ MainHome initialization completed successfully");
    } catch (e, stackTrace) {
      debugPrint("❌ Error in MainHome initState: $e");
      debugPrint("Stack trace: $stackTrace");
      // Continue with basic functionality even if initialization fails
    }
  }

  /// ✅ Navigation from notification
  void _handleNotificationNavigation(RemoteMessage message) {
    final internalUrl = message.data['url'];
    if (internalUrl != null && webViewController != null) {
      webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(internalUrl ?? widget.webUrl)),
      );
    }
  }

  /// ✅ Setup push notification logic
  void setupFirebaseMessaging() async {
    try {
      // Check if Firebase is available
      if (!ConditionalFirebaseService.isFirebaseAvailableSafe) {
        debugPrint("⚠️ Firebase not available, skipping messaging setup");
        return;
      }

      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        await messaging.subscribeToTopic('all_users');
        // Platform-specific topics
        if (Platform.isAndroid) {
          await messaging.subscribeToTopic('android_users');
        } else if (Platform.isIOS) {
          await messaging.subscribeToTopic('ios_users');
        }
      } else {
        if (kDebugMode) {
          print("Notification permission not granted.");
        }
      }

      // ✅ Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        await _showLocalNotification(message);
        _handleNotificationNavigation(message);
      });

      // ✅ Handle background tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint("📲 Opened from background tap: ${message.data}");
        _handleNotificationNavigation(message);
      });
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error during Firebase Messaging setup: $e");
      }
    }
  }

  /// ✅ Local push with optional image
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      final android = notification?.android;
      final imageUrl = notification?.android?.imageUrl ?? message.data['image'];

      if (notification == null) {
        if (kDebugMode) {
          print("❌ Notification is null");
        }
        return;
      }

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'default_channel',
        'Default',
        channelDescription: 'Default notification channel',
        importance: Importance.max,
        priority: Priority.high,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction('id_1', 'View'),
          AndroidNotificationAction('id_2', 'Dismiss'),
        ],
      );

      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          final http.Response response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode != 200) {
            throw Exception('Failed to download image: ${response.statusCode}');
          }

          final tempDir = await getTemporaryDirectory();
          final filePath = '${tempDir.path}/notif_image.jpg';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          androidDetails = AndroidNotificationDetails(
            'default_channel',
            'Default',
            channelDescription: 'Default notification channel',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            icon: '@mipmap/ic_launcher',
            styleInformation: BigPictureStyleInformation(
              FilePathAndroidBitmap(filePath),
              largeIcon: FilePathAndroidBitmap(filePath),
              contentTitle: '<b>${notification.title}</b>',
              summaryText: notification.body,
              htmlFormatContentTitle: true,
              htmlFormatSummaryText: true,
            ),
          );
        } catch (e) {
          if (kDebugMode) {
            print('❌ Failed to load notification image: $e');
          }
        }
      }

      final DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        attachments:
            imageUrl != null ? [DarwinNotificationAttachment(imageUrl)] : null,
      );

      NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        platformDetails,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error showing local notification: $e');
      }
    }
  }

  /// ✅ Connectivity
  Future<void> _checkInternetConnection() async {
    try {
      // Use our improved connectivity service
      final connectivityService = ConnectivityService();
      final isOnline = await connectivityService.checkConnectivity();

      if (mounted) {
        setState(() {
          hasInternet = isOnline;
        });
        debugPrint('🌐 MainHome connectivity check: $isOnline');
      }
    } catch (e) {
      debugPrint('❌ Error checking connectivity in MainHome: $e');
      // Default to online for better UX
      if (mounted) {
        setState(() {
          hasInternet = true;
        });
      }
    }
  }

  /// ✅ Back button double-press exit
  Future<bool> _onBackPressed() async {
    if (webViewController != null) {
      bool canGoBack = await webViewController!.canGoBack();
      if (canGoBack) {
        await webViewController!.goBack();
        return false; // Don't exit app
      }
    }

    DateTime now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > Duration(seconds: 2)) {
      _lastBackPressed = now;
      Fluttertoast.showToast(
        msg: "Press back again to exit",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
      );
      return false;
    }

    return true; // Exit app
  }

  bool isLoading = true;
  bool hasError = false;
  Timer? _loadingTimeout;
  TextStyle _getMenuTextStyle(bool isActive) {
    return GoogleFonts.getFont(
      EnvConfig.bottommenuFont,
      fontSize: EnvConfig.bottommenuFontSize,
      fontWeight:
          EnvConfig.bottommenuFontBold ? FontWeight.bold : FontWeight.normal,
      fontStyle:
          EnvConfig.bottommenuFontItalic ? FontStyle.italic : FontStyle.normal,
      color: isActive
          ? _parseHexColor(widget.activeTabColor)
          : _parseHexColor(widget.textColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for boundary constraints
    _screenSize = MediaQuery.of(context).size;

    // Set initial position if not already set
    if (_dragPosition.dx == 16 && _dragPosition.dy == 300) {
      _setInitialChatPosition();
    }

    // Ensure chat icon is within bounds
    _ensureChatIconInBounds();

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onBackPressed();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Builder(
                builder: (context) {
                  if (hasInternet == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (hasInternet == false) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            '📴 No Internet Connection',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text('Please check your connection and try again'),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _checkInternetConnection(),
                            child: Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Stack(
                    children: [
                      if (!hasError)
                        InAppWebView(
                          key: webViewKey,
                          initialUrlRequest:
                              URLRequest(url: WebUri(widget.webUrl)),
                          initialSettings: settings,
                          pullToRefreshController: pullToRefreshController,
                          onWebViewCreated: (controller) {
                            debugPrint('🌐 WebView created successfully');
                            webViewController = controller;
                          },
                          shouldOverrideUrlLoading:
                              (controller, navigationAction) async {
                            var uri = navigationAction.request.url!;
                            var url = uri.toString();

                            if (kDebugMode) {
                              print("🔗 URL Loading: $url");
                              print(
                                  "   Same Domain: ${isUrlFromSameDomain(url)}");
                              print(
                                  "   Trusted Domain: ${isUrlFromTrustedDomain(url)}");
                              print("   OAuth URL: ${isOAuthUrl(url)}");
                            }

                            // Handle special scheme URLs (always allowed)
                            if (isSpecialSchemeUrl(url)) {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                                return NavigationActionPolicy.CANCEL;
                              }
                            }

                            // Handle URLs based on domain rules
                            if (isUrlFromSameDomain(url) ||
                                (EnvConfig.pushNotify &&
                                    isPushNotificationUrl(url))) {
                              // Allow navigation within the app for same domain or push notification URLs
                              return NavigationActionPolicy.ALLOW;
                            }

                            // Allow trusted domains regardless of IS_DOMAIN_URL setting
                            if (isUrlFromTrustedDomain(url)) {
                              // Keep trusted domains within the app for better user experience
                              return NavigationActionPolicy.ALLOW;
                            }

                            // Handle OAuth URLs - open in external browser to avoid Google's WebView restrictions
                            // Only for non-trusted domains
                            if (isOAuthUrl(url)) {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                                return NavigationActionPolicy.CANCEL;
                              }
                            }

                            // Check if external URLs are allowed for non-trusted domains
                            if (!EnvConfig.isDomainUrl) {
                              // IS_DOMAIN_URL is false - block non-trusted external URLs
                              if (kDebugMode) {
                                print(
                                    "🚫 External URL blocked (IS_DOMAIN_URL=false): $url");
                              }
                              return NavigationActionPolicy.CANCEL;
                            }

                            // IS_DOMAIN_URL is true - allow all other external URLs
                            // For all other external domains (when IS_DOMAIN_URL is true)
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                              return NavigationActionPolicy.CANCEL;
                            }

                            return NavigationActionPolicy.ALLOW;
                          },
                          onLoadStart: (controller, url) {
                            debugPrint('🌐 WebView loading started: $url');
                            setState(() {
                              this.url = url.toString();
                              urlController.text = this.url;
                              isLoading =
                                  true; // Set loading to true when page starts loading
                              hasError = false;
                            });

                            // Set a timeout for loading
                            _loadingTimeout?.cancel();
                            _loadingTimeout =
                                Timer(const Duration(seconds: 30), () {
                              if (mounted && isLoading) {
                                setState(() {
                                  hasError = true;
                                  isLoading = false;
                                });
                                if (kDebugMode) {
                                  print("⏰ Loading timeout reached for: $url");
                                }
                              }
                            });
                          },
                          onLoadStop: (controller, url) async {
                            pullToRefreshController?.endRefreshing();
                            _loadingTimeout?.cancel(); // Cancel timeout
                            setState(() {
                              this.url = url.toString();
                              urlController.text = this.url;
                              isLoading =
                                  false; // Set loading to false when page finishes loading
                              hasError = false;
                            });
                          },
                          onReceivedError:
                              (controller, request, errorResponse) {
                            pullToRefreshController?.endRefreshing();
                            if (kDebugMode) {
                              print(
                                  "❌ WebView Error: ${errorResponse?.description}");
                              print("🔗 Failed URL: ${request.url}");
                              print("📊 Error Code: ${errorResponse?.type}");
                            }
                            setState(() {
                              isLoading = false;
                              hasError = true;
                            });
                          },
                          onProgressChanged: (controller, progress) {
                            if (progress == 100) {
                              pullToRefreshController?.endRefreshing();
                            }
                            setState(() {
                              this.progress = progress / 100;
                              urlController.text = this.url;
                            });
                          },
                          onUpdateVisitedHistory: (controller, url, isReload) {
                            setState(() {
                              this.url = url.toString();
                              urlController.text = this.url;
                            });
                          },
                          onConsoleMessage: (controller, consoleMessage) {
                            print("Console Message: ${consoleMessage.message}");
                          },
                        ),

                      // Error handling
                      if (hasError)
                        Positioned.fill(
                          child: Container(
                            color: Colors.white,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.error_outline,
                                      size: 64, color: Colors.red),
                                  SizedBox(height: 16),
                                  Text(
                                    'Failed to load page',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),
                                  Text('Please check your internet connection'),
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        hasError = false;
                                        isLoading = true;
                                      });
                                      webViewController?.reload();
                                    },
                                    child: Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Loading Indicator
                      if (widget.isLoadIndicator && isLoading)
                        Positioned.fill(
                          child: Container(
                            color: Colors
                                .black26, // optional: semi-transparent overlay
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                      // // Loading Indicator
                      // if (widget.isLoadIndicator && isLoading)
                      //   const Center(child: CircularProgressIndicator()),

                      // Error Screen
                      if (hasError)
                        Container(
                          color: Colors.grey.shade50,
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
                                    'Failed to load page',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Unable to connect to ${Uri.parse(widget.webUrl).host}',
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
                                        onPressed: () {
                                          setState(() {
                                            hasError = false;
                                            isLoading = true;
                                          });
                                          webViewController?.loadUrl(
                                            urlRequest: URLRequest(
                                              url: WebUri(widget.webUrl),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF667eea),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 24,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Retry'),
                                      ),
                                      const SizedBox(width: 12),
                                      TextButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            hasError = false;
                                            isLoading = true;
                                          });
                                          // Try loading a fallback URL
                                          webViewController?.loadUrl(
                                            urlRequest: URLRequest(
                                              url: WebUri(
                                                  'https://www.google.com'),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.grey.shade600,
                                        ),
                                        icon: const Icon(Icons.open_in_new),
                                        label: const Text('Try Google'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Check your internet connection and try again',
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

                      // Chat Icon
                      if (EnvConfig.isChatbot)
                        Positioned(
                          left: _dragPosition.dx,
                          top: _dragPosition.dy,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                // Calculate new position
                                Offset newPosition =
                                    _dragPosition + details.delta;

                                // Apply boundary constraints
                                double maxX =
                                    _screenSize.width - _chatIconSize - 16;
                                double minX = 16;
                                double maxY = _screenSize.height -
                                    _chatIconSize -
                                    _bottomMenuHeight -
                                    16;
                                double minY =
                                    MediaQuery.of(context).padding.top + 16;

                                // Constrain position within bounds
                                newPosition = Offset(
                                  newPosition.dx.clamp(minX, maxX),
                                  newPosition.dy.clamp(minY, maxY),
                                );

                                _dragPosition = newPosition;
                              });
                            },
                            onPanEnd: (details) {
                              // Snap to edges if close enough
                              setState(() {
                                double snapThreshold = 32.0;
                                double leftEdge = 16.0;
                                double rightEdge =
                                    _screenSize.width - _chatIconSize - 16;

                                if (_dragPosition.dx <
                                    leftEdge + snapThreshold) {
                                  _dragPosition =
                                      Offset(leftEdge, _dragPosition.dy);
                                } else if (_dragPosition.dx >
                                    rightEdge - snapThreshold) {
                                  _dragPosition =
                                      Offset(rightEdge, _dragPosition.dy);
                                }

                                _ensureChatIconInBounds();
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: FloatingActionButton(
                                onPressed: () {
                                  setState(() {
                                    isChatVisible = !isChatVisible;
                                  });
                                },
                                backgroundColor: const Color(0xFF667eea),
                                child:
                                    const Icon(Icons.chat, color: Colors.white),
                              ),
                            ),
                          ),
                        ),

                      // Chat Widget
                      if (EnvConfig.isChatbot && isChatVisible)
                        Positioned.fill(
                          child: Container(
                            margin: EdgeInsets.only(
                              top: MediaQuery.of(context).padding.top + 16,
                              left: 16,
                              right: 16,
                              bottom: widget.isBottomMenu ? 96 : 16,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: ChatWidget(
                                webViewController: webViewController!,
                                currentUrl: InitialCurrentURL,
                                onVisibilityChanged: (visible) {
                                  setState(() {
                                    isChatVisible = visible;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        bottomNavigationBar: isBottomMenu && bottomMenuItems.isNotEmpty
            ? BottomNavigationBar(
                type: BottomNavigationBarType
                    .fixed, // Required for more than 3 items
                currentIndex:
                    _currentIndex < bottomMenuItems.length ? _currentIndex : 0,
                onTap: (index) {
                  // Ensure index is within bounds
                  if (index >= 0 && index < bottomMenuItems.length) {
                    // 🔧 FIX: Only call setState if index actually changed
                    if (_currentIndex != index) {
                      setState(() {
                        _currentIndex = index;
                      });
                    }

                    final item = bottomMenuItems[index];
                    final url = item['url'] as String?;
                    if (url != null && url.isNotEmpty) {
                      webViewController?.loadUrl(
                        urlRequest: URLRequest(url: WebUri(url)),
                      );
                    }
                  } else {
                    debugPrint(
                        "⚠️ Invalid bottom menu index: $index (max: ${bottomMenuItems.length - 1})");
                  }
                },
                items: bottomMenuItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return BottomNavigationBarItem(
                    icon: _getCachedIcon(item, _currentIndex == index),
                    label: item['label'] as String? ?? '',
                  );
                }).toList(),
                backgroundColor: _parseHexColor(widget.backgroundColor),
                selectedLabelStyle: _getMenuTextStyle(true),
                unselectedLabelStyle: _getMenuTextStyle(false),
                selectedItemColor: _parseHexColor(widget.activeTabColor),
                unselectedItemColor: _parseHexColor(widget.iconColor),
              )
            : null,
      ),
    );
  }

  /// ✅ Update all Uri instances to WebUri
  void _handleUrl(String url) {
    if (url.startsWith('tel:') ||
        url.startsWith('mailto:') ||
        url.startsWith('whatsapp:') ||
        url.startsWith('sms:')) {
      launchUrl(WebUri(url));
    } else {
      webViewController?.loadUrl(
        urlRequest: URLRequest(url: WebUri(url)),
      );
    }
  }

  void _loadInitialUrl() {
    webViewController?.loadUrl(
      urlRequest: URLRequest(url: WebUri(_pendingInitialUrl ?? widget.webUrl)),
    );
  }

  // Add missing getters
  bool get isCameraEnabled => EnvConfig.isCamera;
  bool get isLocationEnabled => EnvConfig.isLocation;
  bool get isMicEnabled => EnvConfig.isMic;
  bool get isContactEnabled => EnvConfig.isContact;
  bool get isCalendarEnabled => EnvConfig.isCalendar;
  bool get isNotificationEnabled => EnvConfig.isNotification;
  bool get isBiometricEnabled => EnvConfig.isBiometric;
  bool get isPullDown => EnvConfig.isPulldown;

  // Fix URI type mismatches
  WebUri _parseWebUri(String url) {
    return WebUri(url);
  }

  // Update URL parsing methods
  void _loadUrl(String url) {
    webViewController?.loadUrl(urlRequest: URLRequest(url: _parseWebUri(url)));
  }

  bool isUrlFromSameDomain(String url) {
    try {
      Uri uri = Uri.parse(url);
      String domain = uri.host;
      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }
      return domain == myDomain;
    } catch (e) {
      return false;
    }
  }

  bool isUrlFromTrustedDomain(String url) {
    try {
      Uri uri = Uri.parse(url);
      String domain = uri.host;
      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }
      return trustedDomains
          .any((gateway) => domain.endsWith(gateway['domain']!));
    } catch (e) {
      return false;
    }
  }

  bool isSpecialSchemeUrl(String url) {
    return url.startsWith('tel:') ||
        url.startsWith('mailto:') ||
        url.startsWith('whatsapp:') ||
        url.startsWith('sms:');
  }

  bool isPushNotificationUrl(String url) {
    if (!EnvConfig.pushNotify) return false;
    try {
      Uri uri = Uri.parse(url);
      String domain = uri.host;
      if (domain.startsWith('www.')) {
        domain = domain.substring(4);
      }
      return domain == myDomain;
    } catch (e) {
      return false;
    }
  }

  bool isOAuthUrl(String url) {
    try {
      Uri uri = Uri.parse(url);
      String path = uri.path.toLowerCase();
      String query = uri.query.toLowerCase();

      // First check if this is a trusted domain - if so, don't treat as OAuth
      if (isUrlFromTrustedDomain(url)) {
        return false;
      }

      // Check for OAuth-related paths and parameters (only for external domains)
      return path.contains('login') ||
          path.contains('auth') ||
          path.contains('oauth') ||
          path.contains('signin') ||
          path.contains('sign-in') ||
          query.contains('social=') ||
          query.contains('oauth=') ||
          query.contains('auth=') ||
          uri.host.contains('accounts.google.com') ||
          uri.host.contains('facebook.com') ||
          uri.host.contains('appleid.apple.com');
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _loadingTimeout?.cancel();
    // 🔧 FIX: Clean up icon cache to prevent memory leaks
    _iconCache.clear();
    _activeIconCache.clear();
    super.dispose();
  }
}

List<Map<String, dynamic>> parseBottomMenuItems(String raw) {
  try {
    return List<Map<String, dynamic>>.from(json.decode(raw));
  } catch (e) {
    debugPrint("❌ Failed to parse BOTTOMMENU_ITEMS: $e");
    return [];
  }
}

List<Map<String, dynamic>> convertIcons(List<Map<String, dynamic>> items) {
  return items.map((item) {
    return {
      "label": item["label"],
      "icon": _getIconByName(item["icon"]),
      "url": item["url"],
    };
  }).toList();
}

IconData _getIconByName(String? name) {
  if (name == null || name.trim().isEmpty) {
    return Icons.apps; // Default icon
  }

  final lowerName = name.toLowerCase().trim();

  final iconMap = {
    'ac_unit': Icons.ac_unit,
    'access_alarm': Icons.access_alarm,
    'access_time': Icons.access_time,
    'account_balance': Icons.account_balance,
    'account_circle': Icons.account_circle,
    'add': Icons.add,
    'add_a_photo': Icons.add_a_photo,
    'alarm': Icons.alarm,
    'android': Icons.android,
    'announcement': Icons.announcement,
    'apps': Icons.apps,
    'archive': Icons.archive,
    'arrow_back': Icons.arrow_back,
    'arrow_downward': Icons.arrow_downward,
    'arrow_forward': Icons.arrow_forward,
    'arrow_upward': Icons.arrow_upward,
    'aspect_ratio': Icons.aspect_ratio,
    'assessment': Icons.assessment,
    'assignment': Icons.assignment,
    'autorenew': Icons.autorenew,
    'backup': Icons.backup,
    'battery_alert': Icons.battery_alert,
    'battery_charging_full': Icons.battery_charging_full,
    'beach_access': Icons.beach_access,
    'block': Icons.block,
    'bluetooth': Icons.bluetooth,
    'book': Icons.book,
    'bookmark': Icons.bookmark,
    'bug_report': Icons.bug_report,
    'build': Icons.build,
    'calendar_today': Icons.calendar_today,
    'camera': Icons.camera,
    'card_giftcard': Icons.card_giftcard,
    'chat': Icons.chat,
    'check': Icons.check,
    'chevron_left': Icons.chevron_left,
    'chevron_right': Icons.chevron_right,
    'close': Icons.close,
    'cloud': Icons.cloud,
    'code': Icons.code,
    'comment': Icons.comment,
    'compare': Icons.compare,
    'computer': Icons.computer,
    'content_copy': Icons.content_copy,
    'create': Icons.create,
    'delete': Icons.delete,
    'desktop_mac': Icons.desktop_mac,
    'done': Icons.done,
    'download': Icons.download,
    'drag_handle': Icons.drag_handle,
    'edit': Icons.edit,
    'email': Icons.email,
    'error': Icons.error,
    'event': Icons.event,
    'explore': Icons.explore,
    'face': Icons.face,
    'favorite': Icons.favorite,
    'feedback': Icons.feedback,
    'file_copy': Icons.file_copy,
    'filter_list': Icons.filter_list,
    'flag': Icons.flag,
    'folder': Icons.folder,
    'format_align_left': Icons.format_align_left,
    'format_bold': Icons.format_bold,
    'forward': Icons.forward,
    'fullscreen': Icons.fullscreen,
    'gps_fixed': Icons.gps_fixed,
    'grade': Icons.grade,
    'group': Icons.group,
    'help': Icons.help,
    'highlight': Icons.highlight,
    'home': Icons.home,
    'hourglass_empty': Icons.hourglass_empty,
    'http': Icons.http,
    'https': Icons.https,
    'image': Icons.image,
    'info': Icons.info,
    'input': Icons.input,
    'invert_colors': Icons.invert_colors,
    'keyboard': Icons.keyboard,
    'label': Icons.label,
    'language': Icons.language,
    'launch': Icons.launch,
    'link': Icons.link,
    'list': Icons.list,
    'lock': Icons.lock,
    'map': Icons.map,
    'menu': Icons.menu,
    'message': Icons.message,
    'mic': Icons.mic,
    'mood': Icons.mood,
    'more_horiz': Icons.more_horiz,
    'more_vert': Icons.more_vert,
    'navigation': Icons.navigation,
    'notifications': Icons.notifications,
    'offline_bolt': Icons.offline_bolt,
    'palette': Icons.palette,
    'person': Icons.person,
    'phone': Icons.phone,
    'photo': Icons.photo,
    'place': Icons.place,
    'play_arrow': Icons.play_arrow,
    'print': Icons.print,
    'refresh': Icons.refresh,
    'remove': Icons.remove,
    'reorder': Icons.reorder,
    'reply': Icons.reply,
    'report': Icons.report,
    'save': Icons.save,
    'schedule': Icons.schedule,
    'school': Icons.school,
    'search': Icons.search,
    'security': Icons.security,
    'send': Icons.send,
    'settings': Icons.settings,
    'share': Icons.share,
    'shopping_cart': Icons.shopping_cart,
    'star': Icons.star,
    'store': Icons.store,
    'sync': Icons.sync,
    'thumb_up': Icons.thumb_up,
    'title': Icons.title,
    'translate': Icons.translate,
    'trending_up': Icons.trending_up,
    'update': Icons.update,
    'verified_user': Icons.verified_user,
    'visibility': Icons.visibility,
    'volume_up': Icons.volume_up,
    'warning': Icons.warning,
    'watch': Icons.watch,
    'wifi': Icons.wifi,
    'about': Icons.info,
    'contact': Icons.contact_page,
    'shop': Icons.storefront,
    'cart': Icons.shopping_cart_outlined,
    'shoppingcart': Icons.shopping_cart,
    'orders': Icons.receipt_long,
    'order': Icons.receipt_long,
    'wishlist': Icons.favorite,
    'like': Icons.favorite,
    'category': Icons.category,
    'account': Icons.account_circle,
    'profile': Icons.account_circle,
    'offer': Icons.local_offer,
    'discount': Icons.local_offer,
    'services': Icons.miscellaneous_services,
    'blogs': Icons.article,
    'blog': Icons.article,
    'company': Icons.business,
    'aboutus': Icons.business,
    'more': Icons.more_horiz,
    'home_outline': Icons.home_outlined,
    'search_outline': Icons.search_outlined,
    'person_outline': Icons.person_outline,
    'settings_outline': Icons.settings_outlined,
    'favorite_outline': Icons.favorite_outline,
    'info_outline': Icons.info_outline,
    'help_outline': Icons.help_outline,
    'lock_outline': Icons.lock_outline,
    'visibility_outline': Icons.visibility_outlined,
    'calendar_today_outline': Icons.calendar_today_outlined,
    'check_circle_outline': Icons.check_circle_outline,
    'delete_outline': Icons.delete_outline,
    'edit_outlined': Icons.edit_outlined,
    'language_outlined': Icons.language_outlined,
    'star_outline': Icons.star_outline,
    'map_outlined': Icons.map_outlined,
    'menu_outlined': Icons.menu_outlined,
    'notifications_none': Icons.notifications_none,
    'camera_outlined': Icons.camera_outlined,
    'email_outlined': Icons.email_outlined,
    'shopping_cart_outlined': Icons.shopping_cart_outlined,
    'account_circle_outlined': Icons.account_circle_outlined,
    'calendar_today_outlined': Icons.calendar_today_outlined,
    'home_outlined': Icons.home_outlined,
    'search_outlined': Icons.search_outlined,
    'visibility_outlined': Icons.visibility_outlined,
  };

  final icon = iconMap[lowerName];
  if (icon == null) {
    if (kDebugMode) {
      print("🚫 Icon not found for name: $name");
    }
  }
  return icon ?? Icons.error_outline;
}
