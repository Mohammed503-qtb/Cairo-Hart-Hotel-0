# دليل التشغيل — RUNBOOK (P4)

> **فندق قلب القاهرة — عدن** · الحزمة: Task 24-c · المرحلة P4
> الغرض: أي مشغل جديد يستطيع تنفيذ الروتين ومعالجة الحوادث من هذا الدليل وحده.
> اصطلاحات: `الإدارة` = قسم الإدارة في واجهة الويب بعد دخول كود إدارة · `$DOMAIN` = نطاق الإنتاج (مضبوط في `/etc/cairo-hart/env`).
> المرافق: `docs/BACKUP_POLICY.md` (النسخ/الاستعادة) · `docs/MONITORING.md` (المراقبة) · `deploy/README.md` (الإعداد).

---

## 1) بطاقات الحوادث

كل بطاقة: **العرَض → التشخيص خطوة خطوة بأوامر حرفية → الاستعادة → الوقاية**.
اصطلاح الخطورة: SEV-1 (مال/مصادقة) · SEV-2 (تعطل خدمة) · SEV-3 (خلل تجميلي).

### IC-1 — الموقع لا يستجيب

**العرَض:** المتصفح يعلّق أو يعيد `502 Bad Gateway` أو صفحة خطأ اتصال. (خطورة SEV-2)

**التشخيص — بالترتيب:**

```bash
# 1. هل الويب حي محليًا؟ (نتيجة 200 = المشكلة في البوابة/الشبكة، لا في التطبيق)
curl -fsS -o /dev/null -w '%{http_code}\n' http://127.0.0.1:3000/api/public/hotel

# 2. حالة الخدمة وإعادة التشغيل
systemctl status cairo-hart-web.service --no-pager -l

# 3. آخر ما قاله التطبيق قبل السقوط
journalctl -u cairo-hart-web.service -n 80 --no-pager

# 4. البوابة نفسها (تُذكر في 502 تحديدًا)
systemctl status caddy --no-pager
journalctl -u caddy -n 50 --no-pager

# 5. هل النطاق يشير للخادم؟ (مشكلة DNS خارجية)
dig +short $DOMAIN
```

قراءة النتائج:
- الخطوة 1 = 200 والخارج فاشل → البوابة أو الجدار: راجع 4 و5 (`sudo ufw status`, `sudo systemctl restart caddy`).
- الخطوة 1 = فشل اتصال → التطبيق متوقف: راجع 3. أخطاء `SQLITE` أو `database` → انتقل إلى **IC-2**.

**الاستعادة:**

```bash
sudo systemctl restart cairo-hart-web.service
sleep 5
curl -fsS -o /dev/null -w '%{http_code}\n' https://$DOMAIN/api/public/hotel   # المتوقع 200
```

إن لم ينهض بعد إعادة التشغيل مرتين: التصعيد (§4) — لا تجرب أكثر من مرتين متتاليتين.

**الوقاية:** `Restart=always` في الوحدة + فحص كل 5 دقائق (MONITORING) ينبه خلال دقائق.

---

### IC-2 — قاعدة بيانات معطوبة

**العرَض:** كل طلبات API تعيد 500، والسجل يذكر `database disk image is malformed` أو `SQLITE_CORRUPT` أو فشل Prisma متكرر. (خطورة **SEV-1** — بيانات مال)

**التشخيص:**

```bash
# 1. أكّد العلة في السجل
journalctl -u cairo-hart-web.service -n 100 --no-pager | grep -iE 'sqlite|prisma|database|corrupt' | tail -n 20

# 2. فحص سلامة القاعدة الحية (أوقف الخدمتين أولًا ليكون الفحص ساكنًا)
sudo systemctl stop cairo-hart-web.service cairo-hart-realtime.service
sudo -u deploy sqlite3 /opt/cairo-hart/db/custom.db "PRAGMA quick_check;"

# 3. افحص آخر نسختين احتياطيتين (لا تعتمد نسخة قبل فحصها)
ls -lt /var/backups/cairo-hart/daily/ | head -n 3
sudo -u deploy sqlite3 "$(ls -1t /var/backups/cairo-hart/daily/*.db | sed -n 1p)" "PRAGMA quick_check;"
sudo -u deploy sqlite3 "$(ls -1t /var/backups/cairo-hart/daily/*.db | sed -n 2p)" "PRAGMA quick_check;"
```

