#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# HEALTH-CHECK — فحص جاهزية دوري كل 5 دقائق (P3 — Task 24-e)
#
# يفحص: /api/health (الويب+القاعدة) · الصفحة الرئيسية ·
#        Realtime 3002 (polling) · منفذ البث الداخلي 3004 ·
#        وجود القاعدة + مساحة القرص.
#
# التنبيه: عند تغيّر الحالة (سليم→معطوب أو العكس) يرسل نداء
# WEBHOOK واحدًا (ALERT_WEBHOOK من ملف البيئة) — لا إزعاج
# متكرر: الحالة تُخزَّن في state file.
#
# cron:  */5 * * * *  bash /opt/cairo-hart/scripts/health-check.sh
# الرملة:  BASE_URL=… STATE_DIR=… bash scripts/health-check.sh
# ─────────────────────────────────────────────────────────────
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${APP_DIR:-$(dirname "${SCRIPT_DIR}")}"
DB="${APP_DIR}/db/custom.db"
BASE_URL="${BASE_URL:-http://localhost:3000}"
RT_URL="${RT_URL:-http://localhost:3002}"
EMIT_URL="${EMIT_URL:-http://localhost:3004}"
STATE_DIR="${STATE_DIR:-${APP_DIR}/backups}"
STATE_FILE="${STATE_DIR}/health-state"
ENV_FILE="${ENV_FILE:-/etc/cairo-hart/env}"
ALERT_WEBHOOK="${ALERT_WEBHOOK:-}"

if [[ -r "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
  ALERT_WEBHOOK="${ALERT_WEBHOOK:-}"
fi

mkdir -p "${STATE_DIR}"

issues=()
notes=()

# 1) الويب + القاعدة
web_code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "${BASE_URL}/api/health" || echo 000)"
if [[ "${web_code}" == "200" ]]; then
  notes+=("health:200")
else
  issues+=("الويب/الصحة: HTTP ${web_code}")
fi

# 2) الصفحة الرئيسية
home_code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "${BASE_URL}/" || echo 000)"
if [[ "${home_code}" == "200" ]]; then
  notes+=("home:200")
else
  issues+=("الرئيسية: HTTP ${home_code}")
fi

# 3) Realtime — polling socket.io (يجب أن يعيد sid)
rt_body="$(curl -s --max-time 10 "${RT_URL}/socket.io/?EIO=4&transport=polling" || true)"
if echo "${rt_body}" | grep -q '"sid"'; then
  notes+=("realtime:ok")
else
  issues+=("Realtime (3002): لا استجابة polling")
fi

# 4) منفذ البث الداخلي — أي استجابة HTTP تعني أنه حي
emit_code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "${EMIT_URL}/" || echo 000)"
if [[ "${emit_code}" != "000" ]]; then
  notes+=("emit:${emit_code}")
else
  issues+=("منفذ البث الداخلي (3004): لا استجابة")
fi

# 5) القاعدة موجودة
if [[ -f "${DB}" ]]; then
  notes+=("db:present")
else
  issues+=("القاعدة غير موجودة: ${DB}")
fi

# 6) القرص — تحذير تحت 15% متاح
disk_pct="$(df --output=pcent "${APP_DIR}" 2>/dev/null | tail -1 | tr -dc '0-9' || echo 0)"
if [[ -n "${disk_pct}" ]] && (( disk_pct >= 85 )); then
  issues+=("القرص ممتلئ: ${disk_pct}% مستخدم")
fi

# ── تقرير + تنبيه عند تغيّر الحالة فقط ──
now="$(date '+%F %T')"
if (( ${#issues[@]} == 0 )); then
  status="HEALTHY"
  line="${now} ✅ HEALTHY — ${notes[*]}"
else
  status="UNHEALTHY"
  line="${now} 🔴 UNHEALTHY — ${issues[*]}"
fi
echo "${line}"

prev="$(cat "${STATE_FILE}" 2>/dev/null || echo "")"
if [[ "${prev}" != "${status}" ]]; then
  echo "${status}" > "${STATE_FILE}"
  # تغيّرت الحالة — أرسل تنبيهًا إن ضُبط القناة
  if [[ -n "${ALERT_WEBHOOK}" ]]; then
    payload="{\"status\":\"${status}\",\"checkedAt\":\"${now}\",\"service\":\"cairo-hart\",\"details\":\"${issues[*]:-${notes[*]}}\"}"
    if curl -fsS --max-time 10 -X POST -H 'content-type: application/json' \
         -d "${payload}" "${ALERT_WEBHOOK}" >/dev/null 2>&1; then
      echo "📨 أُرسل تنبيه تغيّر الحالة (${status}) عبر WEBHOOK"
    else
      echo "⚠️ فشل إرسال التنبيه عبر WEBHOOK — راجع MONITORING.md"
    fi
  elif [[ "${status}" == "UNHEALTHY" ]]; then
    echo "⚠️ لا ALERT_WEBHOOK مضبوط — راجع docs/MONITORING.md §قناة التنبيه"
  fi
fi

[[ "${status}" == "HEALTHY" ]] && exit 0 || exit 1
