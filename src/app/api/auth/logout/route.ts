// ─────────────────────────────────────────────────────────────
// POST /api/auth/logout — إنهاء الجلسة الحالية
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok } from '@/lib/api'
import { getAuth } from '@/lib/auth'

export const dynamic = 'force-dynamic'

export async function POST(req: NextRequest) {
  const auth = await getAuth(req)
  if (auth) {
    await db.session.updateMany({
      where: { accessCodeId: auth.codeId, revoked: false },
      data: { revoked: true },
    })
  }
  return ok()
}