**الاستعادة** — من آخر نسخة **سليمة** (السكربت يتحقق ويحفظ نسخة أمان من الحالية تلقائيًا — BACKUP_POLICY §5):

```bash
sudo systemctl stop cairo-hart-web.service cairo-hart-realtime.service
bash /opt/cairo-hart/scripts/restore.sh "$(ls -1t /var/backups/cairo-hart/daily/*.db | head -n 1)"
sudo systemctl start cairo-hart-realtime.service
sleep 2
sudo systemctl start cairo-hart-web.service

# التحقق — الأعداد سليمة والتحفظ يعمل:
curl -fsS -o /dev/null -w '%{http_code}\n' https://$DOMAIN/api/public/hotel
sudo -u deploy sqlite3 /opt/cairo-hart/db/custom.db "SELECT COUNT(*) FROM reservations; SELECT COUNT(*) FROM stays; SELECT COUNT(*) FROM payments;"
```

بعد الاستعادة: قارن الأعداد مع آخر قيم يومية معروفة، وأبلغ المالك بما فُقد من الفترة بين النسخة والحادثة (بحد أقصى 24 ساعة). **تصعيد فوري للمالك والمطور — SEV-1.**

**الوقاية:** النسخة الليلية بتحقق سلامة مدمج (quick_check داخل backup.sh) + تدريب الاستعادة الشهري.

---

### IC-3 — تسريب كود طاقم

**العرَض:** شبهة أو تأكيد أن كود وصول لموظف (استقبال/إدارة) تسرب — نطاق شات، صورة، جهاز مفقود. (خطورة **SEV-1** — مصادقة)

**الاستعادة الفورية — بالترتيب، الدقائق الأولى:**

1. **الإبطال من الإدارة** (لا يحتاج سطر أوامر — من أي جهاز):
   ادخل بكود إدارة → **الطاقم والأكواد** → ابحث الكود (بالاسم/القناع) → **إبطال**.
   الخادم يبطل الكود **وكل جلساته في معاملة واحدة** (الموظف يُخرج من الجلسة فورًا — رسالة التأكيد في الواجهة تذكّر بقتل الجلسات).
2. **تدوير ما بقي فورًا:** إن كان المسرب كود **إدارة** ولم يبق كود إدارة آخر نشط → استخدم كود الإدارة الاحتياطي المحفوظ لدى المالك (ظرف مختوم) للدخول والإبطال والتوليد. *لهذا السبب تحديدًا: يجب أن يظل كودا إدارة نشطان دائمًا لا واحد.*
3. **مراجعة سجل التدقيق لتلك الفترة:** الإدارة → **سجل التدقيق** — راجع من لحظة الشبهة حتى الإبطال: أفعال `CODE_LOGIN` و`CODE_LOGIN_FAILED` (هل دخل المسرب؟)، وكل فعل مالي/أسعاري (`RATE_CHANGED`, `ROOM_CHANGED`, `CHECK_IN`…). أي فعل غريب = وثّقه وصدّره (نسخ نصي) للمالك والمطور.
4. **كود بديل:** ولّد كودًا جديدًا للموظف (إن كان سيبقى) بمدة قصيرة (§2 روتين الإصدار) وسلّمه عبر قناة شخصية موثوقة — لا مجموعات.

**فحص موضع التسريب (خادم):**

```bash
# من دخل بالكود المسرب؟ (جلسات الكود الملغى)
sudo -u deploy sqlite3 /opt/cairo-hart/db/custom.db \
  "SELECT action, actor, datetime(createdAt) FROM audit_logs WHERE action LIKE 'CODE_LOGIN%' ORDER BY createdAt DESC LIMIT 30;"
```

**الوقاية:** الكود الخام يُعرض مرة واحدة فقط عند التوليد · مدد قصيرة (1–30 يومًا حسب العقد) · مراجعة شهرية للأكواد النشطة (§2) · قاعدة «كودا إدارة دائمًا».

---

### IC-4 — خدمة realtime متوقفة (الموقع يعمل لكن التحديثات لا تصل)

