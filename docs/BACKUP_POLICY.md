# سياسة النسخ الاحتياطي والاستعادة (P2)

> **فندق قلب القاهرة — عدن** · الحزمة: Task 24-c · المرحلة P2
> القاعدة: قاعدة SQLite واحدة في `/opt/cairo-hart/db/custom.db` — كل ما يخص الحجوزات والإقامات والفوترة والمدفوعات والأكواد والسجلات داخلها.
> **معيار القبول (MASTER_PLAN §8):** استعادة نسخة أمس على خادم نظيف خلال **أقل من ساعة**، مُجرَّبة يدويًا مرة على الأقل وموثقة.

---

## 1) الخلاصة التنفيذية

| البند | القيمة |
|---|---|
| التوقيت | **نسخة ليلية 02:00** عبر cron (مستخدم deploy) |
| المنفّذ | `/opt/cairo-hart/scripts/backup.sh` |
| التقنية | نسخ SQLite **الآمن**: `PRAGMA wal_checkpoint(TRUNCATE)` ثم `sqlite3 … ".backup …"` (لقطة متناسقة حتى والقاعدة قيد الاستخدام) |
| التخزين المحلي | `/var/backups/cairo-hart` — 3 عائلات: يومي/أسبوعي/شهري |
| خارج الموقع | rclone (اختياري — متغير `RCLONE_REMOTE` في `/etc/cairo-hart/env`) |
| الاحتفاظ | **يومي 7 · أسبوعي 4 · شهري 6** |
| الاستعادة | `/opt/cairo-hart/scripts/restore.sh` (بطاقة RUNBOOK IC-2) |
| التدريب | **تدريب استعادة شهري إلزامي** — ملحق RESTORE_DRILL أدناه (§6) |

> **تحديث التنفيذ (Task 24-d):** السكربتان **موجودان الآن في المستودع** — `scripts/backup.sh` و`scripts/restore.sh` فوق أداة موحدة `scripts/sqlite-tool.ts` تعمل بـ `bun:sqlite` المدمج (بلا اعتماد على ثنائي sqlite3): اللقطة عبر `VACUUM INTO` المتناسقة + `PRAGMA quick_check` فوري داخل الأداة نفسها — نفس الضمانات الواردة في §2 أدناه. عند الإعداد على الخادم يكفي `git pull` (لا إنشاء يدوي) — والمحتوى المعروض في §4/§5 يظل صالحًا كبديل يدوي بثنائي sqlite3 عند الحاجة.

---

## 2) لماذا `sqlite3 ".backup"` وليس `cp`؟

القاعدة تعمل بنمط WAL (ملفات `-wal` و`-shm` بجوارها). نسخ الملف بـ `cp` أثناء الكتابة قد ينتج نسخة غير متناسقة (فقدان ما في الـ WAL أو قطع صفحة). أمر `.backup` المدمج في sqlite3 ينشئ لقطة متناسقة عبر اتصال قارئ — وهي الطريقة الموثقة هنا مع نقطة تحقق WAL قبلها لتقليص حجم الـ WAL نفسه.

```bash
# الفحص اليومي اليدوي من أي نسخة (سريع وآمن):
sqlite3 /var/backups/cairo-hart/daily/custom_<STAMP>.db "PRAGMA quick_check;"
# يجب أن يطبع: ok
```

---

## 3) الجدولة (cron — مستخدم deploy)

```cron
# نسخة احتياطية ليلية 02:00
0 2 * * * /opt/cairo-hart/scripts/backup.sh >> /opt/cairo-hart/logs/backup.log 2>&1
```

المتابعة اليومية: آخر سطور `backup.log` + وجود ملف جديد بتاريخ اليوم (راجع docs/MONITORING.md §إيقاعات المراجعة).

---

## 4) السكربت — `/opt/cairo-hart/scripts/backup.sh`

> أنشئه على الخادم بالمحتوى التالي حرفيًا:

