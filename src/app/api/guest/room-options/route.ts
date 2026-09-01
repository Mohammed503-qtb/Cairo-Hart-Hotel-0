// ─────────────────────────────────────────────────────────────
// GET /api/guest/room-options — الغرف المتاحة للنقل
// status=AVAILABLE فقط + فرق السعر عن الغرفة الحالية
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireGuest } from '../_lib'
import { loadStay } from '../_lib'

export const dynamic = 'force-dynamic'

export async function GET(req: NextRequest) {
  const guard = await requireGuest(req)
  if ('error' in guard) return fail(guard.error, guard.status)
  const { stayId } = guard.auth

  try {
    const stay = await loadStay(stayId)
    if (!stay) return fail('الإقامة غير موجودة', 404)

    const currentBaseCents = stay.room.roomType.basePriceCents

    const rooms = await db.room.findMany({
      where: { status: 'AVAILABLE' },
      include: { roomType: { select: { name: true, basePriceCents: true } } },
      orderBy: [{ floor: 'asc' }, { number: 'asc' }],
    })

    return ok({
      rooms: rooms.map((r) => ({
        roomId: r.id,
        number: r.number,
        floor: r.floor,
        typeName: r.roomType.name,
        basePriceCents: r.roomType.basePriceCents,
        diffCents: r.roomType.basePriceCents - currentBaseCents,
      })),
      currentRoom: {
        number: stay.room.number,
        typeName: stay.room.roomType.name,
        basePriceCents: currentBaseCents,
      },
    })
  } catch (e) {
    console.error('guest room options failed', e)
    return fail('حدث خطأ أثناء تحميل الغرف المتاحة — أعد المحاولة', 500)
  }
}