**العرَض:** الصفحات تفتح وتعمل، لكن لوحة الاستقبال لا تتحدث لحظيًا، والإشعارات الفورية لا تظهر. (خطورة SEV-2)

**التشخيص — بالترتيب:**

```bash
# 1. حالة الخدمة
systemctl status cairo-hart-realtime.service --no-pager -l

# 2. سجلها — الطبيعي عند الإقلاع سطران فقط:
#    "Realtime socket service running on port 3002"
#    "Realtime emit endpoint running on port 3004 (localhost only)"
journalctl -u cairo-hart-realtime.service -n 50 --no-pager

# 3. البث الداخلي حي؟ (من الخادم فقط)
curl -fsS http://127.0.0.1:3004/health
# المتوقع: {"ok":true,"service":"realtime-emit"}

# 4. قناة العملاء عبر البوابة — نفس مسار العملاء حرفيًا:
curl -fsS "https://$DOMAIN/?XTransformPort=3002&EIO=4&transport=polling" | head -c 60; echo
# المتوقع: 0{"sid":"...  (مصافحة engine.io ناجحة)

# 5. هل الويب يبث أصلًا؟ (أخطاء fetch إلى 3004 في سجل الويب)
journalctl -u cairo-hart-web.service -n 100 --no-pager | grep -iE 'emit|3004' | tail -n 10
```

قراءة النتائج:
- 1 = failed/crashed → أعد التشغيل (الاستعادة أدناه).
- 3 ناجح و4 فاشل → الخدمة حية لكن **البوابة** لا تحوّل — تحقق من Caddyfile (`grep -A3 XTransformPort /etc/caddy/Caddyfile` يجب أن يظهر matcher قيمة `3002`) ثم `sudo systemctl reload caddy`.
- 3 و4 ناجحان والعميل لا يتحدث → أعد تحميل صفحة العميل (العملاء يعيدون الاتصال تلقائيًا حتى 10 محاولات كل 2 ث). إن استمر: الخطوة 5 ثم التصعيد.

**الاستعادة:**

```bash
sudo systemctl restart cairo-hart-realtime.service
sleep 3
curl -fsS http://127.0.0.1:3004/health
# لا حاجة لإعادة تشغيل الويب — البث يحاول لكل حدث جديد، والعملاء يعيدون الاتصال بأنفسهم
```

**الوقاية:** فحصا 3002 و3004 ضمن health-check كل 5 دقائق + الترتيب `Before=cairo-hart-web.service` في systemd.

---

### IC-5 — امتلاء القرص (النسخ القديمة)

**العرَض:** فشل النسخ الليلية، أخطاء كتابة، أو تباطؤ عام. (خطورة SEV-2 إن تعطلت الخدمات)

**التشخيص:**

```bash
df -h /
sudo du -sh /var/backups/cairo-hart /opt/cairo-hart/.next /opt/cairo-hart/logs /var/log/journal 2>/dev/null | sort -h
sudo -u deploy du -sh /opt/cairo-hart/db
```

**الاستعادة — بالترتيب من الأقل خطرًا:**

```bash
# 1. سجلات السكربتات (نصية — آمنة للتقليص)
sudo -u deploy truncate -s 0 /opt/cairo-hart/logs/health.log /opt/cairo-hart/logs/backup.log

# 2. سجل systemd (يقتطع الأقدم)
sudo journalctl --vacuum-size=500M

# 3. نسخ احتياطية أقدم من سياسة الاحتفاظ (السكربت يفعلها عادة — هذه يدوية عند الفشل)
ls -lt /var/backups/cairo-hart/daily/ | tail -n 5
# راجع القائمة ثم احذف ما جاوز الاحتفاظ (يومي 7/أسبوعي 4/شهري 6) بعد تأكيد التاريخ
sudo -u deploy rm -v /var/backups/cairo-hart/daily/custom_<STAMP-قديم>.db

# 4. تقليص WAL إن تضخم (آمن — لا يحذف بياناتًا، يدمجها)
sudo -u deploy sqlite3 /opt/cairo-hart/db/custom.db "PRAGMA wal_checkpoint(TRUNCATE);"

df -h /   # تأكيد التعافي
```

> ⛔ **لا تحذف أبدًا:** `db/custom.db` ولا `db/custom.db-wal` الحيين، ولا `.next` (كسر البناء = تعطل)، ولا نسخة اليوم الأخيرة.

