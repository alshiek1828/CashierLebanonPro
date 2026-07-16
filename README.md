# Cashier Lebanon Pro 🇱🇧

**نظام نقاط بيع احترافي يعمل بالكامل بدون إنترنت**

[![Flutter](https://img.shields.io/badge/Flutter-3.2+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.2+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-green)](https://github.com)

---

## 📋 وصف المشروع

Cashier Lebanon Pro هو تطبيق نقاط بيع (POS) احترافي مصمم خصيصاً للمتاجر اللبنانية. يعمل التطبيق بالكامل **بدون اتصال بالإنترنت** مع دعم كامل للعملتين:

- **دولار أمريكي (USD)**
- **ليرة لبنانية (LBP)**

مع تحويل تلقائي حسب سعر الصرف.

## ✨ المميزات الرئيسية

### 🛒 إدارة المنتجات
- ✅ إضافة وتعديل وحذف المنتجات
- ✅ بحث سريع بالاسم أو الباركود
- ✅ دعم الصور للمنتجات
- ✅ تصنيف المنتجات
- ✅ متابعة المخزون في الوقت الفعلي

### 🧾 نظام الفواتير المتقدم
- ✅ إنشاء فواتير بسرعة وسهولة
- ✅ بحث وإضافة منتجات بالاسم أو الباركود أو المسح
- ✅ تعديل الكميات والأسعار مباشرة
- ✅ حساب الخصم والضريبة تلقائياً
- ✅ دعم عملتين مع تحويل فوري

### 📷 ماسح الباركود
- ✅ مسح باركود بالكاميرا
- ✅ إضافة تلقائية إذا المنتج موجود
- ✅ إضافة منتج جديد إذا غير موجود
- ✅ إدخال يدوي للباركود
- ✅ دعم الفلاش وتبديل الكاميرا

### 💳 نظام الدفع
- ✅ دفع نقداً (USD/LBP)
- ✅ دفع بالبطاقة
- ✅ دفع مختلط
- ✅ حساب الباقي تلقائياً
- ✅ تحديث سعر الصرف

### 📊 تاريخ الفواتير
- ✅ عرض جميع الفواتير
- ✅ فلترة حسب اليوم/الأسبوع/الشهر
- ✅ بحث برقم الفاتورة أو اسم العميل
- ✅ عرض تفاصيل الفاتورة الكاملة
- ✅ إعادة طباعة ومشاركة

### 📦 إدارة المخزون
- ✅ متابعة الكميات المتوفرة
- ✅ تنبيهات للكمية القليلة والنفاذ
- ✅ إضافة وسحب كميات
- ✚ تعديل يدوي للمخزون

### ⚙️ الإعدادات
- ✅ اسم المتجر والمعلومات
- ✅ العملة الافتراضية
- ✅ سعر صرف قابل للتحديث
- ✅ نسبة الضريبة
- ✅ الوضع الداكن/الفاتح
- ✅ نسخ احتياطي تلقائي

### 💾 النسخ الاحتياطي
- ✅ تصدير قاعدة البيانات
- ✅ استيراد واستعادة البيانات
- ✅ نسخ احتياطي تلقائي كل 24 ساعة

## 🏗️ التقنيات المستخدمة

| التقنية | الاستخدام |
|---------|----------|
| **Flutter 3.2+** | إطار العمل الأساسي |
| **Dart 3.2+** | لغة البرمجة |
| **Riverpod** | إدارة الحالة |
| **go_router** | التنقل بين الشاشات |
| **Drift (SQLite)** | قاعدة البيانات المحلية |
| **mobile_scanner** | مسح الباركود |
| **pdf + printing** | توليد وطباعة PDF |

## 📁 هيكل المشروع

```
lib/
├── main.dart                          # نقطة الدخول
├── core/
│   ├── theme/
│   │   └── app_theme.dart            # الثيم (فاتح/داكن)
│   ├── routing/
│   │   └── app_router.dart           # إعداد التنقل
│   └── constants/
│       └── app_strings.dart          # النصوص والترجمة
├── data/
│   └── database/
│       ├── app_database.dart         # قاعدة البيانات Drift
│       └── database_provider.dart    # Providers للـ Repository
└── presentation/
    ├── providers/
    │   └── providers.dart            # State Management
    └── screens/
        ├── home/home_screen.dart     # الشاشة الرئيسية
        ├── products/products_screen.dart      # إدارة المنتجات
        ├── invoices/create_invoice_screen.dart # إنشاء فاتورة
        ├── inventory/inventory_screen.dart     # المخزون
        ├── settings/settings_screen.dart       # الإعدادات
        ├── backup/backup_screen.dart           # النسخ الاحتياطي
        ├── about/about_screen.dart             # عن التطبيق
        ├── barcode/barcode_scan_screen.dart    # ماسح الباركود
        ├── payment/payment_screen.dart         # الدفع
        ├── invoice_history/invoice_history_screen.dart  # سجل الفواتير
        └── invoice_history/invoice_detail_screen.dart  # تفاصيل الفاتورة
```

## 🚀 التثبيت والتشغيل

### المتطلبات المسبقة
1. **Flutter SDK** >= 3.2.0
2. **Dart SDK** >= 3.2.0
3. **Android Studio** (للبناء على Android)
4. **Xcode** (للبناء على iOS - macOS فقط)

### خطوات التثبيت

```bash
# 1. استنساخ المشروع
git clone https://github.com/alshiek1828/CashierLebanonPro.git
cd CashierLebanonPro

# 2. تثبيت الحزم
flutter pub get

# 3. تشغيل التطبيق
flutter run

# 4. بناء APK للإصدار
flutter build apk --release

# 5. بناء iOS
flutter build ios --release

# 6. بناء Web
flutter build web --release
```

## ⚠️ ملاحظات مهمة لتجنب الأخطاء

### ❌ أخطاء شائعة وكيفية حلها

#### 1. مشكلة `setTorchState()` غير موجود
**الحل:** استخدم `toggleTorch()` بدلاً منه:
```dart
// ❌ خطأ
_controller.setTorchState(TorchState.on);

// ✅ صحيح
_controller.toggleTorch();
```

#### 2. مشكلة `Icons.barcode` غير موجود
**الحل:** استخدم `Icons.qr_code_scanner`:
```dart
// ❌ خطأ
Icons.barcode

// ✅ صحيح
Icons.qr_code_scanner
```

#### 3. مشكلة `onError` parameter غير صالح
**الحل:** أزل معلمة `onError` من MobileScanner:
```dart
// ❌ خطأ
MobileScanner(
  onDetect: _onDetect,
  onError: (error) => print(error), // هذه المعرفة غير مدعومة
);

// ✅ صحيح
MobileScanner(
  onDetect: _onDetect,
);
```

#### 4. مشكلة الشاشة السوداء بعد Splash
**الحل:** تأكد من أن جميع Screens تعرض UI بغض النظر عن حالة البيانات:
```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('الشاشة')),
    body: FutureBuilder(
      future: someAsyncData,
      builder: (context, snapshot) {
        // ✅ دائماً أظهر شيئاً، حتى لو البيانات لم تحمل بعد
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return YourContent(data: snapshot.data!);
      },
    ),
  );
}
```

#### 5. مشكلة الاتجاه الأفقي (Landscape)
**الحل:** تأكد من:
1. AndroidManifest.xml يحتوي على `android:screenOrientation="portrait"`
2. إضافة هذا الكود في `main.dart`:
```dart
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const MyApp());
}
```

#### 6. مشكلة بناء iOS (`-G` flag error)
**الحل:** في GitHub Actions، استخدم `macos-14` بدلاً من `macos-latest`:
```yaml
runs-on: macos-14  # ✅ صحيح
# runs-on: macos-latest  # ❌ قد يسبب مشاكل
```

#### 7. مشكلة مسح الباركود على Web
**الحل:** Web لا يدعم الكاميرا بشكل كامل، لذا أضف خيار الإدخال اليدوي:
```dart
if (kIsWeb) {
  // Show manual entry dialog for web
} else {
  // Use camera scanner
}
```

## 🔧 إعداد CI/CD (GitHub Actions)

أنشئ ملف `.github/workflows/build_app.yml`:

```yaml
name: Build Cashier Lebanon Pro

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          
      - run: flutter pub get
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v3
        with:
          name: android-apk
          path: build/app/outputs/flutter-apk/app-release.apk

  build-ios:
    runs-on: macos-14  # ← مهم: استخدم macos-14
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          
      - run: flutter pub get
      - run: pod install
        working-directory: ios
        
      - run: flutter build ios --release --no-codesign
      - uses: actions/upload-artifact@v3
        with:
          name: ios-build
          path: build/ios/iphoneos/

  build-web:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'
          
      - run: flutter pub get
      - run: flutter build web --release
      - uses: actions/upload-artifact@v3
        with:
          name: web-build
          path: build/web/
```

## 📱 المنصات المدعومة

| المنصة | الحد الأدنى | الحالة |
|--------|-----------|--------|
| **Android** | API 21 (Android 5.0) | ✅ مدعوم بالكامل |
| **iOS** | iOS 12.0+ | ✅ مدعوم بالكامل |
| **Web** | Chrome, Firefox, Safari, Edge | ✅ مدعوم (باستثناء الكاميرا) |

## 🎨 التصميم

- **Material Design 3** - تصميم عصري واحترافي
- **RTL Support** - دعم كامل للغة العربية (من اليمين لليسار)
- **Dark Mode** - وضع داكن وفاتح
- **Responsive** - يتوافق مع مختلف أحجام الشاشات
- **Cairo Font** - خط عربي جميل وواضح

## 🗄️ قاعدة البيانات

التطبيق يستخدم **Drift (SQLite)** للتخزين المحلي:

### الجداول:
1. **Products** - المنتجات
2. **Invoices** - الفواتير
3. **InvoiceItems** - عناصر الفواتير
4. **AppSettings** - الإعدادات
5. **StockMovements** - حركات المخزون
6. **Categories** - التصنيفات

## 📄 الرخصة

© 2024 Cashier Lebanon Pro - جميع الحقوق محفوظة

## 🤝 المساهمة

نرحب بمساهماتكم! يرجى:
1. Fork المشروع
2. إنشاء فرع جديد (`git checkout -b feature/AmazingFeature`)
3. Commit التغييرات (`git commit -m 'Add some AmazingFeature'`)
4. Push الفرع (`git push origin feature/AmazingFeature`)
5. فتح Pull Request

## 📞 التواصل

- **البريد:** support@cashierlebanon.com
- **الموقع:** www.cashierlebanon.com

---

<div align="center">

**صُنع بـ ❤️ في لبنان 🇱🇧**

*Cashier Lebanon Pro - نظام نقاط بيع احترافي*

</div>
