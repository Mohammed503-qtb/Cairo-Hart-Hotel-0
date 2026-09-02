# HOTEL PLATFORM — MASTER PLAN (وثيقة تنفيذية ملزمة)

**فندق قلب القاهرة — عدن**
Website + Booking Engine + Mobile App (Guest / Reception / Admin) + Central Backend + WhatsApp

| البند | القيمة |
|---|---|
| نوع الوثيقة | Master Plan تنفيذي ملزم (Executable Baseline) |
| الإصدار | 1.0 |
| الحالة | Execution Baseline — مصدر الحقيقة الوحيد للتنفيذ |
| النطاق | المنصة الفندقية الكاملة: الموقع + محرك الحجز + التطبيق + الاستقبال + الإدارة + Backend مركزي |
| وثائق المصدر | `PLAN_WEBSITE.md` v1.0 — `PLAN_MOBILE-APK.md` v1.0 — HOTEL WEBSITE — MASTER PLAN (الرسالة الموحدة) |
| اللغة الأساسية | العربية (RTL) — الإنجليزية ثانوية (LTR) |
| العملة الافتراضية | USD (قابلة للتهيئة لكل فندق — تُخزَّن العملة الفعلية صراحةً مع كل مبلغ) |
| المنطقة الزمنية | Asia/Aden — كل حسابات التواريخ تجري بالتوقيت المحلي للفندق المخزَّن في الإعدادات |
| الجهة المستهدفة | AI Coding Agent + فريق التنفيذ |

> **الغرض:** هذه الوثيقة تحوّل خطتي الموقع والتطبيق إلى عقد تنفيذ واحد. كل ما ليس مذكورًا فيها صراحةً يُعد خارج النطاق حتى يُضاف بقرار موثّق. كل ما هو مذكور بصيغة MUST إلزامي، وSHOULD يُنفَّذ إلا بعذر موثّق، وMUST NOT محظور لا استثناء له.

---

## 0. دليل قراءة الوثيقة — اقرأ هذا أولًا

### 0.1 دلالات الإلزام (RFC 2119)

| المصطلح | الدلالة |
|---|---|
| **MUST / إلزامي** | مطلوب دون استثناء. عدم تنفيذه = المرحلة غير مكتملة |
| **SHOULD / يُستحسن** | يُنفَّذ افتراضيًا. الاستثناء يتطلب تسجيله في `docs/decisions/` مع السبب |
| **MAY / اختياري** | مساحة تقديرية للوكيل بشرط عدم خرق أي MUST |
| **MUST NOT / محظور** | ممنوع نهائيًا. خرقه = فشل المراجعة وإعادة العمل |

### 0.2 قواعد أسبقية القرارات

1. هذه الوثيقة (MASTER_PLAN.md) هي **الأعلى أسبقية**.
2. عند أي تعارض ظاهري مع `PLAN_WEBSITE.md` أو `PLAN_MOBILE-APK.md`، تُعتمد صياغة هذه الوثيقة.
3. عند تعارض متطلب مع قيد تقني حقيقي (مثلًا مزود دفع لا يدعم ميزة)، يُسجَّل القرار البديل في `docs/decisions/ADR-XXX.md` قبل التنفيذ.
4. الوكيل **MUST NOT** يبتكر سلوكًا تجاريًا غير منصوص عليه (أسعار، سياسات، حالات، صلاحيات) «لإكمال الشاشة».

### 0.3 اصطلاحات التسمية (ملزمة عبر كل المستودع)

| المجال | الاصطلاح | مثال |
|---|---|---|
| كيانات الدومين (Classes/Types) | PascalCase مفرد | `Reservation`, `ServiceRequest` |
| جداول قاعدة البيانات | snake_case جمع | `reservations`, `service_requests` |
| أعمدة قاعدة البيانات | snake_case | `check_in_date`, `guest_id` |
| حقول JSON في الـ API | camelCase | `bookingReference`, `checkInDate` |
| مسارات الـ API | kebab-case للموارد | `/service-requests`, `/room-types` |
| Enums | UPPER_SNAKE_CASE | `IN_HOUSE`, `PAYMENT_PENDING` |
| مفاتيح الترجمة | `module.key.snake_case` | `guest.home.welcome` |
| معرّفات الكيانات | UUID v4 (داخلي) + مراجع مقروءة للعامة | `HTL-2026-000421` |

### 0.4 قواعد عامة ملزمة للتنفيذ

- **MUST**: كل منطق حرج (توفر، أسعار، تأكيد، صلاحيات، حالات دفع) يُنفَّذ في الـ Backend. الواجهات (Web/Flutter) تعرض وتجمع مدخلات فقط.
- **MUST**: كل التواريخ تُخزَّن UTC، وتُعرض/تُحسب حسب توقيت الفندق. عدد الليالي يُحسب من حدود الأيام لا من الطوابع الزمنية.
- **MUST**: كل المبالغ `DECIMAL(12,2)` — يُمنع حساب المال بأرقام عشرية ثنائية عائمة (float/double).
- **MUST**: كل عملية كتابة حرجة (حجز، دفع، Check-In/Out، توليد كود) تُسجَّل في `AuditLog`.
- **MUST NOT**: أي Secret أو مفتاح مزود يظهر في كود الواجهات أو مستودع Git.
- **MUST NOT**: أي واجهة تعتبر نتيجة التوفر أو السعر أو الدفع من جهة العميل حقيقة نهائية.

