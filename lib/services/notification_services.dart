import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notification/main.dart';
import 'package:notification/view/notification_view.dart';

// handle background message
// its a top level function not a class method which required initialization
Future<void> handleBackgroundMessage(RemoteMessage message) async {
  print("Title: ${message.notification?.title}");
  print("Body: ${message.notification?.body}");
  print("Payload: ${message.data}");
}

class NotificationService {
  // firebase message instance
  final firebaseMessaging = FirebaseMessaging.instance;

  // local notification instance
  final localNotification = FlutterLocalNotificationsPlugin();

  // android channel
  final androidChannel = const AndroidNotificationChannel(
    "high_importance_channel",
    "high Importance Notification",
    description: "This channel is used for important notifications",
    importance: Importance.high,
  );

  // navigate to notification screen
  void handleMessage(RemoteMessage? message) {
    if (message == null) return;
    navigatorKey.currentState?.pushNamed(
      NotificationView.route,
      arguments: message,
    );
  }

  Future initLocalNotification() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    // const ios = DarwinInitializationSettings();
    const setting = InitializationSettings(android: android);
    await localNotification.initialize(
      setting,
      onDidReceiveNotificationResponse: (payload) {
        final message = RemoteMessage.fromMap(jsonDecode(payload.toString()));
        handleMessage(message);
      },
    );

    // platform specific notification android or Ios
    final platform = localNotification.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await platform?.createNotificationChannel(androidChannel);
  }

  Future initPushNotification() async {
    // IOS foreground notification
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    // when app is open from notification and execute handleMessage method
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage);

    // execute handleMessage method when app is open from notification
    // app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

    // background message from firebase
    FirebaseMessaging.onBackgroundMessage(handleBackgroundMessage);

    // notification when app is active
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;

      localNotification.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            androidChannel.id,
            androidChannel.name,
            channelDescription: androidChannel.description,
            icon: ('@mipmap/ic_launcher'),
          ),
        ),
        payload: jsonEncode(message.toMap()),
      );
    });
  }

  Future<void> initFirebaseNotification() async {
    // get permission
    await firebaseMessaging.requestPermission();
    // get device token
    String? fCMToken = await firebaseMessaging.getToken();
    print("Device Token: $fCMToken");
    initPushNotification();
    initLocalNotification();
  }
}