```bash
#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# BACKUP — نسخة احتياطية آمنة لقاعدة SQLite (WAL-safe)
# الموضع: /opt/cairo-hart/scripts/backup.sh  · chmod 750
# التشغيل: يدويًا أو عبر cron 02:00 (docs/BACKUP_POLICY.md)
# ─────────────────────────────────────────────────────────────
set -euo pipefail

APP_DIR="/opt/cairo-hart"
DB="${APP_DIR}/db/custom.db"
BACKUP_ROOT="/var/backups/cairo-hart"
ENV_FILE="/etc/cairo-hart/env"
STAMP="$(date +%F_%H%M%S)"

# متغيرات اختيارية من ملف البيئة (RCLONE_REMOTE)
if [[ -r "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

[[ -f "${DB}" ]] || { echo "❌ القاعدة غير موجودة: ${DB}"; exit 1; }

mkdir -p "${BACKUP_ROOT}/daily" "${BACKUP_ROOT}/weekly" "${BACKUP_ROOT}/monthly"
DEST="${BACKUP_ROOT}/daily/custom_${STAMP}.db"

# 1) نقطة تحقق WAL: دمج سجل الكتابة داخل القاعدة الرئيسية
sqlite3 "${DB}" "PRAGMA wal_checkpoint(TRUNCATE);"

# 2) اللقطة المتناسقة عبر .backup (آمنة مع القرّاء المتزامنين)
sqlite3 "${DB}" ".backup '${DEST}'"
chmod 640 "${DEST}"

# 3) تحقق سلامة النسخة فورًا — فشل التحقق = فشل النسخة
if ! sqlite3 "${DEST}" "PRAGMA quick_check;" | grep -q '^ok$'; then
  echo "❌ النسخة ${DEST} فشلت في quick_check — لا تُعتدّ بها"
  rm -f "${DEST}"
  exit 1
fi
echo "✅ نسخة ناجحة: ${DEST} ($(stat -c%s "${DEST}") بايت)"

# 4) تصنيف أسبوعي (السبت) وشهري (أول الشهر)
if [[ "$(date +%u)" == "6" ]]; then
  cp -p "${DEST}" "${BACKUP_ROOT}/weekly/"
fi
if [[ "$(date +%-d)" == "1" ]]; then
  cp -p "${DEST}" "${BACKUP_ROOT}/monthly/"
fi

# 5) خارج الموقع (اختياري — rclone مضبوط مسبقًا)
if [[ -n "${RCLONE_REMOTE:-}" ]] && command -v rclone >/dev/null 2>&1; then
  rclone copy "${DEST}" "${RCLONE_REMOTE}/db/" --quiet \
    && echo "✅ رُفعت خارج الموقع: ${RCLONE_REMOTE}/db/" \
    || echo "⚠️ فشل الرفع خارج الموقع — راجع docs/BACKUP_POLICY.md §7"
fi

# 6) الاحتفاظ: يومي 7 · أسبوعي 4 · شهري 6
ls -1t "${BACKUP_ROOT}/daily/"   2>/dev/null | grep '\.db$' | tail -n +8 | xargs -r rm -f --
ls -1t "${BACKUP_ROOT}/weekly/"  2>/dev/null | grep '\.db$' | tail -n +5 | xargs -r rm -f --
ls -1t "${BACKUP_ROOT}/monthly/" 2>/dev/null | grep '\.db$' | tail -n +7 | xargs -r rm -f --
```

> **بدقة الالتزام:** الاحتفاظ = آخر 7 يوميات + آخر 4 أسبوعيات + آخر 6 شهريات = أعمق نقطة استعادة تصل إلى **نحو 6 أشهر**.

---

## 5) السكربت — `/opt/cairo-hart/scripts/restore.sh`

```bash
#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# RESTORE — استعادة القاعدة من نسخة احتياطية (بطاقة RUNBOOK IC-2)
# الموضع: /opt/cairo-hart/scripts/restore.sh  · chmod 750
# الاستخدام:
#   sudo systemctl stop cairo-hart-web.service cairo-hart-realtime.service
#   bash /opt/cairo-hart/scripts/restore.sh /var/backups/cairo-hart/daily/custom_YYYY-MM-DD_020000.db
# ─────────────────────────────────────────────────────────────
set -euo pipefail

APP_DIR="/opt/cairo-hart"
DB="${APP_DIR}/db/custom.db"
SRC="${1:-}"

[[ -z "${SRC}" ]] && { echo "الاستخدام: $0 <ملف-النسخة>"; exit 1; }
[[ -f "${SRC}" ]] || { echo "❌ الملف غير موجود: ${SRC}"; exit 1; }

# 1) سلامة النسخة قبل أي شيء
if ! sqlite3 "${SRC}" "PRAGMA quick_check;" | grep -q '^ok$'; then
  echo "❌ النسخة تالفة (quick_check) — جرب نسخة أقدم"
  exit 1
fi

# 2) لا استعادة والخدمات تعمل (كتابات متزامنة = تلف)
if systemctl is-active --quiet cairo-hart-web.service; then
  echo "⛔ أوقف الخدمتين أولًا:"
  echo "  sudo systemctl stop cairo-hart-web.service cairo-hart-realtime.service"
  exit 1
fi

# 3) نسخة أمان من القاعدة الحالية — لا تُفقد أبدًا حتى لو فشلت الاستعادة
if [[ -f "${DB}" ]]; then
  cp -p "${DB}" "${DB}.pre-restore.$(date +%s)"
fi

# 4) الاستعادة عبر .backup (لقطة متناسقة إلى مسار القاعدة) + إزالة WAL قديم
rm -f "${DB}-wal" "${DB}-shm"
sqlite3 "${SRC}" ".backup '${DB}'"
chown deploy:deploy "${DB}"
chmod 640 "${DB}"

echo "✅ استُعيدت القاعدة من: ${SRC}"
echo "الخطوة التالية:"
echo "  sudo systemctl start cairo-hart-realtime.service"
echo "  sleep 2 && sudo systemctl start cairo-hart-web.service"
echo "ثم التحقق: curl -fsS https://\$DOMAIN/api/public/hotel  (أو /api/health متى توفرت)"
```

