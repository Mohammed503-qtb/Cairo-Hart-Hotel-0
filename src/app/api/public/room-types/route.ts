// GET /api/public/room-types — أنواع الغرف النشطة (مرتبة بـ sortOrder)
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { toRoomTypePublic } from '../_lib'

export const dynamic = 'force-dynamic'

export async function GET() {
  try {
    const hotel = await db.hotel.findFirst()
    if (!hotel) {
      return fail('معلومات الفندق غير متاحة حاليًا — يرجى المحاولة لاحقًا', 503)
    }
    const types = await db.roomType.findMany({
      where: { hotelId: hotel.id, active: true },
      orderBy: { sortOrder: 'asc' },
    })
    return ok({ roomTypes: types.map(toRoomTypePublic) })
  } catch {
    return fail('حدث خطأ أثناء جلب أنواع الغرف', 500)
  }
}
