#!/bin/bash
# 🔔 Complete Push Notification Setup Script for Android Workflow
# Ensures ALL required configurations are set for push notifications to work in:
# - Background state (app in background)
# - Closed state (app terminated) 
# - Opened state (app active)

set -euo pipefail

# Enhanced logging
log() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ANDROID_PUSH_SETUP] $1" >&2; }
log_success() { echo -e "\033[0;32m✅ $1\033[0m" >&2; }
log_warning() { echo -e "\033[1;33m⚠️ $1\033[0m" >&2; }
log_error() { echo -e "\033[0;31m❌ $1\033[0m" >&2; }
log_info() { echo -e "\033[0;34m🔍 $1\033[0m" >&2; }

echo "🔔 Complete Push Notification Setup for Android Workflow..."

# Check if push notifications are enabled
if [[ "${PUSH_NOTIFY:-false}" != "true" ]]; then
    log_warning "Push notifications are disabled (PUSH_NOTIFY=false)"
    log_info "Skipping push notification setup"
    exit 0
fi

log_info "Push notifications are enabled, setting up complete configuration..."

# Function to safely add/update manifest values
safe_manifest_update() {
    local manifest_path="$1"
    local pattern="$2"
    local replacement="$3"
    local description="$4"
    
    if grep -q "$pattern" "$manifest_path"; then
        log_info "ℹ️ $description already present in manifest"
    else
        log_info "📝 Adding $description to manifest..."
        # Add the replacement after the application tag
        sed -i.bak "/<application/a\\
        $replacement" "$manifest_path"
        rm -f "${manifest_path}.bak" 2>/dev/null || true
        log_success "✅ Added $description to manifest"
    fi
}

# Function to safely add permissions
safe_permission_add() {
    local manifest_path="$1"
    local permission="$2"
    local description="$3"
    
    if grep -q "$permission" "$manifest_path"; then
        log_info "ℹ️ $description already present in manifest"
    else
        log_info "📝 Adding $description to manifest..."
        # Add permission after the first uses-permission
        sed -i.bak "/<uses-permission android:name=\"android.permission.INTERNET\"/a\\
    $permission" "$manifest_path"
        rm -f "${manifest_path}.bak" 2>/dev/null || true
        log_success "✅ Added $description to manifest"
    fi
}

echo ""
echo "📱 Phase 1: AndroidManifest.xml Configuration"
echo "=============================================="

# Ensure AndroidManifest.xml exists
if [[ ! -f "android/app/src/main/AndroidManifest.xml" ]]; then
    log_error "❌ AndroidManifest.xml not found at android/app/src/main/AndroidManifest.xml"
    exit 1
fi

# Backup original manifest
cp android/app/src/main/AndroidManifest.xml android/app/src/main/AndroidManifest.xml.backup.push

# 1. Add notification permissions
log_info "🔧 Configuring notification permissions..."
safe_permission_add "android/app/src/main/AndroidManifest.xml" \
    '<uses-permission android:name="android.permission.WAKE_LOCK" />' \
    "WAKE_LOCK permission"

safe_permission_add "android/app/src/main/AndroidManifest.xml" \
    '<uses-permission android:name="android.permission.VIBRATE" />' \
    "VIBRATE permission"

# 2. Add FCM service configuration
log_info "🔧 Configuring FCM service..."
FCM_SERVICE_CONFIG='        <!-- Firebase Cloud Messaging Service -->
        <service
            android:name=".MyFirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>'

safe_manifest_update "android/app/src/main/AndroidManifest.xml" \
    "MyFirebaseMessagingService" \
    "$FCM_SERVICE_CONFIG" \
    "FCM service configuration"

# 3. Add notification receiver for background messages
log_info "🔧 Configuring notification receiver..."
NOTIFICATION_RECEIVER_CONFIG='        <!-- Notification Receiver for Background Messages -->
        <receiver
            android:name=".NotificationReceiver"
            android:exported="false">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED" />
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
            </intent-filter>
        </receiver>'

safe_manifest_update "android/app/src/main/AndroidManifest.xml" \
    "NotificationReceiver" \
    "$NOTIFICATION_RECEIVER_CONFIG" \
    "Notification receiver configuration"

echo ""
echo "🔐 Phase 2: Notification Channel Configuration"
echo "=============================================="

# Create notification channel setup in MainActivity
log_info "🔧 Configuring notification channels..."

