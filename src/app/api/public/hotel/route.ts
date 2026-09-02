// GET /api/public/hotel — معلومات الفندق العامة
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { toHotelPublic } from '../_lib'

export const dynamic = 'force-dynamic'

export async function GET() {
  try {
    const hotel = await db.hotel.findFirst()
    if (!hotel) {
      return fail('معلومات الفندق غير متاحة حاليًا — يرجى المحاولة لاحقًا', 503)
    }
    return ok({ hotel: toHotelPublic(hotel) })
  } catch {
    return fail('حدث خطأ أثناء جلب معلومات الفندق', 500)
  }
}