### 0.5 خريطة الوثيقة

| القسم | المحتوى |
|---|---|
| PART I | القرارات المعمارية الملزمة (ADR) |
| PART II | نموذج الدومين (Domain Model) و الثوابت التجارية |
| PART III | آلات الحالة (State Machines) لكل كيان |
| PART IV | مخطط قاعدة البيانات الكامل + استراتيجية Concurrency |
| PART V | نموذج الهوية والأكواد (Access Codes) والجلسات |
| PART VI | الصلاحيات والأدوار (RBAC) |
| PART VII | عقود الـ API (API Contracts) |
| PART VIII | الأحداث والإشعارات (Events & Notifications) |
| PART IX | الشاشات وRoute Map (Website + Guest + Reception + Admin) |
| PART X | هياكل المشاريع (Monorepo / Backend / Flutter / Web) |
| PART XI | الأمان، الاختبارات، الأداء، المراقبة، CI/CD |
| PART XII | مراحل تنفيذ الـ AI Coding Agent (0–13) مع MUST/SHOULD/MUST NOT وAcceptance Criteria |
| PART XIII | Definition of Done النهائي وبوابات الإصدار |
| الملاحق | قاموس المصطلحات + خارج النطاق + سجل التغييرات |

---

## PART I — القرارات المعمارية الملزمة (ADRs)

> هذه القرارات نهائية. تغيير أي منها يتطلب ADR جديد موثّق وموافقة المالك.

### ADR-001 — منصة واحدة مركزية وليست أنظمة منفصلة

**القرار:** يوجد نظام مركزي واحد (Central Hotel Platform) فوق قاعدة بيانات واحدة، تخدمه ثلاث قنوات أمامية: الموقع، التطبيق (Flutter)، وواتساب.

```
CENTRAL HOTEL PLATFORM
                       │
          ┌────────────┼────────────┐
          │            │            │
          ▼            ▼            ▼
       Website     Mobile App    WhatsApp
          │            │            │
          └────────────┼────────────┘
                       │
                       ▼
                CENTRAL API
                       │
                       ▼
                 DATABASE
```

**MUST:**
- كل القنوات تقرأ وتكتب في نفس البيانات المركزية عبر نفس الـ API.
- حجز واتساب/هاتفي/مباشر ينشئ `Reservation` بنفس محرك الحجز وبنفس صيغة `booking_reference` مع `source` مختلفة.

**MUST NOT:**
- بناء نظام حجز خاص بواتساب أو نسخة ثانية من منطق الأسعار لأي قناة.

---

### ADR-002 — الـ Backend هو مصدر قواعد الأعمال الوحيد

**القرار:** كل منطق الأعمال والتحقق يعيش في الـ Backend. Flutter وWeb عملاء رقيقون (Thin Clients).

**MUST:**
- كل Endpoint يتحقق من الجلسة والصلاحية والمدخلات قبل أي تنفيذ.
- الواجهة تعرض حالة «قيد المعالجة» ولا تدّعي النجاح قبل استجابة الخادم.

**MUST NOT:**
- وضع التوفر/الأسعار/التأكيد/صلاحيات المستخدم/حالة الدفع كمنطق نهائي داخل Flutter أو المتصفح.
- اعتماد أي تعديل بيانات من التطبيق دون تحقق Server-side.

---

### ADR-003 — الفصل بين Reservation وStay

**القرار:** الحجز (Reservation) هو الوعد قبل الوصول؛ الإقامة (Stay) هي الحقيقة التشغيلية بعد الوصول.

```
Guest → Reservation → Check-In → Stay → Physical Room → Guest Code
```

**MUST:**
- الموقع يبيع Room Type على مستوى `Reservation/ReservationItem`.
- `Stay` يُنشأ عند Check-In ويُربط بغرفة فعلية واحدة (`Room`) وكود ضيف واحد.
- `booking_reference` يبقى للتتبع فقط ولا يصلح لتسجيل دخول التطبيق.

---

### ADR-004 — البيع على مستوى Room Type والتعيين على مستوى Room

**القرار:** الزائر يحجز «Deluxe Room» (نوع). رقم الغرفة الفعلي يُعيَّن عند Check-In من الاستقبال.

**MUST:**
- عدّاد المخزون يُحسب على مستوى النوع (عدد الغرف الفعلية الفعالة للنوع).
- `Room.status` تعكس الحالة الفيزيائية/التشغيلية (AVAILABLE/OCCUPIED/RESERVED/CLEANING/DIRTY/OUT_OF_ORDER).

---

### ADR-005 — المصادقة بالأكواد الديناميكية (Code-Based Auth)

**القرار:** أربع هويات متميزة: `Booking Reference` (تتبع فقط) و`Guest Code` و`Reception Code` و`Admin Code`. الكود يولّد Session Token بعد تحقق الخادم.