**الأمر الطارئ المختصر (من RUNBOOK):**

```bash
sudo systemctl stop cairo-hart-web.service cairo-hart-realtime.service
NEWEST=$(ls -1t /var/backups/cairo-hart/daily/*.db | head -n 1)
bash /opt/cairo-hart/scripts/restore.sh "${NEWEST}"
sudo systemctl start cairo-hart-realtime.service
sleep 2 && sudo systemctl start cairo-hart-web.service
```

---

## 6) تدريب الاستعادة الشهري — إلزامي (RESTORE_DRILL)

> بوابة الإطلاق 8.8: هذا البند **لا يُقبل بالكلام** — التدريب مُجرى فعليًا وموثق بتاريخ.
> **الدليل الكامل والسجل الحي: [`docs/RESTORE_DRILL.md`](./RESTORE_DRILL.md)** (البروتوكول الشهري بملف تجريبي + التدريب الكامل كل 6 أشهر على المسار الحقيقي + جدول السجل + معالجة الفشل).

خلاصة موجزة هنا (التفصيل الحرفي في وثيقة التدريب):

1. شهريًا: استعادة نسخة أمس إلى **ملف تجريبي** (`/tmp/drill-restore.db`) — لا تُلمس القاعدة الحية — وقراءة الأعداد خلال **أقل من ساعة**.
2. كل 6 أشهر: تدريب كامل عبر `restore.sh` على المسار الحقيقي في نافذة صيانة معلنة للمالك.
3. كل تدريب يُسجَّل فورًا في جدول السجل في `RESTORE_DRILL.md` (التاريخ/الدور/الزمن/الأعداد) — أول صف حقيقي هو ما يفتح بند بوابة الإطلاق في LAUNCH_PLAN §1.

---

## 7) النسخ خارج الموقع (rclone — اختياري لكنه بند قائمة أمن P6)

1. اختر وجهة يملكها المالك (S3 / أي تخزين سحابي يدعمه rclone) واضبطها:
   `rclone config` (أنشئ remote باسم مثل `offsite`)
2. فعّل المتغير في `/etc/cairo-hart/env` (بلا علامة التعليق):
   `RCLONE_REMOTE=offsite:cairo-hart`
3. تحقق يدويًا: `rclone ls offsite:cairo-hart/db/`
4. النسخ خارج الموقع **إضافية** — لا تغني عن المحلية، والاحتفاظ فيها (نسخة اليوم فقط تُرفع) أبسط عمدًا.

إن غاب rclone أو المتغير: تظل النسخ المحلية الثلاث عائلات هي الخط الدفاعي الأول (تُذكر في SECURITY_CHECKLIST كبند «على الخادم»).

---

## 8) ماذا يُنسخ وماذا لا يُنسخ

| العنصر | يُنسخ؟ | لماذا |
|---|---|---|
| `db/custom.db` | ✅ كل شيء | قلب المنصة كله |
| `.next/standalone` وملفات البناء | ❌ | تُعاد بـ `bun run build` من الكود |
| `node_modules` | ❌ | تُعاد بـ `bun install --frozen-lockfile` |
| `/etc/cairo-hart/env` | ⚠️ يدويًا ومشفّرًا عند المالك فقط | سر — لا يدخل النسخ الآلية ولا المستودع (نسخة ورقية مقفلة عند المالك تكفي لاستعادة خادم جديد) |
| الكود (git) | ❌ | المستودع هو المصدر (`git clone`) |

استعادة خادم نظيف بالكامل = الخطوات 1→12 في `deploy/README.md` ثم استبدال القاعدة بآخر نسخة عبر `restore.sh` — وهذا ما يتدرب عليه §6.

---

## 9) عند تعطل النسخ نفسها

| العرَض | المعالجة |
|---|---|
| `backup.sh` غائب عن `backup.log` ليلة كاملة | شغّله يدويًا وراقب الخطأ · راجع cron (`crontab -l` كمستخدم deploy) · قرص ممتلئ؟ (بطاقة IC-5) |
| `quick_check` يفشل على نسخ حديثة متتالية | علامة تلف مبكر في القاعدة الحية — بطاقة IC-2 فورًا + تصعيد للمطور |
| فشل rclone متكرر | تحقق من الصلاحيات/الشبكة (`rclone ls`) — النسخ المحلية مستمرة بلا توقف خلال ذلك |
