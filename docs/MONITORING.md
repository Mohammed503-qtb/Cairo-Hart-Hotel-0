# المراقبة والتنبيه (P3)

> **فندق قلب القاهرة — عدن** · الحزمة: Task 24-c · المرحلة P3
> الهدف (MASTER_PLAN §8): الخطأ الحرج يصل إشعارًا خلال دقائق، وسجل الجاهزية واضح بلا لوحة خارجية.

---

## 1) مصادر الحقيقة

| المصدر | ماذا يعطي | الأمر |
|---|---|---|
| **نقطة الصحة** | حالة الويب عبر البوابة | `curl -fsS https://$DOMAIN/api/health` — ⚠️ غير موجودة في الكود عند هذه الحزمة؛ **البديل العامل اليوم**: `curl -fsS https://$DOMAIN/api/public/hotel` (JSON ببيانات الفندق = الويب والقاعدة حيّان معًا) |
| **journalctl — الويب** | سجل تطبيق الويب | `journalctl -u cairo-hart-web.service -n 100 --no-pager` |
| **journalctl — realtime** | سجل خدمة الأحداث | `journalctl -u cairo-hart-realtime.service -n 100 --no-pager` |
| **البث الداخلي** | صحة realtime من الداخل | `curl -fsS http://127.0.0.1:3004/health` → `{"ok":true,"service":"realtime-emit"}` |
| **حالة الخدمات** | active / restarts | `systemctl show -p ActiveState,NRestarts cairo-hart-web.service cairo-hart-realtime.service` |
| **القاعدة** | الحجم والسلامة | `sudo -u deploy sqlite3 /opt/cairo-hart/db/custom.db "PRAGMA quick_check;"` |
| **النسخ** | نجاح الليلة | `tail -n 20 /opt/cairo-hart/logs/backup.log` + `ls -lt /var/backups/cairo-hart/daily/ \| head` |

> **تحديث التنفيذ (Task 24-e):** مسار `GET /api/health` **موجود الآن في الكود** (`src/app/api/health/route.ts` — يتحقق من القاعدة فعليًا ويعيد 503 عند تعطلها + رقم الإصدار). سكربت `scripts/health-check.sh` **موجود في المستودع** ويفحصه أولًا، وينبه عبر `ALERT_WEBHOOK` عند تغيّر الحالة (بلا إزعاج متكرر — يخزّن الحالة في state file).

---

## 2) السكربت — `/opt/cairo-hart/scripts/health-check.sh` (كل 5 دقائق)

> **تحديث التنفيذ (Task 24-e):** السكربت **موجود الآن في المستودع** (`scripts/health-check.sh`) — يفحص `/api/health` + الرئيسية + Realtime + منفذ البث + القاعدة + القرص، وينبّه عند تغيّر الحالة فقط. المحتوى التالي يظل المرجع التوثيقي للسلوك:

```bash
#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# HEALTH CHECK — فحص جاهزية كل 5 دقائق عبر cron (Task 24-c / P3)
# يفحص: الصحة + الصفحة الرئيسية + قناة realtime (3002) + القاعدة + القرص
# ينبه عبر ALERT_WEBHOOK عند تغيّر الحالة (بلا إزعاج متكرر)
# ─────────────────────────────────────────────────────────────
set -uo pipefail

ENV_FILE="/etc/cairo-hart/env"
APP_DIR="/opt/cairo-hart"
STATE_DIR="${APP_DIR}/logs"

# DOMAIN وALERT_WEBHOOK من ملف البيئة — بلا أي سر داخل السكربت
DOMAIN="$(grep -E '^DOMAIN=' "${ENV_FILE}" 2>/dev/null | tail -n1 | cut -d= -f2- | tr -d '"' || true)"
ALERT_WEBHOOK="$(grep -E '^ALERT_WEBHOOK=' "${ENV_FILE}" 2>/dev/null | tail -n1 | cut -d= -f2- | tr -d '"' || true)"
# حتى تتوفر /api/health في الكود: الفحص على /api/public/hotel (موجودة وتعمل)
HEALTH_PATH="/api/public/hotel"

failures=()

check() {  # $1 = اسم البند، بقية المعاملات = الأمر
  local name="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "OK    ${name}"
  else
    echo "FAIL  ${name}"
    failures+=("${name}")
  fi
}

check "web-health(${HEALTH_PATH})" curl -fsS --max-time 10 "https://${DOMAIN}${HEALTH_PATH}"
check "homepage" curl -fsS --max-time 15 "https://${DOMAIN}/"
check "realtime-3002-polling" curl -fsS --max-time 10 "https://${DOMAIN}/?XTransformPort=3002&EIO=4&transport=polling"
check "realtime-emit-3004" curl -fsS --max-time 5 "http://127.0.0.1:3004/health"
check "db-file" test -s "${APP_DIR}/db/custom.db"
# القرص: إن تجاوز 85% فهو تحذير مبكر قبل امتلائه (بطاقة IC-5)
check "disk-under-85%" bash -c '[ $(df --output=pcent / | tail -n1 | tr -dc "0-9") -lt 85 ]'

# ── إشعار عند تغيّر الحالة فقط (منع إزعاج التكرار كل 5 دقائق) ──
mkdir -p "${STATE_DIR}"
STATE_FILE="${STATE_DIR}/health-state"
CURRENT="OK"
if (( ${#failures[@]} > 0 )); then CURRENT="FAIL"; fi
PREVIOUS="UNKNOWN"
[[ -f "${STATE_FILE}" ]] && PREVIOUS="$(cat "${STATE_FILE}" 2>/dev/null || echo UNKNOWN)"
printf '%s\n' "${CURRENT}" > "${STATE_FILE}"

send_alert() {  # $1 = نص الرسالة
  [[ -z "${ALERT_WEBHOOK}" ]] && return 0
  # الحمولة مفتاح text (متوافق مع Slack/قنوات البريد المُوجّه).
  # لقناة Discord غيّر المفتاح إلى content. لقناة Telegram أضف chat_id.
  curl -fsS --max-time 10 -X POST -H 'content-type: application/json' \
    -d "{\"text\": \"$1\"}" "${ALERT_WEBHOOK}" >/dev/null 2>&1 || true
}

if [[ "${CURRENT}" == "FAIL" && "${PREVIOUS}" != "FAIL" ]]; then
  send_alert "🔴 [فندق قلب القاهرة] فشل فحص الجاهزية: ${failures[*]} — $(date '+%F %T')"
elif [[ "${CURRENT}" == "OK" && "${PREVIOUS}" == "FAIL" ]]; then
  send_alert "🟢 [فندق قلب القاهرة] تعافت الخدمات — جميع الفحوص ناجحة $(date '+%F %T')"
fi

echo "state: ${PREVIOUS} → ${CURRENT}"
```

الجدولة (cron — مستخدم deploy):

```cron
# فحص جاهزية كل 5 دقائق
*/5 * * * * /opt/cairo-hart/scripts/health-check.sh >> /opt/cairo-hart/logs/health.log 2>&1
```

---

## 3) قناة التنبيه — قرار الوضع الحالي

- **`ALERT_WEBHOOK`** (في `/etc/cairo-hart/env`): أي قناة رقمية يختارها المالك — Discord webhook، أو Telegram bot، أو بريد مُوجَّه (email-to-webhook bridge). ضبط المفتاح بحسب القناة مذكور داخل السكربت.
- **واتساب للمشغل: معلَّقة بقرار W0** (قرار المالك الموثق: بلا مزود واتساب — القناة الرسمية wa.me للضيوف فقط ولا توجد بوابة تنبيه تقنية). عند فتح قرار W مستقبلي لمزود واتساب يمكن إضافة قناة تنبيه رابعة — حتى ذلك الحين لا تُبنى.
- بدون `ALERT_WEBHOOK` يعمل الفحص كالتسجيل فقط (`health.log`) — التنبيه حينها مراجعة يدوية، وهذا غير مقبول لبوابة الإطلاق (بند SECURITY_CHECKLIST).