**MUST:**
- التحقق من الكود Server-side حصرًا، مع Rate Limiting وHashing (التفاصيل في PART V).
- كل كود له صلاحية واحدة فقط (persona واحدة) — كود الضيف لا يفتح وضع الاستقبال أبدًا.

**MUST NOT:**
- استخدام `booking_reference` كبيانات دخول للتطبيق أو كوسيلة وصول إدارية وحيدة.

---

### ADR-006 — Monorepo واحد

**القرار:** هيكل Monorepo موحّد: `apps/web` (Next.js) و`apps/mobile` (Flutter) و`backend/` و`packages/*` للعقود المشتركة.

**MUST:**
- مشاركة العقود (API Contracts / OpenAPI) والنماذج المشتركة وDesign Tokens عبر `packages/`.
- كل تغيير في عقد API يبدأ من `packages/api-contracts` ثم توليد العملاء.

**MUST NOT:**
- مشاركة كود الواجهات قسرًا بين Web وMobile — ما يُشارك هو العقود والنماذج والقواعد فقط.

---

### ADR-007 — تجهيزات الـ Backend (Stack Reference)

**القرار:** الـ Backend بلغة TypeScript فوق NestJS، وقاعدة البيانات PostgreSQL عبر Prisma، مع Redis اختياري للـ Rate Limiting والطوابير. قاعدة التطوير المحلي: SQLite عبر Prisma.

| الطبقة | التقنية |
|---|---|
| API Framework | NestJS (TypeScript, Modular) |
| ORM | Prisma |
| قاعدة البيانات الإنتاجية | PostgreSQL 16+ |
| الكاش / الطوابير | Redis (اختياري — MUST تعمل المنصة بدونه مع بدائل في-الذاكرة) |
| الموقع | Next.js (App Router) — يستهلك الـ API المركزي ولا يملك نسخة ثانية من منطق الحجز |
| التطبيق | Flutter (Android + iOS) — بنية طبقية Clean Architecture |

**MUST:**
- الويب والتطبيق يستهلكان نفس الـ API المركزي.
- الـ Backend مقسّم إلى Modules واضحة (انظر PART X) لكل منها Use Cases.

**MUST NOT:**
- بناء منطق حجز مستقل داخل Next.js Server Actions منفصل عن الـ API المركزي.

---

### ADR-008 — OpenAPI هو مصدر عقود الـ API الوحيد

**القرار:** `packages/api-contracts/openapi.yaml` هو المصدر. عملاء الـ API (Flutter/Web) يُولَّدون منه.

**MUST:**
- أي Endpoint جديد يُضاف أولًا إلى OpenAPI ثم يُولَّد العميل ثم يُنفَّذ.
- الـ Backend يُختبر ضد Contract Tests مستخرجة من نفس الملف.

---

### ADR-009 — الدفع طبقة تجريدية مُتحقَّق منها

**القرار:** `PaymentProvider` واجهة تجريدية. نجاح الدفع يقرره المزود عبر Webhook/تحقق خادمي، لا الواجهة.

```
Guest Starts Payment → Provider → Verification/Webhook → Payment State → Reservation State
```

**MUST:**
- Webhook idempotent + التحقق من التوقيع + تسجيل كل محاولة في `payment_attempts`.
- كل عملية دفع/حجز تقبل `Idempotency-Key`.
- دعم الطرق: Online / Pay at Hotel / Deposit / Partial / Manual (حسب تفعيل الفندق).

**MUST NOT:**
- اعتبار الدفع ناجحًا من المتصفح أو التطبيق وحده، أو اختراع سلوك دفع غير موجود لدى المزود.

---

### ADR-010 — الإشعارات طبقة منفصلة عن صحة الأعمال

**القرار:**

```
NotificationService
   ├── WhatsAppProvider
   ├── EmailProvider
   ├── PushProvider
   └── InAppProvider
```

**MUST:**
- فشل واتساب/إيميل لا يُفشل الحجز — يُسجَّل `NotificationAttempt` بحالة FAILED ويُعاد المحاولة.
- القوالب تُدار مركزيًا مع placeholders آمنة (`{{guest_name}}` …).

**MUST NOT:**
- استيراد WhatsApp SDK مباشرة داخل خدمة الحجز.

---

### ADR-011 — Snapshot السعر غير قابل لإعادة الكتابة

**القرار:** عند تأكيد الحجز تُحفظ لقطة سعر كاملة (`ReservationPriceSnapshot`). تغيير الأسعار لاحقًا لا يغيّر الحجوزات التاريخية.

**MUST:**
- كل تعديل حجز (تمديد/تغيير نوع) ينشئ Snapshot جديدًا مرقّمًا (versioned) ويحفظ القديم.

---

### ADR-012 — نظام أحداث للأثر الجانبي

**القرار:** الأحداث الدومينية (`ReservationConfirmed`, `GuestCheckedIn`, `RequestCreated`, `PaymentRecorded`, `ExtensionApproved`, `RoomChanged`, `CheckoutCompleted`…) هي المحرّض الوحيد للإشعارات/Push/توثيق Audit/تحديث الواجهات الفورية.

