#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# DEPLOY — نشر إنتاجي لمنصة فندق قلب القاهرة (عدن)
# الحزمة: Task 24-c · المرحلة P1
#
# هذا السكربت لا يحتوي أي سر — DOMAIN وDATABASE_URL تُقرأ
# من /etc/cairo-hart/env (راجع deploy/env.production.example).
#
# التشغيل (كمستخدم deploy — راجع قاعدة sudoers في deploy/README.md §5):
#   cd /opt/cairo-hart && bash deploy/deploy.sh
#
# التتابع: سجل الإصدار السابق → git pull → الاعتماديات → الهجرات
#          → البناء → إعادة تشغيل الخدمتين → فحص الصحة ×3
#          → نجاح: تحديث last-good / فشل: أمر استرجاع + خروج برمز 1
# ─────────────────────────────────────────────────────────────
set -euo pipefail

APP_DIR="/opt/cairo-hart"
ENV_FILE="/etc/cairo-hart/env"
ROLLBACK_DIR="${APP_DIR}/rollbacks"
LAST_GOOD="${ROLLBACK_DIR}/last-good"
ATTEMPTS=3
WAIT_SECONDS=6

# مسار فحص الصحة — المواصفة تتطلب /api/health.
# ⚠️ واقع الحزمة 24-c: نقطة /api/health غير موجودة في الكود بعد.
#    حتى إضافتها (مهمة كود تابعة) غيّر السطر التالي إلى:
#    HEALTH_PATH="/api/public/hotel"   (نقطة عامة موجودة وتعمل اليوم)
HEALTH_PATH="/api/health"

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"; }

# ── 0. قراءة DOMAIN من ملف البيئة (بلا أي سر داخل السكربت) ──
if [[ ! -r "${ENV_FILE}" ]]; then
  log "❌ ملف البيئة ${ENV_FILE} غير مقروء — راجع deploy/env.production.example"
  exit 1
fi
DOMAIN="$(grep -E '^DOMAIN=' "${ENV_FILE}" | tail -n 1 | cut -d= -f2- | tr -d '"' || true)"
if [[ -z "${DOMAIN}" ]]; then
  log "❌ DOMAIN غير مضبوط في ${ENV_FILE}"
  exit 1
fi

cd "${APP_DIR}"

# ── 1. تسجيل الإصدار السابق في ملف rollbacks/last-good ──
# (إن فشل النشر لاحقًا يبقى آخر إصدار جيد معروفًا للاسترجاع)
PREV_REV="$(git rev-parse HEAD)"
mkdir -p "${ROLLBACK_DIR}"
printf '%s\n' "${PREV_REV}" > "${LAST_GOOD}"
log "📌 الإصدار السابق: ${PREV_REV} (سُجّل في ${LAST_GOOD})"

# ── 2. جلب أحدث كود ──
log "⬇️ git pull ..."
git pull --ff-only

# ── 3. الاعتماديات (الجذر + خدمة realtime) ──
log "📦 bun install --frozen-lockfile (الجذر) ..."
bun install --frozen-lockfile
log "📦 bun install --frozen-lockfile (mini-services/realtime) ..."
( cd mini-services/realtime && bun install --frozen-lockfile )
# توليد عميل Prisma (سكربت db:generate الرسمي في package.json) —
# ضروري بعد تثبيت نظيف لأن bun لا يشغّل خطوات postinstall للحزم
log "⚙️ prisma generate ..."
bunx prisma generate

# ── 4. الهجرات (DATABASE_URL من ملف البيئة) ──
log "🗄️ prisma migrate deploy ..."
set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a
if [[ -z "${DATABASE_URL:-}" ]]; then
  log "❌ DATABASE_URL غير مضبوطة في ${ENV_FILE}"
  exit 1
fi
bunx prisma migrate deploy

# ── 5. البناء ──
log "🏗️ bun run build ..."
bun run build

# ── 6. إعادة تشغيل الخدمتين (realtime أولًا ثم الويب) ──
log "🔄 systemctl restart (realtime ثم web) ..."
sudo -n systemctl restart cairo-hart-realtime.service
sleep 2
sudo -n systemctl restart cairo-hart-web.service

# ── 7. فحص الصحة — 3 محاولات ──
log "🏥 فحص الصحة: https://${DOMAIN}${HEALTH_PATH} ..."
HEALTH_OK=0
attempt=1
while (( attempt <= ATTEMPTS )); do
  sleep "${WAIT_SECONDS}"
  if curl -fsS --max-time 10 "https://${DOMAIN}${HEALTH_PATH}" > /dev/null 2>&1; then
    HEALTH_OK=1
    log "✅ [محاولة ${attempt}] فحص الصحة ناجح"
    break
  fi
  log "⚠️ [محاولة ${attempt}] فشل الفحص — إعادة المحاولة بعد ${WAIT_SECONDS} ث ..."
  attempt=$(( attempt + 1 ))
done

# ── 8. النجاح: هذا الإصدار هو «آخر إصدار جيد» ──
if (( HEALTH_OK > 0 )); then
  NEW_REV="$(git rev-parse HEAD)"
  printf '%s\n' "${NEW_REV}" > "${LAST_GOOD}"
  log "🎉 النشر ناجح — آخر إصدار جيد الآن: ${NEW_REV}"
  exit 0
fi

# ── 9. الفشل: طباعة أمر الاسترجاع والخروج برمز خطأ ──
log "❌ فشل النشر — فحص الصحة لم ينجح بعد ${ATTEMPTS} محاولات"
log "تشخيص فوري (انسخ ونفّذ):"
log "  journalctl -u cairo-hart-web.service -n 50 --no-pager"
log "  journalctl -u cairo-hart-realtime.service -n 50 --no-pager"
log "  curl -v https://${DOMAIN}${HEALTH_PATH}"
cat <<EOF

──────────── أمر الاسترجاع (انسخ ونفّذ كما هو) ────────────
cd ${APP_DIR}
sudo -n systemctl stop cairo-hart-web.service cairo-hart-realtime.service
git checkout --force ${PREV_REV}
bun install --frozen-lockfile
( cd mini-services/realtime && bun install --frozen-lockfile )
bunx prisma generate
bun run build
sudo -n systemctl start cairo-hart-realtime.service
sleep 2
sudo -n systemctl start cairo-hart-web.service
──────────────────────────────────────────────────────────
ملاحظات:
- الهجرات تسير للأمام فقط. إن طبّق هذا النشر الفاشل هجرة جديدة فافحص
  أولاً:  bunx prisma migrate status   ثم استشر المطور قبل الاسترجاع.
- إن كان الخلل في البيانات لا الكود: استعد آخر نسخة احتياطية عبر
  scripts/restore.sh (الوثيقة: docs/BACKUP_POLICY.md + RUNBOOK بطاقة IC-2).
EOF
log "خروج برمز 1 — آخر إصدار جيد مسجل في ${LAST_GOOD}: ${PREV_REV}"
exit 1