---

## 4) إيقاعات المراجعة

| الإيقاع | ماذا يُراجع | الأوامر |
|---|---|---|
| **يومي** (دقيقتان صباحًا) | نجاح النسخة الليلية + آخر حالة صحية | `tail -n 20 /opt/cairo-hart/logs/backup.log` · `tail -n 30 /opt/cairo-hart/logs/health.log` · `ls -lt /var/backups/cairo-hart/daily/ \| head -n 3` |
| **أسبوعي** | أخطاء السجلات + عينة من سجل التدقيق | `sudo journalctl -u cairo-hart-web.service -p err --since "7 days ago" --no-pager` · `sudo journalctl -u cairo-hart-realtime.service -p err --since "7 days ago" --no-pager` · عينة سجل التدقيق من **الإدارة → سجل التدقيق** (فلترة الأسبوع — تُراجع أفعال المصادقة والأكواد والمدفوعات) |
| **شهري** | تدريب استعادة + مراجعة تشغيلية | تدريب RESTORE_DRILL.md (إلزامي) · مراجعة أكواد نشطة/منتهية (روتين RUNBOOK) · `systemctl show -p NRestarts cairo-hart-web.service cairo-hart-realtime.service` — صفر إعادة تشغيل غير مبررة |

---

## 5) الأرقام المتوقعة (خطوط الأساس)

| المقياس | المتوقع | إن انحرف |
|---|---|---|
| زمن استجابة `/api/public/hotel` من الخادم | **أقل من 500ms** (محليًا عادة أقل من 100ms) | راجع journal الويب + حجم القاعدة |
| زمن تحميل الصفحة الرئيسية (curl كامل) | أقل من 2s | تحقق من البوابة ثم الويب (بطاقة IC-1) |
| حجم القاعدة `db/custom.db` | أساس seed بضعة مئات KB · نمو فندق صغير: **أقل من 20MB سنويًا** | تجاوز 50MB = مراجعة (صور خارج القاعدة أصلًا — النمو غير طبيعي يستدعي فحصًا) |
| حجم النسخة الليلية | مطابق تقريبًا لحجم القاعدة | قفزة مفاجئة = حدث بيانات كبير — راجع سجل التدقيق لليوم السابق |
| إعادة تشغيل الخدمات | صفر خارج دورات النشر المعلنة | أي NRestarts صاعدة = بطاقة IC-1 أو IC-4 |
| سطور realtime الصباحية | `Realtime socket service running on port 3002` + `emit endpoint ... 3004` مرة واحدة عند الإقلاع فقط | تكرارها = انهيارات متتالية (IC-4) |

قياس سريع شامل (نسخة واحدة لكل شيء):

```bash
export DOMAIN=hotel.example.com
for i in 1 2 3; do curl -fsS -o /dev/null -w "health: %{http_code} %{time_total}s\n" "https://$DOMAIN/api/public/hotel"; done
sudo -u deploy sqlite3 /opt/cairo-hart/db/custom.db "PRAGMA page_count; PRAGMA quick_check;"
sudo -u deploy du -h /opt/cairo-hart/db/custom.db
```

---

## 6) سجل الجاهزية

`/opt/cairo-hart/logs/health.log` هو السجل الرسمي (سطر لكل فحص + حالة الانتقال). راجع دوريًا حجمه وقلّصه عند الحاجة:

```bash
# تدوير أسبوعي يدوي بسيط (أو ضمن cron الشهري):
sudo -u deploy truncate -s 0 /opt/cairo-hart/logs/health.log
```
