# تطبيق Caller ID - معرف المتصل

تطبيق Flutter احترافي للتعرف على هوية المتصلين دون الحاجة للاتصال بالإنترنت (Offline Caller ID).

## 📱 نظرة عامة

تطبيق Caller ID هو تطبيق Flutter متقدم يعمل على أنظمة Android و iOS و Windows و Linux و macOS و Web، مصمم لتوفير خدمة التعرف على هوية المتصلين بشكل محلي دون الحاجة لاتصال بالإنترنت.

## ✨ المميزات

- **عمل بدون إنترنت**: قاعدة بيانات محلية للتعرف على الأرقام
- **دعم متعدد المنصات**: يعمل على Android, iOS, Windows, Linux, macOS, Web
- **إدارة الصلاحيات**: تحكم كامل في صلاحيات الوصول للهاتف وجهات الاتصال
- **إشعارات محلية**: نظام إشعارات متقدم لإعلام المستخدم بالمكالمات
- **خدمة خلفية**: تشغيل الخدمة في الخلفية لمراقبة المكالمات
- **خط عربي**: دعم كامل للغة العربية بخط Cairo

## 🛠️ التقنيات المستخدمة

### المكتبات الأساسية:
- **Flutter SDK**: إطار العمل الأساسي
- **path_provider**: إدارة مسارات الملفات
- **sqflite**: قاعدة بيانات SQLite المحلية
- **permission_handler**: إدارة صلاحيات التطبيق
- **phone_state**: مراقبة حالة المكالمات الهاتفية
- **archive**: فك ضغط الملفات
- **file_picker**: اختيار الملفات من الجهاز
- **flutter_overlay_window**: النوافذ العائمة
- **flutter_background_service**: الخدمة الخلفية
- **flutter_local_notifications**: الإشعارات المحلية

### الخطوط:
- **Cairo**: خط عربي احترافي للعناصر الواجهة

## 📋 المتطلبات

- Dart SDK: >=3.3.0 <4.0.0
- Flutter SDK

## 🚀 التثبيت والتشغيل

1. استنساخ المشروع:
```bash
git clone <repository-url>
cd caller_id_app
```

2. تثبيت المكتبات:
```bash
flutter pub get
```

3. تشغيل التطبيق:
```bash
flutter run
```

## 📦 البناء والإصدار

الإصدار الحالي: 1.0.0+1

### بناء للتطبيقات المختلفة:

**Android:**
```bash
flutter build apk
flutter build appbundle
```

**iOS:**
```bash
flutter build ios
```

**Windows:**
```bash
flutter build windows
```

**Linux:**
```bash
flutter build linux
```

**macOS:**
```bash
flutter build macos
```

**Web:**
```bash
flutter build web
```

## 🏗️ بنية المشروع

```
caller_id_app/
├── lib/                  # كود مصدر Flutter
├── assets/              # الموارد الثابتة
│   └── fonts/          # خطوط Cairo
├── android/            # ملفات مشروع Android
├── ios/                # ملفات مشروع iOS
├── windows/            # ملفات مشروع Windows
├── linux/              # ملفات مشروع Linux
├── macos/              # ملفات مشروع macOS
├── web/                # ملفات مشروع Web
└── test/               # اختبارات الوحدة
```

## 🔧 التكوين

### تحليل الكود:
تم تكوين `analysis_options.yaml` لتشجيع ممارسات البرمجة الجيدة باستخدام `flutter_lints`.

### إدارة المكتبات:
لتحديث المكتبات تلقائياً لأحدث الإصدارات:
```bash
flutter pub upgrade --major-versions
```

لرؤية المكتبات التي لها إصدارات أحدث:
```bash
flutter pub outdated
```

## 📚 الموارد التعليمية

للبدء مع تطوير Flutter:
- [مختبر: كتابة أول تطبيق Flutter](https://docs.flutter.dev/get-started/codelab)
- [كتاب الطبخ: عينات Flutter مفيدة](https://docs.flutter.dev/cookbook)
- [التوثيق الرسمي](https://docs.flutter.dev/) - يحتوي على دروس وعينات ومرجع API كامل

## 📝 الترخيص

هذا المشروع خاص ولا يُنشر على pub.dev.

## 👥 المساهمة

للمساهمة في المشروع، يرجى إنشاء فرع جديد وتقديم طلب سحب (Pull Request) مع وصف واضح للتغييرات.

---

**ملاحظة**: تم تطوير هذا التطبيق ليعمل بشكل أساسي كمعرف متصل دون اتصال بالإنترنت، مع دعم كامل للغة العربية.
