// lib/notify.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// OneSignal REST anahtarları
const String kOneSignalAppId = "36833244-8d24-499b-afb9-64161b5c7fde";
const String kOneSignalRestKey =
    "os_v2_app_g2bterenerezxl5zmqlbwxd73zujcsqfgh6enjelwjd7raeqsboatik5ul5qosyupu4mgrlrodiwqectlpgxwbohjf2hrusqujz6gfi";
const String kAndroidChannelId = "7b9e80c0-1442-4f02-88c6-750c5316ac61";

/// Şimdi gönder (eşzamanlı, anında push)
Future<bool> sendOneSignalNow({
  required String externalId, // Firebase uid
  required String titleTR,
  required String bodyTR,
  Map<String, dynamic>? data,
}) async {
  debugPrint('🔔 OneSignal NOW gönderiliyor: $titleTR - $bodyTR');

  final resp = await http.post(
    Uri.parse('https://api.onesignal.com/notifications'),
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Key $kOneSignalRestKey',
    },
    body: jsonEncode({
      'app_id': kOneSignalAppId,
      'target_channel': 'push',
      'include_aliases': {
        'external_id': [externalId],
      },
      'headings': {'en': titleTR},
      'contents': {'en': bodyTR},
      'android_channel_id': kAndroidChannelId,
      'android_sound': 'default',
      'priority': 10,
      if (data != null) 'data': data,
    }),
  );

  if (resp.statusCode >= 200 && resp.statusCode < 300) {
    debugPrint('✅ Bildirim başarılı: ${resp.body}');
    return true;
  } else {
    debugPrint('❌ OneSignal NOW failed: ${resp.statusCode} ${resp.body}');
    return false;
  }
}

/// Planlı gönderim (örn. SKT'den 3 gün önce)
Future<bool> scheduleOneSignal({
  required String externalId,
  required String titleTR,
  required String bodyTR,
  required DateTime sendTimeLocal, // yerel saat
  Map<String, dynamic>? data,
}) async {
  // OneSignal UTC ister
  final sendAfterUtc = sendTimeLocal.toUtc().toIso8601String();

  debugPrint(
    '📅 OneSignal SCHEDULE planlanıyor: $titleTR - ${sendTimeLocal.toLocal()}',
  );

  final resp = await http.post(
    Uri.parse('https://api.onesignal.com/notifications'),
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Key $kOneSignalRestKey',
    },
    body: jsonEncode({
      'app_id': kOneSignalAppId,
      'target_channel': 'push',
      'include_aliases': {
        'external_id': [externalId],
      },
      'headings': {'en': titleTR},
      'contents': {'en': bodyTR},
      'send_after': sendAfterUtc,
      'priority': 10,
      if (data != null) 'data': data,
    }),
  );

  if (resp.statusCode >= 200 && resp.statusCode < 300) {
    debugPrint('✅ Planlı bildirim oluşturuldu: ${resp.body}');
    return true;
  } else {
    debugPrint('❌ OneSignal SCHEDULE failed: ${resp.statusCode} ${resp.body}');
    return false;
  }
}