**MUST:**
- كل حدث يُسجَّل ويطلق معالجاته بطريقة معزولة الفشل (فشل معالج لا يُفشل العملية الأصلية).

---

### ADR-013 — عربي أولًا مع RTL كامل

**القرار:** العربية هي اللغة الأساسية باتجاه RTL كامل، والإنجليزية LTR ثانوية. أي شاشة تُسلَّم غير داعمة للغتين والاتجاهين تُعد غير مكتملة.

---

### ADR-014 — واتساب قناة وليس نظامًا

**القرار:** واتساب = Channel (إشعار + دعم + تحويل إلى Request). لا يُخزَّن كوقائع حجز ولا يصبح مصدر الحقيقة.

---

### ADR-015 — الخادم هو المرجع دائمًا (No Offline Authoritative Ops)

**القرار:** لا Offline booking/payment/check-in/checkout/room-assignment. يُسمح لاحقًا بكاش قراءة فقط للبيانات غير الحرجة.

---

### ADR-016 — منع الحجز المزدوج ذريًّا

**القرار:** التأكيد النهائي يمر بمعاملة ذرية (DB Transaction + قفل فهرس/صف) تعيد فحص المخزون داخل المعاملة. الخاسر يستقبل: «الغرفة لم تعد متاحة».

**MUST:**
- الاعتماد على قيود قاعدة البيانات والمعاملات، لا على ترتيب الواجهة.

---

### ADR-017 — هوية الحجز العامة محمية بتحقق ثانٍ

**القرار:** Manage Booking يتطلب `booking_reference` + قيمة تحقق (هاتف أو بريد). لا يُكشف وجود حجز لمجرّد تخمين المرجع.

<!-- APPEND -->

---

## PART II — نموذج الدومين (Domain Model) والثوابت التجارية

### 2.1 المفاهيم الجوهرية

```
Guest ──→ Reservation ──→ Check-In ──→ Stay ──→ Physical Room
              │                             └──→ Guest Access Code
              ├──→ Price Snapshot (غير قابل لإعادة الكتابة)
              ├──→ Payments
              └──→ Documents/Notifications
Stay ├──→ Service Requests ──→ Request Updates
      ├──→ Messages (Chat)
      ├──→ Charges (الفواتير الإضافية)
      ├──→ Extension Requests
      ├──→ Room Change Requests
      └──→ Feedback
```

- **Reservation** = الوعد قبل الوصول (يبيع Room Type).
- **Stay** = الحقيقة التشغيلية بعد الوصول (مرتبط بغرفة فعلية واحدة).
- **Booking Reference (HTL-…)** للتتبع فقط — لا يصلح للدخول.
- **Access Code** هو بوابة الهوية: ضيف H… / استقبال R… / إدارة A…

### 2.2 الثوابت التجارية (Invariants) — كلها مفروضة في الخادم

| # | الثابت | مكان الفرض |
|---|---|---|
| I1 | لا حجز مؤكد فوق المخزون | `availableRoomCount` داخل `$transaction` عند الإنشاء |
| I2 | لا دفع ناجح كاذب | المزود/الخادم يقرر — الواجهة لا تدّعي النجاح |
| I3 | ضيف لا يرى بيانات ضيف آخر | `requireRole('GUEST')` + فلترة stayId في كل مسار |
| I4 | كود منتهٍ/ملغي لا يعمل | فحص status + expiresAt مع كل طلب |
| I5 | مرجع حجز واحد لحجز واحد | `bookingReference @unique` |
| I6 | لا يُعتمد سعر من العميل | `computeQuote` يُعاد حسابه خادميًا عند الإنشاء |
| I7 | لا حجز مزدوج | معاملة ذرية + إعادة فحص التوفر داخلها |
| I8 | لا دفع مكرر | Idempotency Key + Payment مرتبط بالحجز |
| I9 | الحجوزات التاريخية تُفسَّر دائمًا | Price Snapshot محفوظ مع كل حجز |
| I10 | كل عملية حرجة مُدقَّقة | `audit()` مع كل معاملة حرجة |
| I11 | كود الضيف يموت عند الخروج | check-out يُلغي الكود والجلسات فورًا |
| I12 | الغرفة المشغولة لا تُغيَّر يدويًا | رفض status=OCCUPIED من الإدارة |

### 2.3 قواعد المال

- كل المبالغ **سنت صحيح (Int)** — لا float للمال أبدًا.
- الضريبة = `round(subtotal × taxPercent / 100)`.
- رصيد الإقامة = `reservation.grandTotal + Σ charges − reservation.paidCents`.
- الرجوع للحجز التاريخي يكون عبر snapshot لا عبر الأسعار الحالية.

---

## PART III — آلات الحالة (State Machines)

### 3.1 Reservation
```
PENDING ──(دفع ناجح/تأكيد)──→ CONFIRMED ──(Check-In)──→ CHECKED_IN ──(Check-Out)──→ COMPLETED
   │                            │
   │                            └──(إلغاء وفق السياسة)──→ CANCELLED
   └──(انتهاء hold/فشل)──→ EXPIRED/FAILED
                                    CONFIRMED ──(لم يحضر)──→ NO_SHOW
```
قواعد: الحجز يُلغى فقط من CONFIRMED/PENDING. الإلغاء المجاني قبل 24 ساعة من الوصول.

