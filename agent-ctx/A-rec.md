# تقرير بوابة المعايرة — المرحلة الأولى (التعرف والفهم)
**Task ID: A-rec** (موجة الفحص الساكن — قراءة موثقة فقط، لا فحص حي)

| البند | القيمة |
|---|---|
| المهمة | أجوبة أسئلة المعايرة الاثني عشر من ملفات المستودع نفسه، بدليل موضعي `ملف:سطر` لكل ادعاء |
| طبيعة العمل | قراءة ساكنة فقط: README · MASTER_PLAN · worklog · docs/CONTRACTS.md · mobile/README · prisma/schema.prisma · src/lib/*.ts · مسارات API (عدّ ملفات/نقاط) |
| المرجع الحاكم للمهمة | AUDIT_BRIEF.md §4 (الأسطر 117-131) + §12.2 (السطر 298) |
| قاعدة الأدلة | كل إجابة مرفقة بمواضع حرفية؛ أي تعارض وثائق↔كود موثق في القسم الأخير (الواقع يغلب) |

---

## السؤال 1 — لماذا Reservation ≠ Stay؟ وما نقطة التحويل بينهما؟

**الإجابة:**
- **Reservation = وعد بالحجز** (يُنشأ من الموقع العام على **Room Type** — دون تحديد غرفة)؛ **Stay = الإقامة الفعلية** (كيان مستقل يُنشأ عند Check-In بغرفة فعلية محددة). البيع على نوع الغرفة والغرفة الفعلية تُخصص عند الوصول فقط.
- **نقطة التحويل: `POST /api/reception/check-in`** — داخل معاملة ذرية: الحجز يجب أن يكون `CONFIRMED` ثم يُحوَّل إلى `CHECKED_IN` وتُنشأ `Stay` بحالة `ACTIVE` مع `reference` منفصل (`ST-…`) وترتبط بها كل كيانات الإقامة (أكواد/طلبات/رسائل/بنود/دفعات). العلاقة 1:1 (`reservationId @unique` في Stay). الخروج يغلق الدورة: Stay → `CLOSED` وReservation → `COMPLETED`.

**الأدلة:**
- README.md:19 — «**Reservation** = وعد بالحجز (يُنشأ من الموقع)، **Stay** = الإقامة الفعلية (تُنشأ عند Check-In).»
- README.md:20 — «البيع يكون على **Room Type**؛ الغرفة الفعلية تُخصيص عند الوصول فقط.»
- MASTER_PLAN.md:56 — «فصل Reservation (الوعد) عن Stay (الحقيقة)؛ البيع على Room Type والتخصيص عند الوصول…»
- prisma/schema.prisma:119-157 (نموذج Reservation) مقابل 161-187 (نموذج Stay — السطر 164: `reservationId String @unique`).
- src/app/api/reception/check-in/route.ts:43 — `if (reservation.status !== 'CONFIRMED')` (شرط التحويل) · :53-56 — `status: 'CHECKED_IN'` · :67-77 — `tx.stay.create({... status: 'ACTIVE'})` · :80 — الغرفة `OCCUPIED`.
- src/app/api/reception/check-out/route.ts:49-52 — Stay → `CLOSED` + `actualCheckOutAt` · :55-58 — Reservation → `COMPLETED`.
- MASTER_PLAN.md:414 — «`Stay`: يُنشأ عند Check-In → ACTIVE → (CHECKOUT_REQUESTED) → CLOSED.»

---

## السؤال 2 — الهويات الأربع، وأيها وسيلة الدخول؟ ولماذا الكود الخام مرة واحدة فقط؟

**الإجابة:**
الهويات الأربع:
1. **Booking Reference** `HTL-2026-000NNN` — للتتبع فقط، **لا يُستخدم للدخول أبدًا**.
2. **Guest Code** (بادئة `H…`) — كود ضيف مرتبط بإقامة.
3. **Reception Code** (بادئة `R…`) — كود موظف استقبال.
4. **Admin Code** (بادئة `A…`) — كود إدارة.

**الأكواد H/R/A وحدها وسيلة الدخول** (بوابة `POST /api/auth/validate`). الكود الخام يُعرض مرة واحدة فقط عند التوليد **لأنه لا يُخزَّن أبدًا** — المخزن هو هاش SHA-256 فقط + نسخة مقنعة للعرض (`codeMasked` مثل `R49••••M3`)؛ فبعد لحظة التوليد يستحيل استرجاعه، ويُولَّد غيره بدلًا منه.

**الأدلة:**
- MASTER_PLAN.md:421-422 — «أربع هويات: Booking Reference (تتبع فقط — لا دخول أبدًا) · Guest Code (H…) · Reception Code (R…) · Admin Code (A…) — توليد وتحقق وهَش SHA-256 وإبطال وتدقيق في src/lib/codes.ts + src/app/api/auth/.»
- README.md:21-22 — «Booking Reference (مثل HTL-2026-000421) للتتبع فقط — لا يُستخدم للدخول» + «Access Codes (مثل H834729X7) هي وسيلة الدخول الوحيدة للتطبيق، تُخزن هاش SHA-256 ولا تُعرض خامًا إلا مرة واحدة عند التوليد.»
- src/lib/codes.ts:2-3 — «الكود الخام لا يُخزَّن أبدًا — يُخزَّن SHA-256 فقط».
- prisma/schema.prisma:241 — `codeHash String @unique // sha256 of the raw code — raw code is never stored` + :242 `codeMasked`.
- src/lib/codes.ts:33-35 — `hashCode` = sha256 hex · :37-41 — `maskCode` = `XX••••XX`.
- check-in/route.ts:82-93 — الكود الخام يُولَّد ويُخزَّن هاش+قناع فقط، ويُعاد في الاستجابة مرة واحدة (:148 — `guestCode: result.rawCode`).
- README.md:91 — «الكود الخام يظهر مرة واحدة فقط».

---

## السؤال 3 — أين يُفرض «المال بالسنت»؟ وما قاعدة الضريبة والرصيد الحرفية؟

**الإجابة:**
- **الفرض معماريًا في المخطط ومحرك التسعير:** كل الحقول المالية `Int` سنت صحيح — «no floats for financial values». القنوات: prisma/schema.prisma (كل `*Cents`) وsrc/lib/pricing.ts (محرك حتمي) وsrc/app/api (كل الحسابات) والعرض يقسم على 100.
- **الضريبة (حرفيًا):** `taxCents = Math.round((subtotalCents × taxPercent) / 100)` — تقريب السنت.
- **الرصيد (حرفيًا):** `رصيد الإقامة = grandTotalCents + Σ charges − paidCents` (وفي الفاتورة: `balanceCents = (roomTotal + extraTotal) − totalPaid`).
- **العربون (CARD):** `round(grandTotalCents / 2)` = 50% دفعة ONLINE.

**الأدلة:**
- prisma/schema.prisma:5 — «Money: always integer cents (no floats for financial values).»
- src/lib/pricing.ts:2-3 — «كل المبالغ بالسنت (Int) — لا أرقام عائمة للمال أبدًا».
- src/lib/pricing.ts:90 — `const taxCents = Math.round((subtotalCents * input.taxPercent) / 100)`.
- MASTER_PLAN.md:411 (§12.2) — «سنت صحيح دائمًا · الضريبة = round(subtotal × taxPercent / 100) · رصيد الإقامة = grand + Σ charges − Σ paid · التفسير التاريخي عبر snapshot حصرًا.»
- src/app/api/reception/_helpers.ts:52-58 — `computeBalance = reservation.grandTotalCents + chargesTotalCents − reservation.paidCents`.
- src/app/api/reception/_helpers.ts:88-109 — `roomTotalCents = stay.reservation.grandTotalCents` و`balanceCents = totalChargesCents − totalPaidCents` (:109).
- src/app/api/public/bookings/route.ts:234 — `const deposit = Math.round(quote.grandTotalCents / 2)`.
- docs/CONTRACTS.md:49 — «كل المبالغ سنت صحيح (Int) بلا استثناء — مثال 16000 = $160.00».

---

## السؤال 4 — كم نقطة نهاية في الـ API؟ وأين وثيقة عقدها؟ ومجموعة F1 المعلنة STABLE؟

**الإجابة (بما فيها تصويب الواقع):**
- **وثيقة العقد:** `docs/CONTRACTS.md` (v1.1 آخر سجل تغيير — رأس الوثيقة ما زال يقول v1.0، انظر التعارضات).
- **العد الموثق:** MASTER_PLAN §12.5 يقول **67 ملف / 82 نقطة**، وCONTRACTS §10.1 يقول **68 ملف / 83 نقطة** (7+2+16+23+34+1).
- **العد الفعلي بالجرد الساكن لهذه المهمة: 69 ملف مسار / 84 نقطة نهاية** = 7 public + **3 auth** (validate/logout/renew) + 16 guest + 23 reception + 34 admin + 1 جذر — بتوزيع 40 GET + 33 POST + 6 PATCH + 5 DELETE. (الواقع يغلب؛ الفارق كله من قناة auth التي صارت 3 بعد إضافة renew — توثق CONTRACTS نفسها ذلك في §1.2.1 دون تحديث §10.1.)
- **مجموعة F1 المعلنة STABLE (2026-09-02):** (أ) الحزمة الأساسية §8.1 — **16 نقطة نهاية** (auth/validate + logout + 14 مسار guest: dashboard/stay/services/requests GET/POST + cancel/messages GET/POST/bill/extension/room-options/room-change/checkout-request/notifications + read)؛ (ب) عقد مصادقة الجوال §1.2.1 (validate + renew + سياسة 401)؛ (ج) مكملات §8.2 (feedback + public/hotel). البطاقات الأخرى DRAFT حتى F4/F5.

**الأدلة:**
- docs/CONTRACTS.md:1 (عنوان الوثيقة) · :7 (الإصدار ومجموعة F1 STABLE) · :1879 (سجل v1.1).
- MASTER_PLAN.md:424-425 — «67 ملفًا / 82 نقطة نهاية … الجرد الموثّق الكامل: docs/CONTRACTS.md v1.0».
- docs/CONTRACTS.md:1887 — «الفعلي من الملفات: 68 ملف مسار … 83 نقطة نهاية (method+path): 7+2+16+23+34+1».
- **جرد فعلي (هذه المهمة):** `find src/app/api -name route.ts | wc -l` = **69**؛ عدّ المعالجات المصدَّرة = **84** (public 7/7 · auth 3/3 · guest 14/16 · reception 22/23 · admin 22/34 · root 1/1).
- docs/CONTRACTS.md:1863-1871 (§9.2 جدول وسم الحالات — F1 الأساسية STABLE بقرار إغلاق بوابة الثقة 2026-09-02 + عقد المصادقة STABLE + المكملات STABLE).
- docs/CONTRACTS.md:1810-1829 (§8.1 قائمة الـ16 نقطة) · :1831-1836 (§8.2 المكملات).
- docs/CONTRACTS.md:91 — «إضافة renew تجعل قناة auth 3 مسارات بدل «2 مسارات» المذكورة في الفهرس و§3».

---

## السؤال 5 — الثوابت I1–I12 (ملخص سطر لكل ثابت)

المصدر الجامع: MASTER_PLAN.md:395-408 (§12.1). التحقق من الكود لكل ثابت أدناه:

| # | الثابت (ملخص) | مكان الفرض الموثق | دليل من الكود |
|---|---|---|---|
| I1 | لا حجز مؤكد فوق المخزون | عدّ التوفر داخل معاملة عند الإنشاء | bookings/route.ts:150-156 (استدعاء availableRoomCount داخل `$transaction`) + availability.ts:17-37 |
| I2 | لا دفع ناجح كاذب | الخادم يقرر؛ الواجهة لا تدّعي | bookings/route.ts:232-250 (الخادم يُنشئ دفعة ONLINE بنفسه — «الخادم وحده يقرر نتيجة "بوابة الدفع"») |
| I3 | ضيف لا يرى بيانات ضيف آخر | RBAC + فلترة stayId في كل مسار guest | auth.ts:36-43 (stayId من الجلسة لا الطلب) + guest/requests/route.ts:23 |
| I4 | كود منتهٍ/ملغي لا يعمل | فحص status + expiry مع كل طلب | auth.ts:23 + validate/route.ts:70 |
| I5 | مرجع حجز واحد لحجز واحد | unique على bookingReference | schema.prisma:121 (`@unique`) + refs.ts:22-24 (حل التصادم) |
| I6 | لا يُعتمد سعر من العميل | computeQuote خادميًا عند الإنشاء | bookings/route.ts:158-168 (الحساب من جديد داخل الخادم) |
| I7 | لا حجز مزدوج | معاملة ذرية + إعادة فحص داخلها | bookings/route.ts:150-156 + MASTER_PLAN.md:182 (H2.3: «ذرية الإنشاء») |
| I8 | لا دفع مكرر | Idempotency Key (TTL 10 دقائق) | CONTRACTS.md:126 + bookings/route.ts:60-75 (إعادة نفس الحجز مع `replayed: true`) |
| I9 | الحجوزات التاريخية تُفسَّر بلقطة وقت الحجز | Price Snapshot غير قابل لإعادة الكتابة | bookings/route.ts:196-226 + pricing.ts:104-129 |
| I10 | كل عملية حرجة مُدقَّقة | audit() مع كل معاملة حرجة | أمثلة: check-in:96-119 (×3) · check-out:74-86 · guest/requests:113-120 |
| I11 | كود الضيف يموت عند الخروج | check-out يُبطل الكود والجلسات | check-out/route.ts:63-71 (REVOKED + جلسات revoked) |
| I12 | الغرفة المشغولة لا تُغيَّر يدويًا | رفض OCCUPIED من الإدارة | admin/rooms/[id]/route.ts:47-48 + reception/rooms/[id]/status/route.ts:41 |

---

## السؤال 6 — آلات الحالة (الكل والانتقالات)

**المصادر الجامعة:** MASTER_PLAN.md:413-419 (§12.3) + docs/CONTRACTS.md:196-206 (§1.7) + تعليقات prisma/schema.prisma.

**1) Reservation** (schema.prisma:124):
`PENDING → CONFIRMED → CHECKED_IN → COMPLETED`
- الإنشاء من الموقع يُنشئ **مؤكدًا مباشرة** (bookings/route.ts:210 — `status: 'CONFIRMED'`).
- الإلغاء من PENDING/CONFIRMED وفق سياسة 24 ساعة (MASTER_PLAN.md:414؛ public/cancel/route.ts:2 — «مجاني حتى (الوصول − 24 ساعة)، وإلا رسوم ليلة واحدة»).
- CHECKED_IN عند الوصول (check-in:53-56)، COMPLETED عند الخروج (check-out:55-58).
- `NO_SHOW` / `EXPIRED`: قيمتان معرفتان في المخطط ومقبولتان كفلتر إداري فقط — **لا مسار يضبطهما أبدًا** (رصد: admin/reservations/route.ts:24 هو الظهور الوحيد).

**2) Stay** (schema.prisma:170):
`ACTIVE → (CHECKOUT_REQUESTED) → CLOSED`
- يُنشأ ACTIVE عند Check-In (check-in:75)؛ طلب الخروج من الضيف ينقلها CHECKOUT_REQUESTED؛ الخروج يغلقها CLOSED (check-out:49-52) — والخروج مقبول من ACTIVE أو CHECKOUT_REQUESTED (check-out:34-36).

**3) ServiceRequest** (schema.prisma:313):
`NEW → ACKNOWLEDGED → ASSIGNED → IN_PROGRESS → (WAITING) → COMPLETED / CANCELLED / REJECTED`
- تبدأ **NEW** (تصويب H2-a — لا SUBMITTED) (guest/requests/route.ts:99؛ MASTER_PLAN.md:416).
- الاستقبال ينقل بين: ACKNOWLEDGED / ASSIGNED / IN_PROGRESS / WAITING / COMPLETED / CANCELLED / REJECTED (reception/requests/[id]/status/route.ts:15).
- الحالات النهائية الثلاث لا تُعدَّل بعدها (TERMINAL، :16 + :49).
- الضيف يلغي فقط من NEW/ACKNOWLEDGED (guest/requests/[id]/cancel/route.ts:13).

**4) Room** (schema.prisma:79):
`AVAILABLE / RESERVED / OCCUPIED / DIRTY / CLEANING / OUT_OF_ORDER`
- انتقالات يدوية مسموحة: `DIRTY→CLEANING→AVAILABLE` و`DIRTY→AVAILABLE` و`AVAILABLE↔OUT_OF_ORDER` (reception/rooms/[id]/status/route.ts:17-22).
- OCCUPIED تُضبط آليًا عند الوصول (check-in:80) وDIRTY آليًا عند الخروج (check-out:61) — يدويًا ممنوع (I12: rooms status:41 + admin/rooms/[id]:47-48).

**5) AccessCode** (schema.prisma:248-249):
`ACTIVE → (REVOKED | EXPIRED)`
- الإبطال عند الخروج فورًا (I11 — check-out:64-67) أو من الإدارة (codes/revoke) أو تعطيل موظف.
- قيمة `USED` مقبولة كفلتر فقط ولا مسار يضبطها (CONTRACTS.md:1891 + admin/codes/route.ts:27).

**6) (تكميل) ExtensionRequest/RoomChangeRequest:** `PENDING → APPROVED/REJECTED` (schema.prisma:380, :397؛ MASTER_PLAN.md:419).

---

## السؤال 7 — دور H/R/A والبادئة وطول كل كود

**الإجابة:**
- **H (GUEST):** كود الضيف — يُولَّد عند Check-In حصرًا، مرتبط بالإقامة (`stayId`)، صلاحيته حتى نهاية موعد الخروج المتوقع، ويموت فور الخروج (I11). دور صاحبه: وضع الضيف.
- **R (RECEPTION):** كود موظف استقبال — يولده الإدارة (الطاقم والأكواد) بصلاحية 1–30 يومًا لموظف مطابق للدور. دور صاحبه: وضع الاستقبال.
- **A (ADMIN):** كود إدارة — يولده الإدارة كذلك. دور صاحبه: وضع الإدارة.
- **الصيغة (من الكود):** بادئة حرف (H/R/A) + **6 أرقام عشوائية آمنة** + **حرفا تحقق حتميان** = **9 خانات إجمالًا** (مثل `H834729X7`). حرفا التحقق دالة حتمية من الأرقام وبادئة النوع لمنع أخطاء الكتابة.
- ⚠️ MASTER_PLAN.md:422 وAUDIT_BRIEF.md:40 يقولان «بادئة + 7 رموز» — **الواقع في الكود: بادئة + 8 رموز (6 أرقام + حرفا تحقق) = 9 خانات** (codes.ts:20-27). موثق في التعارضات.

**الأدلة:**
- src/lib/codes.ts:9 — `PREFIX: { GUEST: 'H', RECEPTION: 'R', ADMIN: 'A' }`.
- src/lib/codes.ts:19-23 — `generateCode`: 6 أرقام (crypto.randomInt) + checksum → `H834729X7 / R492671M3 / A371849L9`.
- src/lib/codes.ts:12-17 — `checksumChars` الحتمي.
- src/lib/codes.ts:25-27 — `/^[HRA]\d{6}[A-Z0-9]{2}$/`.
- check-in/route.ts:83 — `generateCode('GUEST')` · admin/codes/route.ts:3-5 — توليد أكواد R/A خام تُعاد مرة واحدة.
- mobile/README.md:63 — كود الضيف يُعرض مرة واحدة (R-06) · :81 — صلاحية 1–30 يومًا لكود الطاقم.

---

## السؤال 8 — مسار حدث لحظي كامل: ضيف يرسل طلب خدمة → ظهوره عند الاستقبال

**المسار (بالمنافذ والغرف والأحداث):**

1. **الضيف (SPA `/` على المنفذ 3000)** → `POST /api/guest/requests` بترويسة `Authorization: Bearer <token>` (خادم تطوير Next.js: package.json:6 — `next dev -p 3000`).
2. **الخادم** (guest/requests/route.ts:55-56): `requireGuest` → getAuth يشتق `stayId` من الجلسة (عزل I3) → تحقق (عنوان ≥ 3 أحرف… :67-69) → **معاملة** (:77-149): إنشاء ServiceRequest بحالة `NEW` + مرجع `REQ-…` + RequestUpdate أولي + تدقيق `REQUEST_CREATED` + إشعاران (RECEPTION وGUEST).
3. **البث الداخلي بعد المعاملة** (:160-167): `emitEvent(wsRooms.reception, 'request:new', {id, reference, title, priority, roomNumber, guestName})` → نداء HTTP `POST http://127.0.0.1:3004/emit` (events.ts:15-26 — مهلة 2500ms، best-effort لا يُفشل العملية) + (:168-170) `notification:new` إلى غرفة `stay:{stayId}`.
4. **خدمة Realtime المستقلة** (mini-services/realtime/index.ts): خادم البث الداخلي على **المنفذ 3004** (localhost فقط — :66 `emitServer.listen(3004, '127.0.0.1')`) يستقبل `/emit` وينفذ `io.to(room).emit(event, data)` (:53-54) فوق خادم Socket.IO المربوط على **المنفذ 3002** (:65) — بتحقق `VALID_ROOM = /^(stay:…|reception|admin)$/` (:24).
5. **عميل الاستقبال (المتصفح)**: `useSocket('reception', handlers)` (reception-app.tsx:87) → `io('/?XTransformPort=3002')` (use-socket.ts:23) عبر **بوابة Caddy على :81** التي تحوّل الاستعلام إلى `reverse_proxy localhost:{query.XTransformPort}` (Caddyfile:3-11) → عند الاتصال `socket.emit('join', 'reception')` (use-socket.ts:30-32؛ الخدمة تنفذ join عند اجتياز VALID_ROOM — index.ts:28-29).
6. **الظهور عند الاستقبال**: معالج `REQUEST_NEW` (reception-app.tsx:88-96) → توست «🔔 طلب جديد: …» مع الغرفة والمرجع + `bump()` (يحرك `version` :57-59 فتُعاد جلب القوائم: اللوحة/الطلبات) + `notifVersion++` (تحديث الإشعارات) — **بلا تحديث يدوي**.
- المصادر الموثقة للمسار: MASTER_PLAN.md:64 («مُتحقق: طلب ضيف يظهر في لوحة الاستقبال لحظيًا») · AUDIT_BRIEF.md:35 · CONTRACTS.md:124 (الأحداث السبعة والغرف).

---

## السؤال 9 — المسار الوحيد المرئي في الويب وتبدل الوضع بين الأدوار

**الإجابة:**
- **المسار الوحيد: `/`** (SPA واحدة — `src/app/page.tsx`) — لا مسارات أخرى مرئية؛ كل الأوضاع تُبدَّل داخل نفس الصفحة.
- **الأوضاع الخمسة:** `website | login | guest | reception | admin` (store.ts:10 — `AppMode`) — محفوظة في `zustand/persist` باسم `qalb-hotel-session` (store.ts:34).
- **التبدل:** دخول الكود عبر `POST /api/auth/validate` يعيد `role` → `setMode(res.role.toLowerCase())` (code-login.tsx:46) → page.tsx يعرض المكون المطابق مع تحقق الدور: `mode === 'guest' && session?.role === 'GUEST'` … إلخ (page.tsx:44-48). زر عائم «دخول التطبيق» من الموقع يفتح وضع login (page.tsx:55-62). الخروج يعيد `mode: 'website'` (store.ts:30)، وانتهاء الجلسة يُخرج تلقائيًا بمؤقّت (page.tsx:24-36).

**الأدلة:**
- src/app/page.tsx:44-48 (التحويل) · :55-62 (الزر العائم).
- src/lib/store.ts:10 (الأوضاع الخمسة) · :30 (logout → website).
- src/components/shared/code-login.tsx:41-46.
- AUDIT_BRIEF.md:32 — «SPA بمسار واحد `/` فقط (src/app/page.tsx) يبدّل الأوضاع» · README.md:102.

---

## السؤال 10 — المراحل المقفلة فعليًا والمعلّق وما يحظر AD-06 فتحه

**المقفلة فعليًا (مكتملة وموثقة القبول):**
- **المرحلة H كاملة** (H1–H4) + **بوابة الثقة** — مقفلة 2026-09-02 (MASTER_PLAN.md:135, :158, :222-231).
- **F0, F1, F2** (Flutter تأسيس/ضيف/وقت فوري — :241, :246, :251) · **F4** (الاستقبال — :261) · **F5** (الإدارة — :268) · **F6** (خط البناء والإصدار + minAppVersion — :274، مكتملة نهائيًا).
- **W0** مقفل بقرار المالك 2026-09-02: بلا Twilio/Cloud API — روابط wa.me فقط والأدمن يتحكم برقم الوجهة (:301, :305).

**المعلّق:**
- **F3** (Push/FCM — يحتاج Firebase — :256) · **F7** (Dogfooding — :279) · **F8** (المتاجر — :285).
- **W1–W4** معلقة بلا موعد حتى قرار مزود (:306-309).
- **P1–P7** (الإنتاج) و**O** (ما بعد الإنتاج) — لاحقًا (:317-331, §9).
- عمل الدخول لأي مرحلة تالية **متوقف بقرار المالك على نتيجة التدقيق الخارجي** (worklog.md:626).

**ما يحظر AD-06 فتحه** (MASTER_PLAN.md:112-113): **«لا إعادة فتح للمنطق المُثبَت»** — الدومين كله (Reservation/Stay/الأنواع/الأكواد/لقطة السعر/الفاتورة) مُجرَّب طرفًا لطرف؛ إعادة تصميمه الآن «خطر متنكّر في هيئة تحصين»؛ الأسلوب الوحيد المسموح: **تغطية بالاختبارات لا فتح وتعديل**. ويشدده القسم 10 «القوائم المجمدة» (:363-373): نموذج الدومين + مخطط Prisma مجمّد يُغطى بالاختبار؛ محرك التسعير يُختبر لا يُفتح؛ طوبولوجيا Realtime كما هي؛ NestJS/PostgreSQL/Monorepo مؤجلة بمحفز AD-07؛ فك SPA مسار موازٍ بلا حق توقيف؛ استبدال الأكواد/الجلسات بـ NextAuth مرفوض.

---

## السؤال 11 — فاتورة حجز قديم إذا رُفع سعر النوع لاحقًا (I9)

**الإجابة:**
**لا تتغير إطلاقًا.** الحجز يحمل **Price Snapshot** مجمّدًا وقت الحجز (`priceSnapshot` JSON: الليالي بأسعارها/المجموع/الضريبة/السياسات) + أرقام مالية محفوظة في سجل الحجز نفسه (`subtotalCents/taxCents/grandTotalCents`). الفاتورة تُبنى من **قيم الحجز المخزنة** لا من سعر النوع الحالي، وتفاصيل الإدارة/الاستقبال/الضيف تعرض اللقطة المحلَّلة. رفع `RoomType.basePriceCents` يؤثر فقط على عروض/حجوزات **جديدة** (computeQuote يُحسب لحظة الإنشاء من السعر الحالي). المخطط والاختبارات يثبتان: «snapshot يتجمد ولا يتأثر بتغير أسعار لاحق».

**الأدلة:**
- MASTER_PLAN.md:405 (I9) — «الحجوزات التاريخية تُفسَّر بلقطة وقت الحجز | Price Snapshot غير قابل لإعادة الكتابة».
- src/lib/pricing.ts:104 — «لقطة السعر التي تُحفظ مع الحجز — غير قابلة لإعادة الكتابة».
- src/app/api/public/bookings/route.ts:196-203 (buildSnapshot وقت الحجز) + :226 (`priceSnapshot: snapshot` يُخزَّن).
- prisma/schema.prisma:144 — `priceSnapshot String @default("{}") // JSON: nightly breakdown, rates, policies at booking time`.
- src/app/api/reception/_helpers.ts:88-97 — الفاتورة تقرأ `stay.reservation.grandTotalCents/subtotalCents/taxCents` (قيم مجمدة عند الإنشاء) — لا تقرأ RoomType.
- src/app/api/admin/reservations/[id]/route.ts:82 — تفصيل الإدارة يعرض `priceSnapshot` المحلَّل.
- MASTER_PLAN.md:181 (H2.2) — «ال snapshot يتجمد ولا يتأثر بتغير أسعار لاحق».

---

## السؤال 12 — الخدمات المستقلة عن تطبيق Next.js ومنافذ كل منها

**الإجابة:**
1. **خدمة الوقت الفوري `mini-services/realtime`** (عملية Bun مستقلة بمجلد واعتماديات خاصة — `mini-services/realtime/package.json`):
   - **المنفذ 3002**: خادم Socket.IO للعملاء (الويب والجوال) — يتصلون عبر البوابة بمسار `/?XTransformPort=3002`، path `'/'` (لا يُغيَّر — تعليق صريح في الكود لأن Caddy يعتمده).
   - **المنفذ 3004**: HTTP داخلي على `127.0.0.1` فقط — يستدعيه Backend الويب للبث: `POST /emit` (+ `GET /health`).
2. **بوابة Caddy** (`Caddyfile` — بنية تحتية مستقلة عن التطبيق): تستمع على **:81**، تحوّل الافتراضي إلى `localhost:3000` وأي طلب يحمل `XTransformPort` إلى المنفذ المطلوب.
3. (سياق المنافذ) تطبيق الويب نفسه: **3000** (`next dev -p 3000`). وتطبيق Flutter (`mobile/`) عميل مستقل يُبنى عبر GitHub Actions وليس خدمة هنا.

**الأدلة:**
- mini-services/realtime/index.ts:3-6 — «المنفذ 3002 — socket.io للعملاء (عبر البوابة ?XTransformPort=3002) · المنفذ 3004 — HTTP داخلي (localhost فقط)».
- index.ts:65-66 — `SOCKET_PORT = 3002` / `EMIT_PORT = 3004` + `emitServer.listen(EMIT_PORT, '127.0.0.1')` (localhost only).
- Caddyfile:1-21 — `:81` + `@transform_port_query` → `reverse_proxy localhost:{query.XTransformPort}`، والافتراضي `localhost:3000`.
- src/lib/events.ts:6-7 — `REALTIME_PORT = 3002` / `EMIT_PORT = 3004`.
- package.json:6 — `"dev": "next dev -p 3000"`.
- AUDIT_BRIEF.md:35 · mobile/README.md:46 — نفس الطوبولوجيا.

---

# قسم التعارضات المرصودة (وثائق ↔ كود/واقع — الواقع يغلب)

| # | التعارض | موضع الوثيقة | الواقع (الدليل) | التصنيف المقترح |
|---|---|---|---|---|
| C1 | **عدد ملفات/نقاط الـ API** — ثلاث روايات: 67/82 (الخطة والمطالبة) · 68/83 (CONTRACTS §10.1) | MASTER_PLAN.md:424-425 · AUDIT_BRIEF.md:34 · CONTRACTS.md:1887 | **69 ملفًا / 84 نقطة** (جرد فعلي: 7 public + **3 auth** + 16 guest + 23 reception + 34 admin + 1 root) — الفارق قناة auth (renew) التي وثقت CONTRACTS نفسها تحولها لـ3 مسارات (CONTRACTS.md:91) دون تحديث §10.1 | INFO (توثيق) — لكنه مساس بدقة S6 المستقبلية |
| C2 | **طول كود الدخول** — «بادئة + 7 رموز» (8 خانات) | MASTER_PLAN.md:422 · AUDIT_BRIEF.md:40 | الكود **9 خانات**: بادئة + 6 أرقام + حرفا تحقق — codes.ts:19-23 و:25-27 (regex `[HRA]\d{6}[A-Z0-9]{2}`)؛ العينات نفسها 9 خانات (H834729X7) | INFO (توثيق) |
| C3 | عنوان MASTER_PLAN «v2.4» بينما الإصدار 2.5 | MASTER_PLAN.md:1 مقابل :7 و:455 | مثبت مسبقًا في AUDIT_BRIEF.md:368 (ملحق ب) | COSMETIC (موثق سلفًا) |
| C4 | README «157 اختبارًا» | README.md:72 | **165** — worklog.md:601/:608 وMASTER_PLAN.md:277 | INFO (موثق سلفًا في AUDIT_BRIEF.md:369) |
| C5 | README «20 نموذجًا» | README.md:98 | **22 نموذجًا** — عدّ prisma/schema.prisma (Hotel…AuditLog) وMASTER_PLAN.md:57 | INFO (موثق سلفًا في AUDIT_BRIEF.md:370) |
| C6 | README بنية القنوات: guest «15 مسارًا» · reception «17» · admin «17» | README.md:106-108 | **14 / 22 / 22 ملفًا** (جرد فعلي؛ وأيضًا CONTRACTS.md:22-24 يقول 14/22/22) | INFO |
| C7 | اسم ضيفة العرض: README «نورا سعيد» | README.md:87 | Seed: **«نورا يوسف»** — prisma/seed.ts:258 (وMASTER_PLAN.md:440 وAUDIT_BRIEF.md:49 يقولان يوسف) | COSMETIC |
| C8 | رأس CONTRACTS «v1.0» رغم أن آخر إصدار موثق v1.1 | CONTRACTS.md:7 مقابل :1879 (سجل v1.1) | AUDIT_BRIEF.md:34 يصفها بـ«v1.1» — الرأس لم يُرقَّ | COSMETIC |
| C9 | حالتا `NO_SHOW`/`EXPIRED` للحجز معرفتان في آلة الحالة (§12.3) | MASTER_PLAN.md:414 + schema.prisma:124 | **لا مسار يضبطهما** — الظهور الوحيد فلتر في admin/reservations/route.ts:24 (نمط نظير «USED» الموثق في CONTRACTS.md:1891) | INFO (فجوة وظيفية موثقة كملاحظة، ليست خللًا كسرًا) |

**ملاحظة منهجية:** لم يُنفَّذ أي فحص حي في هذه الموجة (أمر المهمة) — كل ما أعلاه قراءة موثقة. الأعداد الفعلية (C1) نتجت عن جرد ملفات/رموز ساكن (find/grep على شجرة الكود) ولا تمس قاعدة البيانات أو الخوادم.

---

## إقرار النزاهة
- نُفّذ: قراءة كاملة للملفات المصدرية المحددة في التكليف + جرد ساكن لعدد ملفات/نقاط API + تتبع مسارات الأحداث في الكود.
- لم يُنفَّذ (خارج النطاق الساكن): تشغيل الخوادم، اختبارات، لمس `db/custom.db`، أي تعديل كود/commit/push.
- المخرجات: هذا التقرير (`agent-ctx/A-rec.md`) + قسم A-rec ملحق بذيل `worklog.md` (append واحد).
