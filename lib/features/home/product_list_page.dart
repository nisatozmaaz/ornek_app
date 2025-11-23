// features/home/product_list_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:ornek_app/notify.dart';
import '../recipes/recipe_page.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      OneSignal.login(user.uid);
      debugPrint('✅ OneSignal.login(${user.uid})');
    }
    final itemsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('items');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ürünlerim',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Çıkış',
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
          },
        ),
      ),

      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: itemsRef.orderBy('expiry', descending: false).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Henüz ürün yok. + ile ekle.',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            );
          }

          final today = DateTime.now();

          // SlidableAutoCloseBehavior: bir slidable açılınca diğerini kapatır
          return SlidableAutoCloseBehavior(
            child: ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final data = docs[i].data();
                final name = data['name'] as String? ?? '';

                DateTime? expiry;
                final raw = data['expiry'];
                if (raw is Timestamp) expiry = raw.toDate();

                final tileColor = Colors.white;

                TextSpan textSpan;
                if (expiry != null) {
                  final base = DateTime(today.year, today.month, today.day);
                  final d = expiry.difference(base).inDays;

                  textSpan = TextSpan(
                    children: [
                      TextSpan(
                        text: 'SKT: ${_fmt(expiry)}',
                        style: const TextStyle(color: Colors.black87),
                      ),
                      if (d < 0)
                        const TextSpan(
                          text: ' • SÜRESİ GEÇMİŞ',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (d >= 0 && d <= 3)
                        TextSpan(
                          text: ' • $d GÜN KALDI',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  );
                } else {
                  textSpan = const TextSpan(text: '');
                }

                return Slidable(
                  key: ValueKey(docs[i].id),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) {
                          _openEditSheet(context, itemsRef, docs[i].id, data);
                        },
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        icon: Icons.edit,
                        label: 'Düzenle',
                      ),
                      SlidableAction(
                        onPressed: (_) async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Silme Onayı"),
                              content: Text(
                                "$name adlı ürünü silmek istediğinize emin misiniz?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("İptal"),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text("Sil"),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await itemsRef.doc(docs[i].id).delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("$name silindi")),
                            );
                          }
                        },
                        backgroundColor: Colors.teal.shade300,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: 'Sil',
                      ),
                    ],
                  ),
                  child: Card(
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: tileColor,
                    child: ListTile(
                      title: Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: expiry != null
                          ? RichText(text: textSpan)
                          : null,
                      // ÜRÜNE TIKLAYINCA tarif sayfasına git
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                RecipePage(productName: name, expiry: expiry),
                          ),
                        );
                      },

                      // Sağ tarafa “Tarifler” butonu
                      trailing: TextButton.icon(
                        icon: const Icon(Icons.restaurant_menu),
                        label: const Text('Tarifler'),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  RecipePage(productName: name, expiry: expiry),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSheet(context, itemsRef),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  static String _fmt(DateTime d) {
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }

  void _openAddSheet(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> itemsRef,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(ctx).pop(),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            builder: (_, scrollController) => GestureDetector(
              onTap: () {},
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _AddProductForm(
                    onSave: (name, expiry) async {
                      try {
                        final exp = expiry!; // null değil; formda zorunlu
                        await itemsRef.add({
                          'name': name,
                          'expiry': Timestamp.fromDate(exp),
                          'createdAt': FieldValue.serverTimestamp(),
                        });

                        // 🔔 OneSignal bildirimleri
                        final uid = FirebaseAuth.instance.currentUser!.uid;
                        final now = DateTime.now();
                        final today = DateTime(
                          now.year,
                          now.month,
                          now.day,
                          0,
                          0,
                          0,
                        );
                        final expDay = DateTime(
                          exp.year,
                          exp.month,
                          exp.day,
                          0,
                          0,
                          0,
                        );
                        final daysLeft = expDay.difference(today).inDays;

                        debugPrint(
                          '📅 Ürün: $name, SKT: ${_fmt(exp)}, Kalan gün: $daysLeft',
                        );

                        if (daysLeft >= 0 && daysLeft <= 3) {
                          // 3 gün veya daha az - anında bildir
                          await sendOneSignalNow(
                            externalId: uid,
                            titleTR: 'Hatırlatma',
                            bodyTR:
                                '"$name" için SKT\'ye $daysLeft gün kaldı. SKT: ${_fmt(exp)}',
                          );
                        } else if (daysLeft > 3) {
                          // 3+ gün sonra - planlı bildirim
                          final when3 = expDay.subtract(
                            const Duration(days: 3),
                          );
                          await scheduleOneSignal(
                            externalId: uid,
                            titleTR: 'Hatırlatma',
                            bodyTR:
                                '"$name" için SKT\'ye 3 gün kaldı. SKT: ${_fmt(exp)}',
                            sendTimeLocal: when3,
                          );
                        }
                        // (Opsiyonel) SKT - 1 gün için ikinci plan
                        final d1 = exp.subtract(const Duration(days: 1));
                        if (d1.isAfter(now)) {
                          await scheduleOneSignal(
                            externalId: uid,
                            titleTR: 'Son hatırlatma',
                            bodyTR: '"$name" için SKT yarın! SKT: ${_fmt(exp)}',
                            sendTimeLocal: d1,
                          );
                        }

                        // UI kapat & bilgi ver
                        // (plan/now çağrıları bitti; sheet'i sonra kapatıyoruz)
                        // İstersen önce kapatıp sonra gönderebilirsin—fark etmez.
                        Navigator.of(ctx).pop();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$name eklendi'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ürün eklenirken hata oluştu: $e'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openEditSheet(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> itemsRef,
    String docId,
    Map<String, dynamic> data,
  ) {
    final name = data['name'] as String? ?? '';
    DateTime? expiry;
    final raw = data['expiry'];
    if (raw is Timestamp) expiry = raw.toDate();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(ctx).pop(),
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.8,
            builder: (_, scrollController) => GestureDetector(
              onTap: () {},
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: _AddProductForm(
                    initialName: name,
                    initialDate: expiry,
                    onSave: (newName, newExpiry) async {
                      try {
                        await itemsRef.doc(docId).update({
                          'name': newName,
                          'expiry': Timestamp.fromDate(newExpiry!),
                        });
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("$newName güncellendi"),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Güncellerken hata oluştu: $e'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddProductForm extends StatefulWidget {
  final Future<void> Function(String, DateTime?) onSave;
  final String? initialName;
  final DateTime? initialDate;

  const _AddProductForm({
    required this.onSave,
    this.initialName,
    this.initialDate,
  });

  @override
  State<_AddProductForm> createState() => _AddProductFormState();
}

class _AddProductFormState extends State<_AddProductForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  DateTime? _date;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _date = widget.initialDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  final ImagePicker _picker = ImagePicker(); // kameradan foto almak

  DateTime? _tryExtractDate(String text) {
    // 1) "SKT/TETT/EXP: 12.03.2026" tipi:
    final r1 = RegExp(
      r'(?:SKT|TETT|EXP)\s*[:\-]?\s*([0-3]?\d[./-][01]?\d[./-]\d{2,4})',
      caseSensitive: false,
    );
    final m1 = r1.firstMatch(text);
    if (m1 != null) {
      final d = _parseDottedDate(m1.group(1)!);
      if (d != null) return d;
    }

    // 2) "12.03.2026" / "12/03/26" / "12-3-2026"
    final r2 = RegExp(r'\b([0-3]?\d[./-][01]?\d[./-]\d{2,4})\b');
    final m2 = r2.firstMatch(text);
    if (m2 != null) {
      final d = _parseDottedDate(m2.group(1)!);
      if (d != null) return d;
    }

    // 3) "12 Mart 2026" (TR ay adları)
    final r3 = RegExp(
      r'\b([0-3]?\d)\s*(Ocak|Şubat|Mart|Nisan|Mayıs|Haziran|Temmuz|Ağustos|Eylül|Ekim|Kasım|Aralık)\s*(\d{2,4})\b',
      caseSensitive: false,
    );
    final m3 = r3.firstMatch(text);
    if (m3 != null) {
      final gun = int.tryParse(m3.group(1)!);
      final ayAd = m3.group(2)!.toLowerCase();
      final yilRaw = int.tryParse(m3.group(3)!);
      if (gun != null && yilRaw != null) {
        final ayMap = {
          'ocak': 1,
          'şubat': 2,
          'subat': 2,
          'mart': 3,
          'nisan': 4,
          'mayıs': 5,
          'mayis': 5,
          'haziran': 6,
          'temmuz': 7,
          'ağustos': 8,
          'agustos': 8,
          'eylül': 9,
          'eylul': 9,
          'ekim': 10,
          'kasım': 11,
          'kasim': 11,
          'aralık': 12,
          'aralik': 12,
        };
        final ay = ayMap[ayAd];
        if (ay != null) {
          final yil = yilRaw < 100 ? (2000 + yilRaw) : yilRaw;
          try {
            return DateTime(yil, ay, gun);
          } catch (_) {}
        }
      }
    }

    return null;
  }

  DateTime? _parseDottedDate(String s) {
    final parts = s.split(RegExp(r'[./-]'));
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    var y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;
    if (y < 100) y = 2000 + y; // 26 → 2026 gibi
    try {
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  Future<void> _scanDateFromCamera() async {
    // 1) Fotoğraf çek
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;

    // 2) ML Kit ile metin tanı
    final inputImage = InputImage.fromFilePath(picked.path);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final result = await recognizer.processImage(inputImage);

      // 3) Metnin tamamından tarih çekmeyi dene
      final found = _tryExtractDate(result.text);

      if (found != null) {
        // Basit mantıksal doğrulama
        final now = DateTime.now();
        final maxDate = DateTime(now.year + 5, now.month, now.day);
        if (found.isBefore(now.subtract(const Duration(days: 1))) ||
            found.isAfter(maxDate)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OCR sonucu mantıksız bir tarih, tekrar deneyin.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        // Kullanıcıya onay sor
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Tarih Bulundu"),
            content: Text(
              "Tespit edilen tarih: ${ProductListPage._fmt(found)}\nDoğru mu?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text("Hayır"),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text("Evet"),
              ),
            ],
          ),
        );

        if (confirm == true) {
          setState(() {
            _date = found;
            _dateError = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tarih kaydedildi: ${ProductListPage._fmt(found)}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tarih bulunamadı. Lütfen daha net bir fotoğraf çekin.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('OCR hatası: $e')));
    } finally {
      await recognizer.close();
    }
  }

  Future<String?> _fetchProductName(String barcode) async {
    try {
      final url = Uri.parse(
        'https://world.openfoodfacts.org/api/v0/product/$barcode.json',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) {
          final productName = data['product']['product_name'] as String?;
          return productName;
        }
      }
      return null;
    } catch (e) {
      // ignore: avoid_print
      print('Hata: Ürün bilgisi çekilemedi. $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initialName != null ? 'Ürün Düzenle' : 'Ürün Ekle',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Ürün adı',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    final barcode = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SimpleScanner(),
                      ),
                    );
                    if (barcode != null) {
                      final productName = await _fetchProductName(
                        barcode.toString(),
                      );
                      if (productName != null) {
                        setState(() {
                          _nameCtrl.text = productName;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Ürün adı barkoddan alındı: $productName',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Barkod numarası için ürün bulunamadı.',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Boş bırakılamaz' : null,
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    _date == null
                        ? 'Son kullanma tarihi(zorunlu)'
                        : ProductListPage._fmt(_date!),
                  ),
                  onPressed: () async {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (context) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.calendar_today),
                              title: const Text('Manuel Tarih Seç'),
                              onTap: () async {
                                Navigator.pop(context);
                                final now = DateTime.now();
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _date ?? now,
                                  firstDate: now.subtract(
                                    const Duration(days: 1),
                                  ),
                                  lastDate: DateTime(now.year + 5),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _date = picked;
                                    _dateError = null;
                                  });
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.camera_alt),
                              title: const Text('Kameradan Oku'),
                              onTap: () {
                                Navigator.pop(context);
                                _scanDateFromCamera();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                if (_dateError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _dateError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Kaydet'),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    if (_date == null) {
                      setState(
                        () =>
                            _dateError = 'Son kullanma tarihi boş bırakılamaz',
                      );
                      return;
                    }
                    await widget.onSave(_nameCtrl.text.trim(), _date);
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class SimpleScanner extends StatelessWidget {
  const SimpleScanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barkod Tara')),
      body: MobileScanner(
        controller: MobileScannerController(
          detectionSpeed: DetectionSpeed.noDuplicates,
        ),
        onDetect: (capture) {
          final barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final barcode = barcodes.first.rawValue;
            Navigator.pop(context, barcode);
          }
        },
      ),
    );
  }
}