**الوقاية:** بند `disk-under-85%` في health-check ينبه قبل الامتلاء.

---

### IC-6 — تحديث خاطئ → rollback

**العرَض:** بعد نشر جديد الموقع مكسور (أو `deploy.sh` نفسه أعلن الفشل وطباعة أمر الاسترجاع). (خطورة SEV-2؛ SEV-1 إن مسّ المال/المصادقة)

**التشخيص:**

```bash
journalctl -u cairo-hart-web.service -n 80 --no-pager
cat /opt/cairo-hart/rollbacks/last-good     # آخر إصدار جيد (commit hash)
cd /opt/cairo-hart && git log --oneline -3
```

**الاستعادة — إما سكربت الاسترجاع المطبوع في فشل deploy.sh، أو يدويًا:**

```bash
cd /opt/cairo-hart
sudo -n systemctl stop cairo-hart-web.service cairo-hart-realtime.service
git checkout --force "$(cat rollbacks/last-good)"
bun install --frozen-lockfile
( cd mini-services/realtime && bun install --frozen-lockfile )
bunx prisma generate
bun run build
sudo -n systemctl start cairo-hart-realtime.service
sleep 2
sudo -n systemctl start cairo-hart-web.service
curl -fsS -o /dev/null -w '%{http_code}\n' https://$DOMAIN/api/public/hotel   # المتوقع 200
```

> **الهجرات تسير للأمام فقط:** إن طبّق النشر الفاشل هجرة جديدة فافحص أولًا `bunx prisma migrate status` واستشر المطور — الاسترجاع الكودي مع هجرة جديدة قد يترك عدم تطابق. **إن كان الخلل في البيانات لا الكود:** استعد آخر نسخة قاعدة (IC-2) — البيانات أغلى من الكود (الكود في git).

**الوقاية:** بوابة فحص الصحة في deploy.sh (3 محاولات) + سجل last-good + soft launch المرحلي (LAUNCH_PLAN).

---

## 2) روتين الطاقم

### إصدار كود موظف جديد

من **الإدارة → الطاقم والأكواد → توليد**:
1. **الدور الصحيح**: `استقبال` لموظفي الاستقبال، `إدارة` للمديرين فقط — لا تمنح إدارة لمن ليس مديرًا (كل المسارات الإدارية تفتح بها).
2. **المدة**: بين **1 و30 يومًا** (حد الخادم الذهبي — لا يُقبل غيره) — الصواب التشغيلي: أقصر مدة تغطي الحاجة (أسبوعان لموظف موسمي، شهر للمدير الدائم ثم تجديد).
3. **الكود الخام يظهر مرة واحدة فقط**: سلّمه للموظف **قناة شخصية موثوقة** (وجاهة أو رسالة مباشرة)، ثم أطفئ نافذة العرض. لا يُرسل في مجموعات ولا يُحفظ في ملاحظات مشتركة.

### الإبطال عند انتهاء العمل أو دوران الموظفين

- في **نفس يوم** انتهاء العمل (لا غدًا): الإدارة → الطاقم والأكواد → إبطال.
- **الإبطال يقتل الكود وجميع جلساته فورًا** — الموظف يخرج من الجلسة مباشرة. أعلِم الموظف بذلك سلفًا («ستُخرج من النظام آخر دوامك»).
- دوران الموظف = إبطال القديم ثم توليد بديل بمدة جديدة (لا تُمدد كود منتهي).
- **مراجعة شهرية**: الإدارة → الطاقم والأكواد — راجع الأكواد **النشطة**: كل كود بلا موظف فعلي = إبطال. (استعلام سريع من الخادم):

```bash
sudo -u deploy sqlite3 /opt/cairo-hart/db/custom.db \
  "SELECT type, status, COUNT(*) FROM access_codes GROUP BY type, status;"
```

### قائمة الاستقبال اليومية (5 دقائق كل صباح)

