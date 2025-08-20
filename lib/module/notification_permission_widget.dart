import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/notification_service.dart';
import '../config/env_config.dart';

/// 🔔 iOS Notification Permission Widget
/// This widget ensures notification permissions are requested with user interaction
/// which is required for iOS to show the permission dialog
class NotificationPermissionWidget extends StatefulWidget {
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;
  final Widget? child;

  const NotificationPermissionWidget({
    super.key,
    this.onPermissionGranted,
    this.onPermissionDenied,
    this.child,
  });

  @override
  State<NotificationPermissionWidget> createState() =>
      _NotificationPermissionWidgetState();
}

class _NotificationPermissionWidgetState
    extends State<NotificationPermissionWidget> {
  bool _hasPermission = false;
  bool _isRequesting = false;
  bool _hasShownDialog = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionStatus();
  }

  /// Check current notification permission status
  Future<void> _checkPermissionStatus() async {
    try {
      // Check if notifications are enabled in config
      if (!EnvConfig.pushNotify) {
        debugPrint(
            '🔔 Notifications disabled in config, skipping permission check');
        return;
      }

      // For iOS, we need to check the actual permission status
      if (Platform.isIOS) {
        final FlutterLocalNotificationsPlugin plugin =
            FlutterLocalNotificationsPlugin();
        final IOSFlutterLocalNotificationsPlugin? iosPlugin =
            plugin.resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();

        if (iosPlugin != null) {
          final bool? hasPermission = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
            critical: true,
            provisional: false,
          );

          setState(() {
            _hasPermission = hasPermission ?? false;
          });

          debugPrint('🍎 iOS notification permission status: $_hasPermission');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking notification permission status: $e');
    }
  }

  /// Request notification permissions with user interaction
  Future<void> _requestNotificationPermissions() async {
    if (_isRequesting) return;

    setState(() {
      _isRequesting = true;
    });

    try {
      debugPrint(
          '🔔 Requesting notification permissions with user interaction...');

      // Request permissions
      final bool granted = await requestNotificationPermissions();

      setState(() {
        _hasPermission = granted;
        _isRequesting = false;
      });

      if (granted) {
        debugPrint('✅ Notification permissions granted');
        widget.onPermissionGranted?.call();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Notification permissions granted!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        debugPrint('❌ Notification permissions denied');
        widget.onPermissionDenied?.call();

        // Show denied message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  '❌ Notification permissions denied. You can enable them in Settings.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: _openAppSettings,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error requesting notification permissions: $e');
      setState(() {
        _isRequesting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error requesting permissions: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Open app settings for manual permission enable
  void _openAppSettings() {
    try {
      // This will open the app's settings page where users can enable notifications
      // Note: This requires the app_settings package or similar
      debugPrint('🔧 Opening app settings...');
      // You can implement this using app_settings package
    } catch (e) {
      debugPrint('❌ Error opening app settings: $e');
    }
  }

  /// Show permission request dialog
  void _showPermissionDialog() {
    if (_hasShownDialog) return;

    setState(() {
      _hasShownDialog = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.notifications_active, color: Colors.blue),
              SizedBox(width: 8),
              Text('Enable Notifications'),
            ],
          ),
          content: const Text(
            'This app would like to send you notifications to keep you updated with important information. '
            'You can change this later in Settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _hasShownDialog = false;
                });
                widget.onPermissionDenied?.call();
              },
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _hasShownDialog = false;
                });
                _requestNotificationPermissions();
              },
              child: const Text('Enable'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // If notifications are disabled in config, just return the child
    if (!EnvConfig.pushNotify) {
      return widget.child ?? const SizedBox.shrink();
    }

    // If we have permission, just return the child
    if (_hasPermission) {
      return widget.child ?? const SizedBox.shrink();
    }

    // If we haven't shown the dialog yet, show it automatically
    if (!_hasShownDialog) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPermissionDialog();
      });
    }

    // Show a banner asking for permission
    return Column(
      children: [
        if (widget.child != null) widget.child!,
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Enable Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Stay updated with important information by enabling notifications.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isRequesting ? null : () => _showPermissionDialog(),
                      child: _isRequesting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.0),
                            )
                          : const Text('Enable'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: _isRequesting
                          ? null
                          : () {
                              setState(() {
                                _hasShownDialog = true;
                              });
                              widget.onPermissionDenied?.call();
                            },
                      child: const Text('Not Now'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
