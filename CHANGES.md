# ملخص الإصلاحات

جميع الإصلاحات محلية بالكامل — لا إضافة مكتبات جديدة ولا أي ربط خارجي، فقط تصحيح كود موجود.

## 1. `lib/main.dart`
- إعادة ترتيب التشغيل: الآن نطلب الأذونات الحرجة (`phone`, `systemAlertWindow`, `notification`) **قبل** تشغيل الخدمة الخلفية، بدل بعدها. هذا يمنع فشل الاستماع للمكالمات أو عرض النافذة العائمة بصمت في أول تشغيل.
- إضافة فحص `Permission.systemAlertWindow.isGranted` داخل `onStart` قبل محاولة عرض الـ Overlay، كحماية إضافية.

## 2. `lib/database/database_helper.dart`
- توحيد منطق اكتشاف اسم الجدول وأعمدة الهاتف/الاسم في دالة واحدة `_resolveSchema()` تُستخدم من كل من `searchByNumber` و `searchByName` (كان مكرراً وفيه سطر ميت يرجع `null` دائماً في `searchByNumber`).
- تخزين مؤقت (cache) لنتيجة اكتشاف المخطط بدل إعادة استعلام `PRAGMA` و `sqlite_master` في كل بحث — تحسين أداء.
- `getTotalRecordsCount` يستخدم الآن `COUNT(*)` الحقيقي بدل `MAX(rowid)` غير الدقيق عند وجود صفوف محذوفة.
- إضافة `_ensureIndexes()` تنشئ فهرس (`CREATE INDEX IF NOT EXISTS`) على عمودي الهاتف والاسم في الجدول المستورد فعلياً — يسرّع البحث بشكل كبير على جدول بملايين السجلات.
- تخفيض `PRAGMA mmap_size` من رقم غير واقعي (30 غيغابايت) إلى 2 غيغابايت.
- إضافة `debugPrint` في كل `catch` بدل الابتلاع الصامت الكامل، لتسهيل تشخيص أي مشكلة مستقبلية.

## 3. `lib/core/utils/name_utils.dart` (ملف جديد مساعد فقط، ليس ميزة)
- دالة موحّدة `splitNames()` لتقسيم الأسماء المدمجة، تُستخدم الآن في الشاشات الثلاث بدل ثلاث نسخ مختلفة قليلاً من نفس المنطق.
- دالة `extractMatchingName()` تصلح مشكلة كانت تسبب Crash (`RangeError`) عند استدعاء `list.first` على قائمة فارغة في `NameSearchView` القديمة.

## 4. `lib/views/name_search_view.dart`
- استخدام `NameUtils` بدل الكود المحلي المكرر.
- إصلاح احتمال الـ Crash في حالة اسم فارغ بالكامل.
- إضافة فحص `mounted` قبل `setState` بعد عملية غير متزامنة.

## 5. `lib/views/number_search_view.dart`
- استخدام `NameUtils.splitNames()` بدل `RegExp` محلي منفصل.
- إضافة `dispose()` لتحرير `_searchController` (لم يكن موجوداً سابقاً).
- إضافة فحص `mounted`.

## 6. `lib/overlay_window.dart`
- استخدام `NameUtils.splitNames()` بدل الكود المحلي.
- توضيح أن زر "إضافة جهة اتصال" بلا تنفيذ فعلي (تم تعطيله صراحة `onPressed: null` بدل ترك دالة فارغة موهمة بأنها تعمل).

## 7. `lib/home_screen.dart`
- تسجيل أخطاء `safeScan` عبر `debugPrint` بدل الابتلاع الصامت الكامل.
- إضافة فحوصات `mounted` قبل استخدام `context` بعد عمليات غير متزامنة (async gaps) لمنع تحذيرات/أخطاء محتملة لو أُغلقت الشاشة أثناء الاستيراد.

## 8. `lib/zip_decompressor.dart`
- **تم حذفه بالكامل** بناءً على تأكيدك أنك لم تعد تستخدم آلية الاستيراد من ملف مضغوط، وأصبحت تقرأ ملف قاعدة البيانات مباشرة. كان هذا الملف كوداً ميتاً غير مستخدم أصلاً في أي مكان بالواجهة.

## ملفات لم تتغير
`lib/core/widgets/smart_search_indicator.dart`, `lib/core/constants/app_constants.dart`, `lib/core/theme/app_colors.dart` — نُسخت كما هي دون أي تعديل لأنه لم توجد فيها مشاكل.

---

## ⚠️ ملاحظة مهمة لم تُصلح تلقائياً (تحتاج قراراً منك)
صلاحية `Permission.manageExternalStorage` في `home_screen.dart` ما زالت كما هي (لم أغيّرها لأن تضييقها يتطلب إضافة مكتبة جديدة مثل `file_picker`، وأنت طلبت عدم أي إضافات). فقط تذكير: هذه الصلاحية حساسة عند النشر على Google Play وتحتاج تبريراً موثقاً إن قررت النشر لاحقاً.
