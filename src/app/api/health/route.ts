// ─────────────────────────────────────────────────────────────
// GET /api/health — فحص جاهزية عام رخيص (P3 — Task 24-e)
//
// الغرض: مراقبة التشغيل (scripts/health-check.sh + Caddy الصحي)
// يعيد 200 فقط عندما تستجيب قاعدة البيانات فعلًا.
// عام بلا مصادقة عمدًا: لا يكشف أي بيانات — فقط الحالة والإصدار.
// ─────────────────────────────────────────────────────────────
import { NextResponse } from 'next/server'
import { db } from '@/lib/db'
import { version } from '../../../../package.json'

export const dynamic = 'force-dynamic'

export async function GET() {
  const startedAt = Date.now()
  try {
    await db.$queryRaw`SELECT 1`
    return NextResponse.json(
      {
        ok: true,
        db: true,
        service: 'cairo-hart-web',
        version,
        checkedAt: new Date().toISOString(),
        tookMs: Date.now() - startedAt,
      },
      { headers: { 'cache-control': 'no-store' } }
    )
  } catch {
    return NextResponse.json(
      {
        ok: false,
        db: false,
        service: 'cairo-hart-web',
        version,
        checkedAt: new Date().toISOString(),
        tookMs: Date.now() - startedAt,
      },
      { status: 503, headers: { 'cache-control': 'no-store' } }
    )
  }
}
