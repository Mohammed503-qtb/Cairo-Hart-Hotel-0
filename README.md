# فندق قلب القاهرة — عدن | Cairo Heart Hotel — Aden

منصة فندقية متكاملة أحادية قاعدة البيانات: **موقع حجز عام + تطبيق ضيف + وضع استقبال + وضع إدارة** فوق قاعدة بيانات مركزية واحدة، مع اتصال فوري (Socket.IO) وتدقيق كامل للعمليات.

> **Cairo Heart Hotel — Aden**: a single-database hotel platform combining a public booking website, a guest app, a reception console, and an admin console — with realtime updates, deterministic pricing, hashed access codes, and a full audit trail.

---

## 1) نظرة عامة | Overview

| القناة | الوصف | الدخول |
|---|---|---|
| **الموقع العام** | صفحات الفندق، أنواع الغرف، المرافق، بحث التوفر، محرك الحجز، إدارة/إلغاء الحجز | زائر عادي — بلا تسجيل |
| **تطبيق الضيف** | الإقامة، طلب الخدمات، المحادثة الفورية، الفاتورة، التمديد، تغيير الغرفة، طلب الخروج | كود ضيف (يُولّد عند Check-In) |
| **الاستقبال** | الوصولات، المغادرات، المقيمون، Check-In/Check-Out، الطلبات، الغرف، المدفوعات، البحث الفوري | كود استقبال |
| **الإدارة** | لوحة تحكم، إعدادات الفندق، أنواع/غرف/معدلات/خدمات، الطاقم والأكواد، الحجوزات، التقارير، سجل التدقيق | كود إدارة |

### المفاهيم الجوهرية (Domain)
- **Reservation** = وعد بالحجز (يُنشأ من الموقع)، **Stay** = الإقامة الفعلية (تُنشأ عند Check-In).
- البيع يكون على **Room Type**؛ الغرفة الفعلية تُخصيص عند الوصول فقط.
- **Booking Reference** (مثل `HTL-2026-000421`) للتتبع فقط — لا يُستخدم للدخول.
- **Access Codes** (مثل `H834729X7`) هي وسيلة الدخول الوحيدة للتطبيق، تُخزن هاش SHA-256 ولا تُعرض خامًا إلا مرة واحدة عند التوليد.

---

## 2) التقنيات | Tech Stack

- **Next.js 16 (App Router) + TypeScript 5** — الواجهة والمسارات
- **Tailwind CSS 4 + shadcn/ui (New York) + Lucide** — نظام المكونات
- **Prisma ORM + SQLite** — قاعدة بيانات مركزية واحدة (المال بالسنت — أعداد صحيحة)
- **Socket.IO (mini-service منفصل)** — بث الأحداث الفوري
- **Zustand** — حالة العميل
- **Framer Motion** — الحركات والانتقالات
- واجهة عربية RTL بالكامل (خط Cairo) مع وضع ليلي/نهاري

---

## 3) التشغيل محليًا | Local Setup

```bash
# 1) تثبيت الاعتماديات
bun install

# 2) تهيئة ملف البيئة
cp .env.example .env
# ثم عدّل DATABASE_URL إلى المسار المطلق لقاعدة بياناتك إن لزم
# مثال: DATABASE_URL="file:/home/user/Cairo-Hart-Hotel-0/db/custom.db"

# 3) إنشاء قاعدة البيانات ودفع المخطط
bun run db:push

# 4) تعبئة بيانات العرض التجريبية (فندق + 14 غرفة + خدمات + حجوزات + طاقم)
bun prisma/seed.ts

# 5) تشغيل خدمة الوقت الفوري (Socket.IO)
cd mini-services/realtime && bun install && bun run dev

# 6) تشغيل التطبيق
bun run dev
# ← http://localhost:3000
```