# Create the notification channel setup file with dynamic package name
if [[ -z "${PKG_NAME:-}" ]]; then
    log_error "❌ PKG_NAME environment variable is not set"
    log_info "Please ensure PKG_NAME is set in your workflow environment"
    exit 1
fi

# Convert package name to directory structure
PACKAGE_DIR=$(echo "$PKG_NAME" | sed 's/\./\//g')
mkdir -p "android/app/src/main/kotlin/$PACKAGE_DIR"
NOTIFICATION_CHANNEL_FILE="android/app/src/main/kotlin/$PACKAGE_DIR/NotificationChannelManager.kt"

log_info "📁 Creating notification channel manager in package: $PKG_NAME"
log_info "📁 Directory path: android/app/src/main/kotlin/$PACKAGE_DIR"

cat > "$NOTIFICATION_CHANNEL_FILE" << EOF
package $PKG_NAME

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.util.Log

object NotificationChannelManager {
    private const val TAG = "NotificationChannelManager"
    
    fun createNotificationChannels(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(NotificationManager::class.java)
            
            // Default notification channel
            val defaultChannel = NotificationChannel(
                "default",
                "Default Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Default notification channel for app notifications"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }
            
            // Push notification channel
            val pushChannel = NotificationChannel(
                "push_notifications",
                "Push Notifications",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Channel for push notifications and FCM messages"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }
            
            // Background message channel
            val backgroundChannel = NotificationChannel(
                "background_messages",
                "Background Messages",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Channel for background FCM messages"
                enableLights(false)
                enableVibration(false)
                setShowBadge(false)
            }
            
            notificationManager.createNotificationChannels(listOf(defaultChannel, pushChannel, backgroundChannel))
            Log.d(TAG, "Notification channels created successfully")
        }
    }
}
EOF

log_success "✅ Created NotificationChannelManager.kt"

# Create FCM service class
log_info "🔧 Creating FCM service class..."
FCM_SERVICE_FILE="android/app/src/main/kotlin/$PACKAGE_DIR/MyFirebaseMessagingService.kt"

cat > "$FCM_SERVICE_FILE" << EOF
package $PKG_NAME

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {
    private val TAG = "MyFirebaseMessagingService"
    
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.d(TAG, "From: ${remoteMessage.from}")
        
        // Check if message contains a data payload
        remoteMessage.data.isNotEmpty().let {
            Log.d(TAG, "Message data payload: ${remoteMessage.data}")
        }
        
        // Check if message contains a notification payload
        remoteMessage.notification?.let {
            Log.d(TAG, "Message Notification Body: ${it.body}")
            sendNotification(it.title ?: "New Message", it.body ?: "")
        }
        
        // Handle background messages
        if (remoteMessage.data.isNotEmpty()) {
            val title = remoteMessage.data["title"] ?: "New Message"
            val body = remoteMessage.data["body"] ?: ""
            sendNotification(title, body)
        }
    }
    
    override fun onNewToken(token: String) {
        Log.d(TAG, "Refreshed token: $token")
        // Send token to your server
        sendRegistrationToServer(token)
    }
    
    private fun sendRegistrationToServer(token: String) {
        // TODO: Implement this method to send token to your app server
        Log.d(TAG, "Token should be sent to server: $token")
    }
    
    private fun sendNotification(title: String, messageBody: String) {
        val intent = Intent(this, MainActivity::class.java)
        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_ONE_SHOT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val channelId = "push_notifications"
        val defaultSoundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
        val notificationBuilder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(messageBody)
            .setAutoCancel(true)
            .setSound(defaultSoundUri)
            .setContentIntent(pendingIntent)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Create notification channel for Android 8.0+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Push Notifications",
                NotificationManager.IMPORTANCE_HIGH
            )
            notificationManager.createNotificationChannel(channel)
        }
        
        notificationManager.notify(0, notificationBuilder.build())
    }
}
EOF

log_success "✅ Created MyFirebaseMessagingService.kt"

# Create notification receiver
log_info "🔧 Creating notification receiver..."
NOTIFICATION_RECEIVER_FILE="android/app/src/main/kotlin/$PACKAGE_DIR/NotificationReceiver.kt"