### 3.2 Stay
```
(لا شيء) ──(Check-In: معاملة ذرية)──→ ACTIVE ──(طلب ضيف الخروج)──→ CHECKOUT_REQUESTED ──(تأكيد الاستقبال)──→ CLOSED
                                        ACTIVE ───────────────────(خروج مباشر من الاستقبال)──→ CLOSED
```
عند CLOSED (ضمن معاملة واحدة): reservation→COMPLETED، room→DIRTY، كود الضيف→REVOKED، الجلسات→revoked.

### 3.3 Room
```
AVAILABLE ⇄ RESERVED
AVAILABLE → OCCUPIED (Check-In فقط) → DIRTY (Check-Out فقط) → CLEANING → AVAILABLE
AVAILABLE ⇄ OUT_OF_ORDER (إدارة/صيانة، مع سبب)
```
ممنوع: تعيين OCCUPIED يدويًا. شغل الغرفة يحدث عبر Check-In حصرًا.

### 3.4 ServiceRequest
```
NEW → ACKNOWLEDGED → ASSIGNED → IN_PROGRESS → COMPLETED
 │         │             │           │
 └──(إلغاء الضيف قبل التنفيذ)──→ CANCELLED      └──(رفض)──→ REJECTED
                                   IN_PROGRESS → WAITING → IN_PROGRESS
```
الضيف يلغي فقط من NEW/ACKNOWLEDGED. كل انتقال يُسجَّل RequestUpdate مع الفاعل والوقت.

### 3.5 Payment / PaymentStatus
```
Payment: COMPLETED (الحالة العملية) | FAILED | REFUNDED
PaymentStatus (على الحجز): UNPAID → PARTIALLY_PAID → PAID | REFUNDED
```
تسديد الدفعات يحدّث paidCents ثم يُعاد حساب PaymentStatus.

### 3.6 ExtensionRequest / RoomChangeRequest
```
PENDING → APPROVED (مع فحص توفر داخل معاملة + Charge للفرق) | REJECTED
```

### 3.7 AccessCode / Session
```
AccessCode: GENERATED(ACTIVE) → USED(فعّال مع lastUsedAt) → EXPIRED | REVOKED
Session: CREATED → (expiresAt | revoked) → ميتة
```
إبطال الكود يبطل كل جلساته. الخروج يبطل كود الضيف. الجلسة تنتهي مع الأقرب: صلاحية الكود / 12 ساعة.

---

## PART IV — قاعدة البيانات (كما نُفِّذت)

Prisma + SQLite (جاهزة للترقية إلى PostgreSQL دون تغيير منطقي). المال بالسنت. Enums كنص مع قيم موثقة.

| الجدول | الغرض | حقول مميزة |
|---|---|---|
| Hotel | إعدادات الفندق الواحد | taxPercent, weekendSurchargePercent, checkIn/OutTime, السياسات الخمس, bookingHorizonDays |
| RoomType | نوع الغرفة القابل للبيع | basePriceCents, capacityAdults/Children, amenities/images (JSON), active |
| Room | الغرفة الفعلية | number (فريد), floor, status (ست حالات) |
| Rate | معدل موسمي | roomTypeId, startDate, endDate, priceCents |
| Guest | الضيف | phone (فريد), idNumber |
| Reservation | الحجز | bookingReference (فريد), status, source, priceSnapshot (JSON), paidCents |
| Stay | الإقامة | reference (ST-…), reservationId (فريد 1:1), roomId, status |
| Charge | بند فاتورة إضافي | category (SERVICE/EXTRA/PENALTY/ROOM_EXTENSION) |
| Payment | دفعة | method, amountCents, recordedBy, مرتبطة بالحجز+الإقامة |
| Staff | الموظف | role (RECEPTION/ADMIN/MANAGER), active |
| AccessCode | كود الدخول | codeHash (sha256 — الخام لا يُخزَّن), codeMasked, type, expiresAt, status |
| Session | جلسة | token (فريد), accessCodeId, expiresAt, revoked |
| ServiceCategory/Service | كتالوج الخدمات | key, priceCents, active |
| ServiceRequest / RequestUpdate | الطلبات وخطها الزمني | reference (REQ-…), status, priority |
| Message | محادثة الضيف/الاستقبال | sender, senderName, readAt |
| Notification | إشعار (GUEST/RECEPTION/ADMIN) | audience, type, read |
| ExtensionRequest / RoomChangeRequest | طلبات التمديد والنقل | PENDING/APPROVED/REJECTED + price |
| Feedback | تقييم الإقامة | rating 1-5, tags |
| AuditLog | سجل التدقيق | action, actor, actorRole, details JSON |

**فهارس حرجة:** `(checkIn, checkOut)` و `(status)` على الحجوزات (حسابات التوفر)، `codeHash` فريد، `bookingReference` فريد.

---

## PART V — نموذج الهوية والأكواد

### 5.1 الأصناف الأربعة