> **متطلب**: [Bun](https://bun.sh) runtime.

---

## 4) أكواد الدخول التجريبية | Demo Access Codes

| الدور | الكود | ملاحظات |
|---|---|---|
| ضيف (خالد يوسف — غرفة 201) | `H834729X7` | إقامة جارية |
| ضيف (نورا سعيد — غرفة 103) | `H119922K4` | مغادرة اليوم |
| استقبال | `R492671M3` | كامل صلاحيات الاستقبال |
| إدارة | `A371849L9` | كامل صلاحيات الإدارة |

> توليد أكواد جديدة: من **الاستقبال** عند Check-In (كود ضيف)، أو من **الإدارة → الطاقم والأكواد** (أكواد استقبال/إدارة). الكود الخام يظهر مرة واحدة فقط.

---

## 5) بنية المشروع | Structure

```
├── prisma/                  # schema.prisma (20 نموذجًا) + seed.ts
├── db/                      # ملفات SQLite (غير مؤرشفة — تُولّد محليًا)
├── src/
│   ├── app/
│   │   ├── page.tsx         # SPA رئيسية: website / login / guest / reception / admin
│   │   └── api/
│   │       ├── public/      # hotel, room-types, availability, bookings, lookup, cancel
│   │       ├── auth/        # validate, logout
│   │       ├── guest/       # 15 مسارًا — كلها تتحقق من جلسة الضيف
│   │       ├── reception/   # 17 مسارًا — Check-In/Out, الطلبات, الغرف, الفواتير...
│   │       └── admin/       # 17 مسارًا — الإعدادات, الأنواع, الغرف, المعدلات, التقارير...
│   ├── components/
│   │   ├── website/         # موقع الفندق العام + محرك الحجز
│   │   ├── guest/           # تطبيق الضيف
│   │   ├── reception/       # وحدة الاستقبال
│   │   ├── admin/           # وحدة الإدارة
│   │   └── ui/              # مكونات shadcn/ui
│   └── lib/                 # codes (توليد/هاش) · pricing (محرك التسعير) · availability · auth · audit · events...
├── mini-services/realtime/  # خدمة Socket.IO مستقلة (بث الأحداث)
├── public/images/           # صور الفندق والغرف والمرافق
├── MASTER_PLAN.md           # الخطة الرئيسية التنفيذية الكاملة
└── upload/                  # وثائق الخطة الأصلية (الموقع + التطبيق)
```

---

## 6) الأمان | Security Highlights

- الأكواد مخزنة **SHA-256 hashed** — لا تُخزن خامًا أبدًا
- كل مسارات `guest/` و`reception/` و`admin/` تتحقق من الجلسة والدور (RBAC) قبل أي عملية
- **Rate limiting** على مسار التحقق من الأكواد
- **Audit Log** شامل لكل العمليات الحساسة (Check-In/Out، الأكواد، المدفوعات، الإلغاء...)
- عزل بيانات الضيف: كل مسار يعيد بيانات إقامة الضيف الحالي فقط
- التسعير حتمي **server-side** مع **Price Snapshot** محفوظ وقت الحجز (لا يتغير بعده)

---

## 7) الوثائق | Documentation

- [`MASTER_PLAN.md`](./MASTER_PLAN.md) — الخطة الرئيسية التنفيذية (النطاق، النماذج، آلات الحالة، العقود، المراحل 0-13، DoD)
- [`upload/PLAN_WEBSITE.md`](./upload/PLAN_WEBSITE.md) — خطة الموقع الأصلية
- [`upload/PLAN_ MOBILE-APK.md`](./upload/PLAN_%20MOBILE-APK.md) — خطة تطبيق الموبايل الأصلية
- [`worklog.md`](./worklog.md) — سجل العمل التنفيذي لكل مرحلة

---

**فندق قلب القاهرة — عدن** · بُني فوق Next.js 16 · جاهز للتوسع إلى تطبيق Flutter (Guest/Reception/Admin) فوق نفس الـ API.
