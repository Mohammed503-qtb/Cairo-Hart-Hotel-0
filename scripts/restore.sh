#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
# RESTORE — استعادة القاعدة من نسخة احتياطية (بطاقة RUNBOOK IC-2)
#
# الاستخدام:
#   sudo systemctl stop cairo-hart-web.service cairo-hart-realtime.service
#   bash scripts/restore.sh <ملف-النسخة.db>
#   sudo systemctl start cairo-hart-web.service cairo-hart-realtime.service
#
# في الرملة (بلا systemd): أوقف bun (الخادم + realtime) قبل الاستعادة.
# الجوهر: scripts/sqlite-tool.ts — يرفض أي نسخة فاشلة في quick_check
# ويصنع نسخة أمان من القاعدة الحالية قبل الاستبدال.
# ─────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="${APP_DIR:-$(dirname "${SCRIPT_DIR}")}"
DB="${APP_DIR}/db/custom.db"

SRC="${1:-}"
if [[ -z "${SRC}" || ! -f "${SRC}" ]]; then
  echo "❌ حدد ملف نسخة موجود: bash scripts/restore.sh /var/backups/cairo-hart/daily/custom_YYYY-MM-DD_HHMMSS.db"
  exit 2
fi

# تحذير صريح — الاستعادة كتابة مدمّرة للقاعدة الحالية
echo "⚠️  ستُستبدل القاعدة الحالية (${DB}) بـ ${SRC}"
echo "    الخدمات يجب أن تكون متوقفة (راجع docs/RUNBOOK.md — بطاقة IC-2)"
read -r -p "أكمل؟ (اكتب: نعم) " answer
if [[ "${answer}" != "نعم" ]]; then
  echo "أُلغيت الاستعادة — لم يُلمس شيء."
  exit 0
fi

bun "${SCRIPT_DIR}/sqlite-tool.ts" restore "${SRC}" "${DB}"

# تحقق تشغيلي بعد الاستعادة (إن كان الخادم يعمل)
if curl -fsS "${BASE_URL:-http://localhost:3000}/api/health" >/dev/null 2>&1; then
  echo "✅ الخادم يستجيب بعد الاستعادة — راجع السجل يدويًا"
else
  echo "ℹ️ الخادم غير مستجيب (متوقف غالبًا) — ابدأ الخدمات ثم تحقق من /api/health"
fi
