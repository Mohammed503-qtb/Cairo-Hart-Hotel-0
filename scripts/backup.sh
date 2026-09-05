#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# BACKUP — نسخة احتياطية آمنة لقاعدة SQLite (P2 — Task 24-d)
#
# التشغيل:  bash scripts/backup.sh          (يدويًا أو عبر cron 02:00)
# المسارات قابلة للتجاوز للرملة:  APP_DIR=… BACKUP_ROOT=… bash scripts/backup.sh
# الجوهر: scripts/sqlite-tool.ts (bun:sqlite — VACUUM INTO متناسقة
#         + quick_check فوري، بلا اعتماد على ثنائي sqlite3)
# السياسة: docs/BACKUP_POLICY.md
# ─────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${APP_DIR:-$(dirname "${SCRIPT_DIR}")}"
DB="${APP_DIR}/db/custom.db"
BACKUP_ROOT="${BACKUP_ROOT:-/var/backups/cairo-hart}"
STAMP="$(date +%F_%H%M%S)"

# متغيرات اختيارية من ملف البيئة (RCLONE_REMOTE)
ENV_FILE="${ENV_FILE:-/etc/cairo-hart/env}"
if [[ -r "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

[[ -f "${DB}" ]] || { echo "❌ القاعدة غير موجودة: ${DB}"; exit 1; }

mkdir -p "${BACKUP_ROOT}/daily" "${BACKUP_ROOT}/weekly" "${BACKUP_ROOT}/monthly"
DEST="${BACKUP_ROOT}/daily/custom_${STAMP}.db"

# 1+2+3) لقطة متناسقة + فحص فوري (فشل الفحص = فشل النسخة)
bun "${SCRIPT_DIR}/sqlite-tool.ts" backup "${DB}" "${DEST}"
chmod 640 "${DEST}" 2>/dev/null || chmod 644 "${DEST}"

# 4) تصنيف أسبوعي (السبت) وشهري (أول الشهر)
if [[ "$(date +%u)" == "6" ]]; then
  cp -p "${DEST}" "${BACKUP_ROOT}/weekly/"
fi
if [[ "$(date +%-d)" == "1" ]]; then
  cp -p "${DEST}" "${BACKUP_ROOT}/monthly/"
fi

# 5) خارج الموقع (اختياري — rclone مضبوط مسبقًا)
if [[ -n "${RCLONE_REMOTE:-}" ]] && command -v rclone >/dev/null 2>&1; then
  if rclone copy "${DEST}" "${RCLONE_REMOTE}/db/" --quiet; then
    echo "✅ رُفعت خارج الموقع: ${RCLONE_REMOTE}/db/"
  else
    echo "⚠️ فشل الرفع خارج الموقع — راجع docs/BACKUP_POLICY.md §7"
  fi
fi

# 6) الاحتفاظ: يومي 7 · أسبوعي 4 · شهري 6
ls -1t "${BACKUP_ROOT}/daily/"   2>/dev/null | grep '\.db$' | tail -n +8 | xargs -r rm -f --
ls -1t "${BACKUP_ROOT}/weekly/"  2>/dev/null | grep '\.db$' | tail -n +5 | xargs -r rm -f --
ls -1t "${BACKUP_ROOT}/monthly/" 2>/dev/null | grep '\.db$' | tail -n +7 | xargs -r rm -f --

echo "✅ اكتملت النسخة الاحتياطية (${STAMP})"