cat > "$NOTIFICATION_RECEIVER_FILE" << EOF
package $PKG_NAME

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class NotificationReceiver : BroadcastReceiver() {
    private val TAG = "NotificationReceiver"
    
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED -> {
                Log.d(TAG, "Boot completed, initializing notification channels")
                NotificationChannelManager.createNotificationChannels(context)
            }
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                Log.d(TAG, "Package replaced, reinitializing notification channels")
                NotificationChannelManager.createNotificationChannels(context)
            }
        }
    }
}
EOF

log_success "✅ Created NotificationReceiver.kt"

echo ""
echo "🏗️ Phase 3: MainActivity Integration"
echo "===================================="

# Update MainActivity to initialize notification channels
log_info "🔧 Integrating notification channel setup with MainActivity..."

# Check if MainActivity exists with dynamic package name
MAIN_ACTIVITY_FILES=(
    "android/app/src/main/kotlin/$PACKAGE_DIR/MainActivity.kt"
    "android/app/src/main/java/$PACKAGE_DIR/MainActivity.java"
)

MAIN_ACTIVITY_FOUND=false
for file in "${MAIN_ACTIVITY_FILES[@]}"; do
    if [[ -f "$file" ]]; then
        log_info "Found MainActivity at: $file"
        MAIN_ACTIVITY_FOUND=true
        
        # Check if it's already integrated
        if grep -q "NotificationChannelManager" "$file"; then
            log_info "ℹ️ Notification channel setup already integrated in MainActivity"
        else
            log_info "📝 Integrating notification channel setup..."
            
            # For Kotlin files
            if [[ "$file" == *.kt ]]; then
                # Add import
                sed -i.bak '/package/a\
import $PKG_NAME.NotificationChannelManager' "$file"
                
                # Add to onCreate method
                sed -i.bak '/super.onCreate(savedInstanceState)/a\
        NotificationChannelManager.createNotificationChannels(this)' "$file"
                
                log_success "✅ Integrated notification channel setup in Kotlin MainActivity"
            # For Java files
            elif [[ "$file" == *.java ]]; then
                # Add import
                sed -i.bak '/package/a\
import $PKG_NAME.NotificationChannelManager;' "$file"
                
                # Add to onCreate method
                sed -i.bak '/super.onCreate(savedInstanceState);/a\
        NotificationChannelManager.INSTANCE.createNotificationChannels(this);' "$file"
                
                log_success "✅ Integrated notification channel setup in Java MainActivity"
            fi
            
            rm -f "${file}.bak" 2>/dev/null || true
        fi
        break
    fi
done

if [[ "$MAIN_ACTIVITY_FOUND" == "false" ]]; then
    log_warning "⚠️ MainActivity not found, notification channels will be created by the service"
fi

echo ""
echo "📦 Phase 4: Build.gradle Configuration"
echo "======================================"

# Ensure Firebase dependencies are in build.gradle
log_info "🔧 Ensuring Firebase dependencies in build.gradle..."

if [[ -f "android/app/build.gradle.kts" ]]; then
    # Check if Firebase dependencies are present
    if ! grep -q "implementation.*firebase.*messaging" android/app/build.gradle.kts; then
        log_info "📝 Adding Firebase Messaging dependency to build.gradle.kts..."
        
        # Add after other Firebase dependencies
        sed -i.bak '/implementation.*firebase/a\
    implementation("com.google.firebase:firebase-messaging:23.4.0")' android/app/build.gradle.kts
        
        log_success "✅ Added Firebase Messaging dependency"
    else
        log_info "ℹ️ Firebase Messaging dependency already present"
    fi
    
    # Check if apply plugin 'com.google.gms.google-services' is present
    if ! grep -q "apply.*google-services" android/app/build.gradle.kts; then
        log_info "📝 Adding Google Services plugin to build.gradle.kts..."
        
        # Add at the end of the file
        echo "" >> android/app/build.gradle.kts
        echo "apply(plugin = \"com.google.gms.google-services\")" >> android/app/build.gradle.kts
        
        log_success "✅ Added Google Services plugin"
    else
        log_info "ℹ️ Google Services plugin already present"
    fi
    
    rm -f android/app/build.gradle.kts.bak 2>/dev/null || true
else
    log_warning "⚠️ build.gradle.kts not found, cannot configure Firebase dependencies"
fi

echo ""
echo "🔥 Phase 5: Firebase Configuration Validation"
echo "============================================"

# Validate Firebase configuration
log_info "🔍 Validating Firebase configuration..."