| الهوية | الصيغة | يولّده | الصلاحية |
|---|---|---|---|
| Booking Reference | HTL-2026-000421 | النظام (الحجز) | للتتبع — **ليست بيانات دخول** |
| Guest Code | H834729X7 | الاستقبال عند Check-In | حتى نهاية يوم الخروج — يموت عند الخروج |
| Reception Code | R492671M3 | الإدارة | قابلة للتهيئة (أيام، افتراضي 7) |
| Admin Code | A371849L9 | الإدارة (Master) | قابلة للتهيئة (افتراضي 7 أيام) |

### 5.2 قواعد إلزامية (مُنفَّذة)

- **MUST**: البادئة + 6 أرقام عشوائية (crypto) + حرفا تحقق حتميان (مقاومة أخطاء الكتابة).
- **MUST**: `sha256(code)` — الكود الخام لا يُخزَّن أبدًا؛ يظهر مرة واحدة عند التوليد.
- **MUST**: rate limit 5 محاولات/دقيقة لكل IP + قفل 15 دقيقة بعد 10 محاولات فاشلة.
- **MUST**: فشل الدخول برسالة موحدة لا تكشف وجود الكود (مقاومة التعداد).
- **MUST**: الجلسة token UUID تنتهي مع الأقرب (صلاحية الكود / 12 ساعة) وتبطل مع إبطال الكود.

---

## PART VI — الصلاحيات (RBAC) — مفروضة خادميًا

