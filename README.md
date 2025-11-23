# 🍎 Gıda İsrafı Önleme Uygulaması

Son kullanma tarihi takibi ve akıllı tarif önerileri ile gıda israfını önlemeye yardımcı olan Flutter mobil uygulaması.

## 📱 Özellikler

### 🔔 Akıllı Bildirim Sistemi
- Son kullanma tarihine 3 gün kala otomatik bildirim
- OneSignal entegrasyonu ile güvenilir push notification
- Kullanıcı dostu hatırlatmalar

### 🤖 AI Destekli Tarif Önerileri
- Google Gemini AI entegrasyonu
- Bozulmak üzere olan ürünler için özel tarifler
- Hızlı ve pratik yemek tarifleri
- Malzeme listesi ve adım adım talimatlar

### 📷 Akıllı Tarama Özellikleri
- **Barkod Okuma**: Ürün ismini otomatik getir
- **OCR ile SKT Okuma**: Kameradan son kullanma tarihini otomatik tanı
- Google ML Kit Text Recognition ile güçlü metin tanıma

### 📦 Ürün Yönetimi
- Ürün ekleme, düzenleme, silme
- Son kullanma tarihi takibi
- Görsel uyarılar (3 gün ve daha az kaldığında)
- Kaydırarak düzenleme/silme (Slidable UI)

## 🛠️ Kullanılan Teknolojiler

### Frontend
- **Flutter** - Cross-platform mobil framework
- **Dart** - Programlama dili

### Backend & Services
- **Firebase Authentication** - Kullanıcı yönetimi
- **Cloud Firestore** - Veritabanı
- **Firebase Cloud Functions** - Sunucu tarafı işlemler

### AI & Bildirim
- **Google Gemini 2.0 Flash** - Tarif üretimi için AI
- **OneSignal** - Push notification servisi

### Kütüphaneler
```yaml
dependencies:
  # Firebase
  firebase_core: ^4.0.0
  firebase_auth: ^6.0.1
  cloud_firestore: ^6.0.0
  firebase_messaging: 16.0.0
  
  # Bildirim
  onesignal_flutter: ^5.3.4
  
  # Kamera & Tarama
  mobile_scanner: ^4.0.0
  google_mlkit_text_recognition: ^0.15.0
  image_picker: ^1.2.0
  camera: ^0.11.2
  
  # UI
  flutter_slidable: ^3.1.0
  
  # Network
  http: ^1.2.1
  
  # Yerelleştirme
  intl: ^0.20.2
  flutter_localization: ^0.3.3
```

## 🚀 Kurulum

### 1. Projeyi Klonla
```bash
git clone https://github.com/nisatozmaaz/ornek_app.git
cd ornek_app
```

### 2. Bağımlılıkları Yükle
```bash
flutter pub get
```

### 3. Firebase Yapılandırması
- Firebase Console'dan yeni proje oluştur
- Android/iOS için uygulama ekle
- `google-services.json` (Android) ve `GoogleService-Info.plist` (iOS) dosyalarını indir
- İlgili klasörlere yerleştir

### 4. API Key'lerini Ayarla

**OneSignal:**
1. [OneSignal](https://onesignal.com) hesabı oluştur
2. Yeni uygulama oluştur
3. `lib/notify.dart` dosyasında API key'leri güncelle

**Google Gemini:**
1. [Google AI Studio](https://makersuite.google.com/app/apikey) hesabı oluştur
2. API key al
3. `lib/features/recipes/recipe_page.dart` dosyasında API key'i güncelle

### 5. Uygulamayı Çalıştır
```bash
flutter run
```

## 📂 Proje Yapısı

```
lib/
├── main.dart                          # Ana uygulama giriş noktası
├── auth_gate.dart                     # Kimlik doğrulama kontrol
├── notify.dart                        # OneSignal bildirim servisi
├── theme/
│   └── theme.dart                     # Uygulama teması
└── features/
    ├── home/
    │   └── product_list_page.dart     # Ana ürün listesi sayfası
    └── recipes/
        └── recipe_page.dart           # AI tarif önerileri sayfası
```

## 🎯 Kullanım

### Ürün Ekleme
1. Ana sayfada **+** butonuna tıkla
2. **Barkod** veya **Manuel** olarak ürün adı gir
3. **Kamera** veya **Manuel** olarak son kullanma tarihini gir
4. **Kaydet**

### Tarif Önerileri
1. Ürüne tıkla veya **Tarifler** butonuna bas
2. AI otomatik olarak tarif üretecek
3. Malzemeler ve adımları görüntüle

### Bildirimler
- Ürün eklendiğinde otomatik planlanır
- SKT'ye 3 gün kaldığında bildirim gelir
- Bildirime tıklayarak uygulamayı aç

## 🔒 Güvenlik Notları

⚠️ **Önemli:** Gerçek bir uygulamada API key'lerini `.env` dosyasında saklayın ve `.gitignore`'a ekleyin!

```bash
# .gitignore'a ekle
*.env
lib/config/api_keys.dart
```

## 👨‍💻 Geliştirici

**Nisa Nur Tozmaz**
- GitHub: [@nisatozmaaz](https://github.com/nisatozmaaz)

## 🙏 Teşekkürler

- Google Gemini AI - Tarif önerileri için
- OneSignal - Bildirim servisi için
- Firebase - Backend altyapısı için
- Flutter Community - Harika paketler için

---

⭐ Bu projeyi beğendiyseniz yıldız vermeyi unutmayın!