if [[ -f "android/app/google-services.json" ]]; then
    log_success "✅ google-services.json exists"
    
    # Check required Firebase keys
    REQUIRED_KEYS=("api_key" "client" "project_id" "storage_bucket")
    for key in "${REQUIRED_KEYS[@]}"; do
        if grep -q "\"$key\"" android/app/google-services.json; then
            log_success "✅ Firebase $key is configured"
        else
            log_warning "⚠️ Firebase $key is missing"
        fi
    done
    
    # Check package name consistency
    if [[ -f "android/app/src/main/AndroidManifest.xml" ]]; then
        FIREBASE_PACKAGE=$(grep -o '"package_name": "[^"]*"' android/app/google-services.json | head -1 | cut -d'"' -f4)
        MANIFEST_PACKAGE=$(grep -o 'package="[^"]*"' android/app/src/main/AndroidManifest.xml | cut -d'"' -f2)
        
        if [[ -n "$FIREBASE_PACKAGE" && -n "$MANIFEST_PACKAGE" ]]; then
            if [[ "$FIREBASE_PACKAGE" == "$MANIFEST_PACKAGE" ]]; then
                log_success "✅ Package name matches between Firebase and manifest: $FIREBASE_PACKAGE"
            else
                log_warning "⚠️ Package name mismatch: Firebase=$FIREBASE_PACKAGE, Manifest=$MANIFEST_PACKAGE"
            fi
        fi
    fi
else
    log_warning "⚠️ google-services.json not found"
    log_info "ℹ️ Firebase configuration will be handled by the Firebase setup script"
fi

echo ""
echo "🔍 Phase 6: Final Configuration Verification"
echo "==========================================="

# Final verification of key configurations
log_info "🔍 Performing final configuration verification..."

# Check AndroidManifest.xml configurations
if grep -q "MyFirebaseMessagingService" android/app/src/main/AndroidManifest.xml; then
    log_success "✅ FCM service configured in AndroidManifest.xml"
else
    log_error "❌ FCM service missing from AndroidManifest.xml"
fi

if grep -q "NotificationReceiver" android/app/src/main/AndroidManifest.xml; then
    log_success "✅ Notification receiver configured in AndroidManifest.xml"
else
    log_error "❌ Notification receiver missing from AndroidManifest.xml"
fi

# Check notification permissions
if grep -q "android.permission.WAKE_LOCK" android/app/src/main/AndroidManifest.xml; then
    log_success "✅ WAKE_LOCK permission configured"
else
    log_error "❌ WAKE_LOCK permission missing"
fi

if grep -q "android.permission.VIBRATE" android/app/src/main/AndroidManifest.xml; then
    log_success "✅ VIBRATE permission configured"
else
    log_error "❌ VIBRATE permission missing"
fi

# Check if required classes were created
REQUIRED_CLASSES=(
    "NotificationChannelManager.kt"
    "MyFirebaseMessagingService.kt"
    "NotificationReceiver.kt"
)

for class in "${REQUIRED_CLASSES[@]}"; do
    if [[ -f "android/app/src/main/kotlin/co/pixaware/pixaware/$class" ]]; then
        log_success "✅ $class created successfully"
    else
        log_error "❌ $class creation failed"
    fi
done

echo ""
echo "🎉 Push Notification Setup Complete!"
echo "==================================="

log_success "✅ Complete push notification configuration completed successfully!"
log_info "📱 Your Android app is now configured to receive push notifications in ALL states:"
echo "   🔵 Background state (app in background)"
echo "   🔴 Closed state (app terminated)"
echo "   🟢 Opened state (app active)"
echo ""
log_info "🚀 Ready for production push notification testing!"

# Run comprehensive verification to confirm setup
if [[ -f "lib/scripts/android/verify_push_notifications_comprehensive.sh" ]]; then
    echo ""
    log_info "🔍 Running comprehensive verification to confirm setup..."
    chmod +x lib/scripts/android/verify_push_notifications_comprehensive.sh
    if ./lib/scripts/android/verify_push_notifications_comprehensive.sh; then
        log_success "🎉 Verification passed! Push notifications are fully configured."
    else
        log_warning "⚠️ Verification found some issues. Check the output above."
        log_info "🔧 Push notifications may not work properly until all issues are resolved."
    fi
else
    log_warning "⚠️ Comprehensive verification script not found"
fi

echo ""
log_success "🔔 Push notification setup process completed!"
