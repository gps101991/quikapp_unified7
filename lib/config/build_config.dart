import 'package:flutter/foundation.dart';

/// 🚀 Build Configuration for Codemagic Workflows
///
/// This class provides build-time configuration and optimizations
/// that are automatically applied based on the current workflow.
class BuildConfig {
  // Private constructor to prevent instantiation
  BuildConfig._();

  // ===== WORKFLOW CONFIGURATION =====

  /// Current workflow ID from Codemagic
  static const String workflowId = String.fromEnvironment(
    'WORKFLOW_ID',
    defaultValue: 'development',
  );

  /// Build ID from Codemagic
  static const String buildId = String.fromEnvironment(
    'CM_BUILD_ID',
    defaultValue: '',
  );

  /// Branch name
  static const String branch = String.fromEnvironment(
    'BRANCH',
    defaultValue: 'main',
  );

  /// Commit hash
  static const String commitHash = String.fromEnvironment(
    'CM_COMMIT',
    defaultValue: '',
  );

  /// Project ID
  static const String projectId = String.fromEnvironment(
    'PROJECT_ID',
    defaultValue: '',
  );

  // ===== BUILD OPTIMIZATIONS =====

  /// Enable debug features (development only)
  static bool get enableDebugFeatures => kDebugMode;

  /// Enable performance profiling
  static bool get enablePerformanceProfiling => kDebugMode;

  /// Enable detailed logging
  static bool get enableDetailedLogging => kDebugMode;

  /// Enable crash reporting
  static bool get enableCrashReporting => !kDebugMode;

  /// Enable analytics
  static bool get enableAnalytics => !kDebugMode;

  // ===== WORKFLOW-SPECIFIC CONFIGURATIONS =====

  /// Check if running in iOS workflow
  static bool get isIosWorkflow => workflowId == 'ios-workflow';

  /// Check if running in Android workflow
  static bool get isAndroidWorkflow => workflowId == 'android-publish';

  /// Check if running in combined workflow
  static bool get isCombinedWorkflow => workflowId == 'combined';

  /// Check if running in development
  static bool get isDevelopment => workflowId == 'development';

  // ===== PLATFORM-SPECIFIC OPTIMIZATIONS =====

  /// Get platform-specific build optimizations
  static Map<String, dynamic> get platformOptimizations {
    if (kIsWeb) {
      return {
        'enableWebOptimizations': true,
        'enableServiceWorker': !kDebugMode,
        'enablePWA': !kDebugMode,
        'enableWebAssembly': true,
      };
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return {
        'enableAndroidOptimizations': true,
        'enableProguard': !kDebugMode,
        'enableR8': !kDebugMode,
        'enableMultidex': true,
        'enableVectorDrawables': true,
      };
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return {
        'enableIosOptimizations': true,
        'enableBitcode': false,
        'enableSwiftOptimization': true,
        'enableMetal': true,
        'enableARKit': false, // Enable if needed
      };
    }
    return {
      'enableGenericOptimizations': true,
    };
  }

  // ===== FEATURE FLAGS =====

  /// Get feature flags based on workflow
  static Map<String, bool> get featureFlags {
    final baseFlags = {
      'pushNotifications': true,
      'firebase': true,
      'analytics': !kDebugMode,
      'crashReporting': !kDebugMode,
      'performanceMonitoring': !kDebugMode,
      'remoteConfig': !kDebugMode,
    };

    // Workflow-specific feature overrides
    if (isIosWorkflow) {
      baseFlags.addAll({
        'iosSpecificFeatures': true,
        'appStoreConnect': true,
        'testFlight': true,
      });
    }

    if (isAndroidWorkflow) {
      baseFlags.addAll({
        'androidSpecificFeatures': true,
        'playStore': true,
        'firebaseAppDistribution': true,
      });
    }

    if (isCombinedWorkflow) {
      baseFlags.addAll({
        'crossPlatformFeatures': true,
        'unifiedBuild': true,
      });
    }

    return baseFlags;
  }

  // ===== BUILD INFORMATION =====

  /// Get comprehensive build information
  static Map<String, dynamic> get buildInfo => {
        'workflowId': workflowId,
        'buildId': buildId,
        'branch': branch,
        'commitHash': commitHash,
        'projectId': projectId,
        'isDebug': kDebugMode,
        'isProfile': kProfileMode,
        'isRelease': kReleaseMode,
        'targetPlatform': defaultTargetPlatform.toString(),
        'featureFlags': featureFlags,
        'platformOptimizations': platformOptimizations,
      };

  /// Get build summary for logging
  static String get buildSummary => '''
🚀 Build Configuration Summary:
   Workflow: $workflowId
   Build ID: $buildId
   Branch: $branch
   Commit: $commitHash
   Platform: ${defaultTargetPlatform.toString()}
   Mode: ${kDebugMode ? 'Debug' : kProfileMode ? 'Profile' : 'Release'}
   Features: ${featureFlags.entries.where((e) => e.value).map((e) => e.key).join(', ')}
''';

  // ===== VALIDATION =====

  /// Validate build configuration
  static List<String> get validationErrors {
    final errors = <String>[];

    if (workflowId.isEmpty) {
      errors.add('WORKFLOW_ID is required');
    }

    if (buildId.isEmpty && !isDevelopment) {
      errors.add('CM_BUILD_ID is required for production builds');
    }

    if (branch.isEmpty) {
      errors.add('BRANCH is required');
    }

    return errors;
  }

  /// Check if build configuration is valid
  static bool get isValid => validationErrors.isEmpty;

  // ===== UTILITY METHODS =====

  /// Get environment-specific configuration
  static Map<String, dynamic> getEnvironmentConfig(String environment) {
    switch (environment.toLowerCase()) {
      case 'development':
        return {
          'enableDebugFeatures': true,
          'enableDetailedLogging': true,
          'enablePerformanceProfiling': true,
          'enableCrashReporting': false,
          'enableAnalytics': false,
        };
      case 'staging':
        return {
          'enableDebugFeatures': false,
          'enableDetailedLogging': true,
          'enablePerformanceProfiling': false,
          'enableCrashReporting': true,
          'enableAnalytics': true,
        };
      case 'production':
        return {
          'enableDebugFeatures': false,
          'enableDetailedLogging': false,
          'enablePerformanceProfiling': false,
          'enableCrashReporting': true,
          'enableAnalytics': true,
        };
      default:
        return {
          'enableDebugFeatures': kDebugMode,
          'enableDetailedLogging': kDebugMode,
          'enablePerformanceProfiling': kDebugMode,
          'enableCrashReporting': !kDebugMode,
          'enableAnalytics': !kDebugMode,
        };
    }
  }

  /// Check if a specific feature is enabled
  static bool isFeatureEnabled(String feature) {
    return featureFlags[feature] ?? false;
  }

  /// Get workflow-specific configuration
  static Map<String, dynamic> getWorkflowConfig() {
    switch (workflowId) {
      case 'ios-workflow':
        return {
          'platform': 'ios',
          'buildType': 'release',
          'codeSigning': true,
          'provisioning': true,
          'appStoreUpload': true,
          'testFlight': true,
        };
      case 'android-publish':
        return {
          'platform': 'android',
          'buildType': 'release',
          'codeSigning': true,
          'keystore': true,
          'playStoreUpload': true,
          'firebaseDistribution': true,
        };
      case 'combined':
        return {
          'platform': 'universal',
          'buildType': 'release',
          'codeSigning': true,
          'crossPlatform': true,
          'unifiedBuild': true,
        };
      default:
        return {
          'platform': 'unknown',
          'buildType': 'development',
          'codeSigning': false,
        };
    }
  }
}