من **لوحة الاستقبال** (فحص عيني سريع) + تحقق خادمي اختياري:
1. **الواصلون اليوم**: قائمة الوصول — تأكد إتمام Check-In لكل واصل مكتمل.
2. **المغادرون اليوم**: من ينتهي إقامته — إتمام Check-Out والتحصيل (رصيد ≠ 0 قبل المغادرة يُحسم فورًا).
3. **الأرصدة**: الغرف ذات رصيد غير صفّر — لا ضيف يغادر بفاتورة غير مسددة دون قرار مالك موثق.

```bash
# تحقق سريع من الخادم (اختياري):
sudo -u deploy sqlite3 /opt/cairo-hart/db/custom.db "SELECT COUNT(*) FROM stays WHERE status='ACTIVE';"
sudo -u deploy sqlite3 /opt/cairo-hart/db/custom.db "SELECT COUNT(*) FROM access_codes WHERE status='ACTIVE';"
```

---

## 3) المسارات السرية وإدارتها

| السر | موضعه | القاعدة |
|---|---|---|
| متغيرات الإنتاج | `/etc/cairo-hart/env` | **صلاحية 600، مالك root:deploy** · لا يدخل المستودع أبدًا (`.gitignore` يحجب `.env*` أصلًا) |
| أكواد الوصول | داخل القاعدة **مُلبَّدة SHA-256** | الخام يظهر مرة واحدة عند التوليد فقط · لا يُخزن خام في أي مكان |
| كود الإدارة الاحتياطي | ظرف مختوم لدى المالك | لسيناريو IC-3 فقط · يُستبدل كل دورة كود إدارة |
| مفاتيح SSH | `~/.ssh/authorized_keys` | دخول بالمفاتيح بلا كلمات مرور (SECURITY_CHECKLIST) |

**التدوير الدوري:**
- أكواد الطاقم: عند كل دوران موظف + مراجعة شهرية (§2) + فورًا عند أي شبهة (IC-3).
- ملف env: لا يحوي اليوم مفاتيح API (لا بوابة دفع — PAYMENT_GATEWAY_DECISION مفتوحة). **عند أول مفتاح تجاري (بوابة دفع/مزود واتساب مستقبلي): يدور عند كل شبهة تسريب وبمراجعة نصف سنوية على الأقل، ويُحدَّث بتغيير المزود لا بتحرير يدوي متكرر.**
- التحقق الشهري من عدم تسرب أسرار للمستودع:

```bash
cd /opt/cairo-hart && git grep -lE '(DATABASE_URL=file:/|ALERT_WEBHOOK=|sk_live|api[_-]?key)' -- ':!deploy/env.production.example' ':!*.md' || echo "نظيف — لا أسرار في المستودع"
```

---

## 4) التصعيد

| المستوى | تعريفه | من يُخطر | القناة |
|---|---|---|---|
| **SEV-1** | مال أو مصادقة: فوترة خاطئة، دفعة مفقودة/مكررة، قاعدة معطوبة، تسريب كود | **المالك فورًا** ثم المطور | مكالمة هاتفية مباشرة للمالك · قناة ALERT_WEBHOOK الرقمية للمطور |
| **SEV-2** | تعطل خدمة: الموقع، realtime، النسخ الاحتياطي | **المشغل** يعالج من هذا الدليل؛ إن تجاوز 30 دقيقة أو تكرر في اليوم نفسه → المالك | قناة ALERT_WEBHOOK (تصل المالك والمشغل معًا) |
| **SEV-3** | خلل تجميلي لا يوقف عملًا | يُسجَّل فقط في قائمة الإصلاح | مراجعة الأسبوع (MONITORING §4) |

> الأدوار لا الأسماء: **المشغل** (استقبال/تشغيل يومي) · **المالك** (قرار الأثر المالي والتجاري) · **المطور** (عيوب الكود والهجرات). لا يُغيَّر منطق المال أو المصادقة إلا بقرار موثق (AD-06).

---

## 5) فهرس سريع

| الموقف | البطاقة |
|---|---|
| الموقع لا يستجيب | IC-1 |
| قاعدة معطوبة / أخطاء SQLite | IC-2 |
| تسريب كود طاقم | IC-3 |
| التحديثات الفورية لا تصل | IC-4 |
| قرص ممتلئ / نسخ فاشلة | IC-5 |
| نشر خاطئ | IC-6 |
| فشل النسخ الليلي | BACKUP_POLICY §9 |
| لا تنبيهات تصل | MONITORING §3 |
