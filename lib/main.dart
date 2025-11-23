import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth_gate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'theme/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

// Arka planda gelen FCM bildirimleri (Firebase Messaging) için handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // burada print unutulmuştu:
  debugPrint("📩 Arka planda mesaj geldi: ${message.notification?.title}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2) FCM background handler (eğer FCM de kullanacaksan)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3) OneSignal (runApp'tan ÖNCE; doğru sıra)
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

  // OneSignal App ID'ni buraya koy
  OneSignal.initialize("36833244-8d24-499b-afb9-64161b5c7fde");

  // Android 13+/iOS için izin iste. (true → native izin penceresini göster)
  final accepted = await OneSignal.Notifications.requestPermission(true);
  if (kDebugMode) debugPrint('🔔 Push permission accepted: $accepted');

  // Uygulama açıkken de sistem bildirimi göster
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    // Varsayılan davranışı engelle
    event.preventDefault();
    // Bildirimi manuel göster
    event.notification.display();
  });

  // (Opsiyonel) Bildirime tıklama dinleyicisi
  OneSignal.Notifications.addClickListener((opened) {
    // final data = opened.notification.additionalData;
    // TODO: data'ya göre sayfa yönlendirme yapılabilir
    debugPrint("🔔 Notification clicked: ${opened.notification.title}");
  });

  // 4) Uygulamayı başlat
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM(); // (Opsiyonel) FCM token'ını Firestore'a yazıyorsan
    _setupOneSignalLoginBridge(); // Firebase Auth ile OneSignal external_id bağla
  }

  // KULLANIYORSAN: FCM token'ını Firestore'a kaydet
  Future<void> _setupFCM() async {
    final fcm = FirebaseMessaging.instance;

    // iOS için bildirim izni (OneSignal zaten sordu; burada da istemek istersen)
    await fcm.requestPermission();

    final token = await fcm.getToken();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "fcmToken": token,
      }, SetOptions(merge: true));
    }

    // Token yenilenince güncelle
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "fcmToken": newToken,
        }, SetOptions(merge: true));
      }
    });
  }

  // Firebase Auth durumuna göre OneSignal'e login/logout (external_id = uid)
  void _setupOneSignalLoginBridge() {
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        await OneSignal.login(user.uid);
        if (kDebugMode) debugPrint("✅ OneSignal.login(${user.uid})");
      } else {
        await OneSignal.logout();
        if (kDebugMode) debugPrint("↩️ OneSignal.logout()");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      title: 'Gıda İsrafı',
      theme: appTheme,
      home: const AuthGate(),
    );
  }
}
