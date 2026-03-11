import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:playmate/notification_screen.dart';
import 'package:playmate/splash_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',
  'High Importance Notifications',
  description: 'Used for important notifications.',
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

bool _localNotificationsReady = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  var firebaseReady = false;
  if (!kIsWeb) {
    await Firebase.initializeApp();
    firebaseReady = true;
  } else {
    // Web requires explicit FirebaseOptions (flutterfire configure).
    debugPrint('Firebase init skipped on web: missing FirebaseOptions.');
  }

  if (firebaseReady) {
    await _initializeLocalNotifications();

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('Notification permission: ${settings.authorizationStatus}');

    if (kDebugMode) {
      await _showTestNotification();
    }

    messaging
        .getToken()
        .then((token) {
          debugPrint("Firebase Messaging Token: $token");
          _syncFcmTokenToBackend(token);
        })
        .catchError((error) {
          debugPrint("Error fetching Firebase Messaging token: $error");
        });

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      debugPrint('FCM token refreshed: $token');
      _syncFcmTokenToBackend(token);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground notification: ${message.messageId} ${message.data}');
      _showForegroundNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      debugPrint('Notification clicked with data: ${message.data}');
      _openNotificationsScreen();
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint(
          'App opened from terminated state by notification: ${message.data}',
        );
        _openNotificationsScreen();
      }
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  runApp(const MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp();
  }
  debugPrint('Handling a background message: ${message.messageId}');
  // Handle background message
}

Future<void> _initializeLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
  const iosInit = DarwinInitializationSettings();

  try {
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (_) {
        _openNotificationsScreen();
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
    _localNotificationsReady = true;
  } on MissingPluginException catch (e) {
    _localNotificationsReady = false;
    debugPrint('Local notifications plugin is not registered yet: $e');
  }
}

Future<void> _showForegroundNotification(RemoteMessage message) async {
  if (!_localNotificationsReady) {
    return;
  }

  final notification = message.notification;
  if (notification == null) {
    return;
  }

  await _localNotifications.show(
    notification.hashCode,
    notification.title ?? 'PlayMate',
    notification.body ?? 'You have a new notification',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'Used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    payload: 'notifications',
  );
}

Future<void> _showTestNotification() async {
  if (!_localNotificationsReady) {
    return;
  }

  await _localNotifications.show(
    999001,
    'PlayMate Test Notification',
    'If this appears, popup notifications are working.',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'Used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    payload: 'notifications',
  );
}

Future<void> _syncFcmTokenToBackend(String? fcmToken) async {
  if (fcmToken == null || fcmToken.isEmpty) {
    return;
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('auth_token');
    final userId = prefs.getString('user_id');
    final baseUrl = dotenv.env['BASE_URL'] ?? '';

    if (authToken == null || authToken.isEmpty) {
      debugPrint('Skipping FCM token sync: missing auth_token');
      return;
    }
    if (userId == null || userId.isEmpty) {
      debugPrint('Skipping FCM token sync: missing user_id');
      return;
    }
    if (baseUrl.isEmpty) {
      debugPrint('Skipping FCM token sync: missing BASE_URL');
      return;
    }

    final uri = Uri.parse('$baseUrl/user/fcm-token/$userId');
    final response = await http.patch(
      uri,
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'fcm_token': fcmToken}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      debugPrint('FCM token synced successfully');
    } else {
      debugPrint(
        'FCM token sync failed: ${response.statusCode} ${response.body}',
      );
    }
  } catch (e) {
    debugPrint('Error syncing FCM token: $e');
  }
}

void _openNotificationsScreen() {
  final navigator = navigatorKey.currentState;
  if (navigator != null) {
    navigator.pushNamed('/notifications');
    return;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    navigatorKey.currentState?.pushNamed('/notifications');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Playmate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(elevation: 0, scrolledUnderElevation: 0),
      ),
      home: const SplashScreen(),
      navigatorKey: navigatorKey,
      routes: {
        '/notifications': (context) => const NotificationScreen(),
      },
    );
  }
}
