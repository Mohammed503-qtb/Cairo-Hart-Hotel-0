# فندق قلب القاهرة — عدن | تطبيق الضيف (Flutter)

> تطبيق Android/iOS لضيوف الفندق — **المرحلة F1** (نقل تصميم مُجرَّب من تطبيق الويب).
> المرجع السلوكي الوحيد: الواجهة الويب المناظرة + عقد API في `docs/CONTRACTS.md`.

## البنية

```
mobile/
├── lib/
│   ├── main.dart            # الإطلاق
│   ├── app.dart             # MaterialApp + RTL + الثيم + دورة الجلسة
│   ├── config.dart          # عنوان الخادم (--dart-define أو إدخال المستخدم)
│   ├── core/                # ApiClient (401→renew) + تنسيق عربي
│   ├── models/guest.dart    # نماذج قناة الضيف G-01..G-16
│   ├── state/               # SessionController + GuestStore
│   ├── services/            # RealtimeService (Socket.IO — F2)
│   ├── ui/                  # الثيم (كحلي/ذهبي + Cairo) + مكونات مشتركة
│   └── screens/             # الشاشات (دخول، هيكل الضيف، التبويبات، الحوارات)
├── android/                 # منصة Android (flavors: dev/prod)
├── test/                    # اختبارات (bun تعادلها: flutter test)
└── assets/                  # خط Cairo + الشعار
```

## التشغيل محليًا

يتطلب Flutter SDK (اختُبر مع 3.29.x):

```bash
cd mobile
flutter pub get
flutter analyze
flutter test

# تشغيل على محاكي/جهاز (نسخة التطوير):
flutter run --flavor dev --dart-define=APP_ENV=dev

# بناء إصدار:
flutter build apk --release --flavor prod --dart-define=APP_ENV=prod --dart-define=API_BASE_URL=https://YOUR-HOTEL-DOMAIN --dart-define=APP_VERSION=1.0.0
```

## عنوان الخادم

- عند البناء بـ `--dart-define=API_BASE_URL=https://…` يصبح العنوان ثابتًا ولا يظهر للمستخدم.
- بدونه: تظهر «إعدادات الخادم» في شاشة الدخول ويُخزَّن العنوان محليًا (لكل بناء dev الافتراضي).
- Realtime: socket.io على `/` مع `XTransformPort=3002` (نفس طوبولوجيا الويب).

## إصدار التطبيق وحد التحديث (F6)

- إصدار البناء يُدمج عبر `--dart-define=APP_VERSION=x.y.z` — CI يستخرجه تلقائيًا من `pubspec.yaml` (الافتراضي المحلي `0.0.0`).
- عند الإطلاق يفحص التطبيق `GET /api/public/app-config` (PUB-07، بلا مصادقة): إن كان `minAppVersion` أعلى من إصدار البناء → شاشة حجب «يتوفر تحديث مطلوب» برابط الإصدارات (قابل للنسخ) وزر «إعادة المحاولة».
- الأدمن يضبط الحد من إعدادات الفندق (A-03: حقل «أقل إصدار مسموح للتطبيق») — فارغ = لا فرض. فشل الفحص متسامح (التطبيق يُكمل تشغيله).

## المصادقة (عقد §1.2.1 — STABLE)

- `POST /api/auth/validate` بالكود → `{token, role, name, expiresAt}` (Bearer، عمر ≤ 12 ساعة).
- `renew` عند الإطلاق/العودة للمقدمة — نفس التوكن يُمدَّد.
- أي 401 نهائي → مسح التوكن → شاشة الكود (بلا refresh-token).

## التوقيع والإصدار (CI)

- GitHub Actions: `mobile-ci.yml` (analyze + test) و`mobile-release.yml` (APK موقَّع + GitHub Release).
- مفتاح التوقيع **لا يُرفع للمستودع** — يُحقن من Secrets:
  `KEYSTORE_BASE64` · `KEYSTORE_PASSWORD` · `KEY_ALIAS` · `KEY_PASSWORD`.
- وضع RECEPTION/ADMIN: شاشة إرشادية فقط (F4/F5 لاحقًا).

## أكواد العرض التجريبية (بيئة seed فقط)

- ضيف: `H834729X7` (خالد يوسف — غرفة 201)
- تُمسح قبل الإنتاج (قاعدة إدارة المخاطر §11).
