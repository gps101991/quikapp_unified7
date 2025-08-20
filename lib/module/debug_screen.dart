import 'package:flutter/material.dart';
import '../config/env_config.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Information'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Environment Configuration',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Core App Info
            _buildInfoCard('App Name', EnvConfig.appName),
            _buildInfoCard('Version Name', EnvConfig.versionName),
            _buildInfoCard('Version Code', EnvConfig.versionCode.toString()),
            _buildInfoCard('Package Name', EnvConfig.packageName),
            _buildInfoCard('Workflow ID', EnvConfig.workflowId),

            const SizedBox(height: 16),
            const Text(
              'Feature Flags',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            _buildInfoCard('Push Notify', EnvConfig.pushNotify.toString()),
            _buildInfoCard('Chat Bot', EnvConfig.isChatbot.toString()),
            _buildInfoCard('Splash Screen', EnvConfig.isSplash.toString()),
            _buildInfoCard('Bottom Menu', EnvConfig.isBottommenu.toString()),
            _buildInfoCard(
              'Load Indicator',
              EnvConfig.isLoadIndicator.toString(),
            ),

            const SizedBox(height: 16),
            const Text(
              'Configuration',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            _buildInfoCard('Web URL', EnvConfig.webUrl),
            _buildInfoCard('Logo URL', EnvConfig.logoUrl),
            _buildInfoCard('Splash URL', EnvConfig.splashUrl),
            _buildInfoCard('Splash Background', EnvConfig.splashBg),

            const SizedBox(height: 16),
            const Text(
              'Firebase Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            _buildInfoCard(
              'Firebase Required',
              EnvConfig.isFirebaseRequired.toString(),
            ),
            _buildInfoCard(
              'Firebase Config Available',
              EnvConfig.hasFirebaseConfig.toString(),
            ),
            _buildInfoCard(
              'Should Initialize Firebase',
              EnvConfig.shouldInitializeFirebase.toString(),
            ),

            const SizedBox(height: 16),
            const Text(
              'Permissions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            _buildInfoCard('Camera', EnvConfig.isCamera.toString()),
            _buildInfoCard('Location', EnvConfig.isLocation.toString()),
            _buildInfoCard('Microphone', EnvConfig.isMic.toString()),
            _buildInfoCard('Notification', EnvConfig.isNotification.toString()),
            _buildInfoCard('Contact', EnvConfig.isContact.toString()),
            _buildInfoCard('Biometric', EnvConfig.isBiometric.toString()),
            _buildInfoCard('Calendar', EnvConfig.isCalendar.toString()),
            _buildInfoCard('Storage', EnvConfig.isStorage.toString()),

            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close Debug Screen'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value.isEmpty ? 'Not Set' : value,
                style: TextStyle(
                  color: value.isEmpty ? Colors.grey : Colors.black87,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
