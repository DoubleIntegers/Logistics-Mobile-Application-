import 'dart:developer';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';


// ── Background message handler (top-level function, wajib di luar class) ──
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  // Firebase sudah diinit di main(), tidak perlu init lagi
  log('🔔 [BG] Notif diterima: ${message.notification?.title}');
  log('   Body   : ${message.notification?.body}');
  log('   Data   : ${message.data}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  // GlobalKey untuk akses ScaffoldMessenger dari mana saja
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  /// Channel ID harus sama dengan AndroidManifest meta-data
  static const _channelId = 'logitrack_channel';
  static const _channelName = 'LogiTrack Notifications';
  static const _channelDesc = 'Notifikasi pengiriman dan update order';

  // ── Public init ───────────────────────────────────────────

  Future<void> initialize() async {
    await _setupLocalNotifications();
    await _requestPermission();
    await _configureFCM();
    _printFcmToken();
  }

  // ── Local Notifications Setup ─────────────────────────────

  Future<void> _setupLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotif.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onLocalNotifTapped,
    );

    // Buat Android notification channel
if (Platform.isAndroid) {
      await _localNotif
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
            const AndroidNotificationChannel(
              _channelId,
              _channelName,
              description: _channelDesc,
              importance: Importance.high,
              playSound: true,
              enableVibration: true,
              enableLights: true,
              ledColor: Color(0xFF0052CC),
            ),
          );
    }
  }

  void _onLocalNotifTapped(NotificationResponse response) {
    log('🔔 Local notif tapped: ${response.payload}');
    // TODO: navigasi berdasarkan payload (misal order ID)
  }

  // ── Permission ────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    log('🔔 FCM permission: ${settings.authorizationStatus}');
  }

  // ── FCM Configuration ─────────────────────────────────────

  Future<void> _configureFCM() async {
    // 1. Background handler (wajib top-level function)
    FirebaseMessaging.onBackgroundMessage(
        firebaseBackgroundMessageHandler);

    // 2. Foreground: tampilkan sebagai local notif + snackbar
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 3. App dibuka dari notif (background → foreground)
    FirebaseMessaging.onMessageOpenedApp
        .listen(_handleNotificationOpenedApp);

    // 4. App dibuka dari terminated state via notif
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      log('🔔 App dibuka dari notif terminated: ${initial.notification?.title}');
      _handleNotificationOpenedApp(initial);
    }

    // 5. iOS: tampilkan notif saat foreground
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _handleForegroundMessage(RemoteMessage message) {
    log('🔔 [FG] Notif masuk: ${message.notification?.title}');

    // Tampilkan local notification
    _showLocalNotification(message);

    // Tampilkan Snackbar
    _showSnackbar(message);
  }

  void _handleNotificationOpenedApp(RemoteMessage message) {
    log('🔔 App dibuka via notif: ${message.notification?.title}');
    log('   Data: ${message.data}');
    // TODO: navigasi ke halaman relevan berdasarkan message.data
    // Contoh: if (message.data['type'] == 'new_order') { ... }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    await _localNotif.show(
      message.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF0052CC),
          styleInformation: BigTextStyleInformation(
            notif.body ?? '',
            htmlFormatBigText: false,
            contentTitle: notif.title,
          ),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  void _showSnackbar(RemoteMessage message) {
    final title = message.notification?.title ?? 'Notifikasi';
    final body = message.notification?.body ?? '';

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.notifications_rounded,
                  color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.white)),
                  if (body.isNotEmpty)
                    Text(body,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0052CC),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        action: SnackBarAction(
          label: 'Lihat',
          textColor: Colors.amber,
          onPressed: () {
            // TODO: navigasi ke halaman relevan
          },
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  void _printFcmToken() async {
    final token = await _fcm.getToken();
    log('════════════════════════════════════════');
    log('🔑 FCM Device Token:');
    log('   $token');
    log('════════════════════════════════════════');
    // TODO: simpan token ke tabel `profiles` di Supabase
    // agar server bisa kirim notif ke device tertentu
  }

  Future<String?> getFcmToken() async => _fcm.getToken();

  /// Subscribe ke topic (misal semua driver)
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    log('🔔 Subscribed to topic: $topic');
  }

  /// Unsubscribe dari topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }
}