| المسار | GUEST | RECEPTION | ADMIN |
|---|---|---|---|
| /api/public/** | متاح للجميع (مع rate limits) | — | — |
| /api/guest/** | ✓ (إقامته فقط) | ✗ | ✗ |
| /api/reception/** | ✗ | ✓ | ✓ |
| /api/admin/** | ✗ | ✗ | ✓ |

- إخفاء الواجهة ليس أمنًا — **كل endpoint يتحقق عبر `requireRole`** قبل أي استعلام.
- الضيف: بيانات إقامته حصرًا (كل استعلام يُفلتر بـ stayId من الجلسة).
- Reception: البيانات التشغيلية كاملة + العمليات (check-in/out, payments, requests).
- Admin: كل شيء + الإعدادات والأكواد والطاقم والتقارير والتدقيق.

---

## PART VII — عقود الـ API (كما نُفِّذت)

الصيغة الموحدة: `{ ok: true, ...data }` أو `{ ok: false, error }` + أكواد HTTP صحيحة. كل المسارات `force-dynamic`. المال بالسنت.

### 7.1 المصادقة
| المسار | الوصف |
|---|---|
| POST /api/auth/validate | {code} → {token, role, name, expiresAt} — rate limited + hashed |
| POST /api/auth/logout | إبطال جلسات الكود الحالي |

### 7.2 العام (الموقع)
| المسار | الوصف |
|---|---|
| GET /api/public/hotel | بيانات الفندق والسياسات |
| GET /api/public/room-types | الكتالوج النشط |
| POST /api/public/availability | {checkIn, checkOut, adults, children, roomsCount} → عروض مقتبسة |
| POST /api/public/bookings | إنشاء حجز — **معاملة ذرية + إعادة فحص + Idempotency** |
| POST /api/public/lookup | {reference, phone} → الحجز (تحقق آخر 9 أرقام) |
| POST /api/public/cancel | إلغاء وفق السياسة (مجاني −24س / رسوم ليلة) |

### 7.3 الضيف (GUEST فقط)
dashboard, stay, services, requests (+cancel), messages, bill, extension (فحص توفر خادمي + سعر), room-options, room-change, checkout-request, notifications (+read), feedback.

### 7.4 الاستقبال (RECEPTION/ADMIN)
dashboard (KPIs اليوم)، arrivals/departures (بتاريخ)، inhouse، stays/[id]، **check-in** (معاملة: تأكيد+غرفة+Stay+كود)، **check-out** (رصيد أو تأكيد؛ إغلاق+DIRTY+إبطال كود)، requests (+status مع خط زمني)، rooms (+status انتقالات التنظيف)، payments، charges، billing/[stayId]، extension-requests (+decide)، room-change-requests (+decide)، search، messages، notifications.

### 7.5 الإدارة (ADMIN فقط)
dashboard (KPIs + roomsByStatus + revenueByDay + alerts)، hotel (GET/PATCH)، room-types (CRUD بحذف ناعم)، rooms (CRUD بمنع OCCUPIED يدويًا)، rates (CRUD مع تحذير تداخل)، services + service-categories (CRUD)، staff (+إبطال كود عند التعطيل)، **codes** (توليد يعرض الخام مرة واحدة + قوائم مقنّعة + revoke)، reservations (paginated + تفاصيل snapshot)، guests، audit (فلاتر + صفحات)، reports (إشغال 14 يومًا/إيراد 6 أشهر/إحصاءات الطلبات/الجنسيات).

---

## PART VIII — الأحداث والإشعارات (Realtime)

```
Backend (بعد المعاملة) ──POST /emit──→ Realtime Service (3002/3004)
                                            │ socket.io عبر البوابة ?XTransformPort=3002
                        ┌───────────────────┼───────────────────┐
                        ▼                   ▼                   ▼
                   stay:{id}            reception              admin
```

| الحدث | المستلم | المصدر |
|---|---|---|
| request:new | reception | إنشاء ضيف لطلب |
| request:updated | stay | تحديث الاستقباب لحالة |
| chat:message | stay / reception | رسالة من أي طرف |
| notification:new | الجميع | كل إشعار |
| reservation:new | reception | حجز جديد من الموقع |
| stay:updated | stay / reception | دفع/تمديد/نقل/خروج |
| room:status | reception | تغيير حالة غرفة |

**قاعدة**: فشل البث لا يُفشل العملية (best-effort) + الإشعارات مسجلة في DB كطبقة مصدر ثانٍ. التطبيقات تستخدم polling احتياطيًا.

---

## PART IX — الشاشات (Route Map المنفذة)

**SPA واحدة على `/`** بأوضاع: `website | login | guest | reception | admin`:

### الموقع (website)
هيدر ثابت + Hero/ودجت البحث + شريط الثقة + الغرف (بطاقات+تفاصيل) + المرافق + المعرض (Lightbox) + الموقع والتواصل والسياسات + Footer لاصق. **نافذة الحجز 5 خطوات**: النتائج ← بيانات الضيف ← المراجعة والسعر والدفع ← المعالجة ← التأكيد (مرجع + طباعة + واتساب). **إدارة الحجز**: بحث + عرض + إلغاء وفق السياسة.

### الضيف (guest)
هيدر (إشعارات/خروج) + تنقل سفلي (الرئيسية/إقامتي/الخدمات/الفاتورة): ترحيب + إجراءات سريعة ×6 + ملخص + إشعارات | الغرفة والخط الزمني والسياسات | كتالوج + طلباتي (حالات ملونة + نبض العاجل + خط زمني) | الفاتورة (شحنات/مدفوعات/رصيد + طلب خروج) + محادثة عائمة + حواريات (تمديد/تغيير غرفة/ملاحظات).

### الاستقبال (reception)
لوحة (4 KPI + وصول/مغادرة/طلبات + إجراءات) | الوصولون (معالج 4 خطوات: تحقق ← غرفة من نفس النوع ← تأكيد ← **الكود الخام مرة واحدة + واتساب**) | المغادرون (معالج: رصيد ← دفعة سريعة/تأكيد مع رصيد ← إغلاق) | المقيمون (بطاقات + تفاصيل بـ5 تبويبات: ضيف/فاتورة/طلبات/رسائل/إجراءات) | الطلبات (فلاتر + إدارة الحالة) | لوحة الغرف (طوابق ملونة + انتقالات تنظيف) | بحث عام.

### الإدارة (admin)
لوحة (KPIs + PieChart الغرف + AreaChart الإيراد + تنبيهات) | إعدادات الفندق | أنواع الغرف (CRUD + وسوم مزايا + منتقي صور) | الغرف (CRUD + فلاتر + منع OCCUPIED) | الأسعار الموسمية | الخدمات والأقسام | الطاقم + **الأكواد** (توليد بالخام مرة واحدة + قوائم مقنعة + إبطال) | الحجوزات (فلاتر + snapshot) | الضيوف | التقارير (recharts) | سجل التدقيق.

---

## PART X — هيكل المشروع (كما نُفِّذ + خارطة الإنتاج)

```
my-project/                          (Monorepo عملي)
├── src/app/page.tsx                 SPA shell — تبديل الأوضاع
├── src/app/api/
│   ├── auth/                        validate + logout
│   ├── public/                      hotel, room-types, availability, bookings, lookup, cancel
│   ├── guest/                       15 مسارًا (إقامة الضيف)
│   ├── reception/                   19 مسارًا (التشغيل)
│   └── admin/                       17 مسارًا (الإدارة)
├── src/lib/                         المنطق المشترك (codes/refs/pricing/availability/auth/audit/rate-limit/events/api/format/store/api-client)
├── src/components/
│   ├── website/ guest/ reception/ admin/ shared/
├── src/hooks/                       use-socket (realtime عبر البوابة)
├── prisma/schema.prisma + seed.ts
└── mini-services/realtime/          socket.io (3002) + emit HTTP داخلي (3004)
```

**الترقية الإنتاجية (مستقبلية):** NestJS backend مستقل بنفس عقود PART VII + PostgreSQL + `apps/web` (Next.js) + `apps/mobile` (Flutter Clean Architecture: core/auth/guest/reception/admin/shared مع Router لكل جلسة) + `packages/api-contracts` (OpenAPI مصدر وحيد) — كلها فوق نفس الدومين في هذه الوثيقة.

---

## PART XI — الأمان والاختبارات والأداء

**الأمان (منفذ):** HTTPS/بوابة، هاش أكواد، جلسات منتهية مع الكود، rate limits (دخول 5/د + قفل، توفر 20/د، حجز 10/س، بحث 5/د)، تحقق مدخلات في كل مسار، عزل بيانات الضيف، AuditLog شامل، لا أسرار في العميل.

**الاختبارات (الرحلات المُتحققة فعليًا):**
1. زائر ← حجز (فندق/بطاقة) ← HTL-… ← إدارة/إلغاء ✓
2. استقبال: وصول ← معالج ← غرفة 204 ← كود H… ✓
3. ضيف بالكود الجديد ← طلب عاجل REQ-… ✓
4. استقبال: استلام ← تنفيذ ← إكمال ✓
5. دفعة $184 ← خروج ← CLOSED + DIRTY + كود REVOKED ✓
6. الكود الميت يُرفض: «تم إلغاء هذا الكود» ✓
7. سلبيات: غرفة غير متاحة/نوع خاطئ/خروج برصيد بلا تأكيد/حالة غير صالحة — كلها برسائل عربية ✓

**الأداء (مستهدف):** API < 1s (المقاسة حاليًا 15-50ms)، تحميل أولي سريع، Skeletons لكل جلب، صور محسّنة، polling 12s احتياطي فقط.

---

## PART XII — مراحل التنفيذ وحالتها

| المرحلة | النطاق | الحالة |
|---|---|---|
| P0 | الدومين والمعمارية والعقود | ✅ منجزة |
| P1 | الأساس: DB + مكتبات + هوية + Realtime | ✅ منجزة |
| P2 | الموقع العام | ✅ منجزة |
| P3 | محرك الحجز (توفر/تسعير/حجز/إدارة/إلغاء) | ✅ منجزة |
| P4 | الدفع (تجريدي: فندق/بطاقة-عربون) | ✅ منجزة (مزود حقيقي: مستقبل) |
| P5 | التأكيدات (طباعة PDF بالطباعة المتصفح + واتساب) | ✅ منجزة |
| P6 | أساس التطبيق (SPA + دخول الكود + جلسات) | ✅ منجزة |
| P7 | وضع الضيف | ✅ منجزة |
| P8 | وضع الاستقبال | ✅ منجزة |
| P9 | وضع الإدارة | ✅ منجزة |
| P10 | التواصل الفوري (socket.io + إشعارات) | ✅ منجزة |
| P11 | الفواتير (شحنات/دفعات/أرصدة/خروج) | ✅ منجزة |
| P12 | التحصين (الأمان/الأداء/المراقبة) | ✅ أساس منجز (مراقبة إنتاجية: مستقبل) |
| P13 | Flutter الحقيقي (Android/iOS) | 🔜 خارطة الطريق — عميل للـ API نفسه |
| P14 | الإنتاج (NestJS مستقل + PostgreSQL + مزود دفع حقيقي + WhatsApp Cloud API) | 🔜 خارطة الطريق |

### MUST / MUST NOT للمراحل القادمة (P13-P14)
- **MUST**: التطبيق يستهلك نفس API هذه الوثيقة دون منطق حرج محلي.
- **MUST**: كل شاشة Flutter تطابق Route Map في PART IX.
- **MUST**: مزود الدفع الحقيقي يُتحقق منه عبر Webhook idempotent.
- **MUST NOT**: نسخة ثانية من محرك التسعير أو التوفر في أي عميل.
- **MUST NOT**: اعتبار WhatsApp مصدر بيانات — هو قناة فقط.

---

## PART XIII — Definition of Done

✅ **محقق في هذه الإصدارة** — مستخدم حقيقي يستطيع اليوم:
فتح الموقع ← فهم الفندق ← بحث التوفر ← رؤية الأسعار الشفافة ← اختيار غرفة ← إدخال بياناته ← مراجعة السعر النهائي ← اختيار الدفع ← الحصول على مرجع HTL-… ← طباعة التأكيد ← إدارة/إلغاء حجزه ||| الاستقبال: يرى الوصولين ← يسجل الوصول بغرفة فعلية ← **يولّد كود ضيف يظهر مرة واحدة** ← يدير الطلبات ← يسجل الدفعات ← يسجل الخروج (الغرفة DIRTY والكود يموت) ||| الضيف: يدخل بكوده ← يرى إقامته ← يطلب خدمة عاجلة ← يتحادث فوريًا ← يرى فاتورته ← يطلب تمديدًا/تغيير غرفة ← يطلب الخروج ||| الإدارة: تدير كل شيء + تولّد أكواد الطاقم + التقارير + التدقيق.

**البوابة النهائية:** المنصة لا تكتمل بجمال الشاشات بل بأن الرحلة الكاملة أعلاه تعمل بلا انقطاع — وقد تم التحقق منها فعليًا.

---

## الملحق أ — خارج النطاق (مؤجل بوعي)
OTA، Loyalty، POS مطاعم، سبا، CRM متقدم، Multi-property، AI Concierge، Housekeeping App مستقل، Offline bookings.

## الملحق ب — أكواد العرض التجريبية
ضيف: `H834729X7` (خالد، غرفة 201) — ضيفة: `H119922K4` (نورا، خروج اليوم) — استقبال: `R492671M3` — إدارة: `A371849L9`

## الملحق ج — سجل التغييرات
| الإصدار | التغيير |
|---|---|
| 1.0 | التوحيد من PLAN_WEBSITE + PLAN_MOBILE + الرسالة الموحدة، ثم **تنفيذ المنصة كاملة** وتوثيق حالتها الفعلية |
