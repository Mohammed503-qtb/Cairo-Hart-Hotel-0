// ─────────────────────────────────────────────────────────────
// PUBLIC API SHARED HELPERS — مساعدات مشتركة لمسارات /api/public
// (ملف خاص بمسارات الموقع العامة — لا يُصدَّر كـ route)
// ─────────────────────────────────────────────────────────────
import { nightsBetween } from '@/lib/pricing'
import { formatDateAr } from '@/lib/format'
import type { Prisma } from '@prisma/client'
import type { HotelPublic, ReservationPublic, RoomTypePublic } from '@/types'

export type ReservationWithRelations = Prisma.ReservationGetPayload<{
  include: { guest: true; roomType: true }
}>

/** parse آمن لمصفوفة JSON مخزنة كنص */
export function parseJsonArray<T = string>(raw: string | null | undefined): T[] {
  if (!raw) return []
  try {
    const v = JSON.parse(raw) as unknown
    return Array.isArray(v) ? (v as T[]) : []
  } catch {
    return []
  }
}

/** لقطة السعر المخزنة مع الحجز (parsed بأمان) */
export function parseSnapshot(raw: string | null | undefined): Record<string, unknown> | null {
  if (!raw) return null
  try {
    const v = JSON.parse(raw) as unknown
    return v && typeof v === 'object' ? (v as Record<string, unknown>) : null
  } catch {
    return null
  }
}

export function digitsOnly(s: unknown): string {
  return String(s ?? '').replace(/\D/g, '')
}

/** آخر N أرقام من رقم هاتف (للمطابقة دون كشف التنسيق) */
export function lastNDigits(s: unknown, n = 9): string {
  const d = digitsOnly(s)
  return d.slice(-n)
}

/** قناع الهاتف: يُظهر أول 3 أرقام وآخر 4 فقط — +967****4567 */
export function maskPhone(phone: string | null | undefined): string {
  const d = digitsOnly(phone)
  if (d.length === 0) return ''
  if (d.length <= 4) return '+****'
  if (d.length < 8) return `+${'*'.repeat(d.length - 4)}${d.slice(-4)}`
  return `+${d.slice(0, 3)}****${d.slice(-4)}`
}

/** "YYYY-MM-DD" → Date منتصف الليل المحلي، أو null */
export function inputToDate(v: unknown): Date | null {
  if (typeof v !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(v)) return null
  const d = new Date(`${v}T00:00:00`)
  return Number.isNaN(d.getTime()) ? null : d
}

export function toRoomTypePublic(t: {
  id: string
  name: string
  nameEn: string
  description: string
  capacityAdults: number
  capacityChildren: number
  bedConfig: string
  sizeSqm: number
  basePriceCents: number
  amenities: string
  images: string
}): RoomTypePublic {
  return {
    id: t.id,
    name: t.name,
    nameEn: t.nameEn,
    description: t.description,
    capacityAdults: t.capacityAdults,
    capacityChildren: t.capacityChildren,
    bedConfig: t.bedConfig,
    sizeSqm: t.sizeSqm,
    basePriceCents: t.basePriceCents,
    amenities: parseJsonArray<string>(t.amenities),
    images: parseJsonArray<string>(t.images),
  }
}

export function toHotelPublic(h: {
  id: string
  name: string
  tagline: string
  description: string
  phone: string
  whatsapp: string
  email: string
  address: string
  city: string
  country: string
  currency: string
  taxPercent: number
  weekendSurchargePercent: number
  checkInTime: string
  checkOutTime: string
  minStayNights: number
  maxStayNights: number
  bookingHorizonDays: number
  cancellationPolicy: string
  paymentPolicy: string
  childrenPolicy: string
  petsPolicy: string
  smokingPolicy: string
}): HotelPublic {
  return {
    id: h.id,
    name: h.name,
    tagline: h.tagline,
    description: h.description,
    phone: h.phone,
    whatsapp: h.whatsapp,
    email: h.email,
    address: h.address,
    city: h.city,
    country: h.country,
    currency: h.currency,
    taxPercent: h.taxPercent,
    weekendSurchargePercent: h.weekendSurchargePercent,
    checkInTime: h.checkInTime,
    checkOutTime: h.checkOutTime,
    minStayNights: h.minStayNights,
    maxStayNights: h.maxStayNights,
    bookingHorizonDays: h.bookingHorizonDays,
    cancellationPolicy: h.cancellationPolicy,
    paymentPolicy: h.paymentPolicy,
    childrenPolicy: h.childrenPolicy,
    petsPolicy: h.petsPolicy,
    smokingPolicy: h.smokingPolicy,
  }
}

/** الحجز → شكل عام آمن للعرض (هاتف الضيف مقنّع) */
export function toReservationPublic(r: ReservationWithRelations): ReservationPublic {
  return {
    id: r.id,
    bookingReference: r.bookingReference,
    status: r.status,
    source: r.source,
    checkIn: r.checkIn.toISOString(),
    checkOut: r.checkOut.toISOString(),
    nights: nightsBetween(r.checkIn, r.checkOut),
    adults: r.adults,
    children: r.children,
    roomsCount: r.roomsCount,
    currency: r.currency,
    subtotalCents: r.subtotalCents,
    taxCents: r.taxCents,
    grandTotalCents: r.grandTotalCents,
    paidCents: r.paidCents,
    paymentStatus: r.paymentStatus,
    paymentMethod: r.paymentMethod,
    specialRequests: r.specialRequests,
    createdAt: r.createdAt.toISOString(),
    guest: {
      id: r.guest.id,
      fullName: r.guest.fullName,
      phone: maskPhone(r.guest.phone),
      whatsapp: r.guest.whatsapp ? maskPhone(r.guest.whatsapp) : null,
      email: r.guest.email,
      nationality: r.guest.nationality,
    },
    roomType: {
      id: r.roomType.id,
      name: r.roomType.name,
      basePriceCents: r.roomType.basePriceCents,
    },
  }
}

/** تفكيك لقطة السعر إلى الشكل الذي تعيده واجهات lookup/cancel */
export function snapshotBreakdown(r: { priceSnapshot: string }): {
  nightly: { date: string; priceCents: number; rateName: string }[]
  subtotalCents: number
  taxCents: number
  grandTotalCents: number
  cancellationPolicy: string
  checkInTime: string
  checkOutTime: string
} | null {
  const snap = parseSnapshot(r.priceSnapshot)
  if (!snap) return null
  const nightly = Array.isArray(snap.nightly)
    ? (snap.nightly as { date: string; priceCents: number; rateName: string }[])
    : []
  return {
    nightly,
    subtotalCents: Number(snap.subtotalCents ?? 0),
    taxCents: Number(snap.taxCents ?? 0),
    grandTotalCents: Number(snap.grandTotalCents ?? 0),
    cancellationPolicy: String(snap.cancellationPolicy ?? ''),
    checkInTime: String(snap.checkInTime ?? ''),
    checkOutTime: String(snap.checkOutTime ?? ''),
  }
}

/**
 * سياسة الإلغاء: مجاني حتى (الوصول − 24 ساعة)، وبعدها رسوم ليلة واحدة.
 * تُحسب من لقطة السعر المحفوظة (سعر الليلة الأولى الفعلي × عدد الغرف).
 */
export function cancellationInfo(r: {
  checkIn: Date
  roomsCount: number
  subtotalCents: number
  priceSnapshot: string
}): { refundable: boolean; penaltyCents: number; freeUntil: string } {
  const freeUntil = new Date(new Date(r.checkIn).getTime() - 24 * 3_600_000)
  const refundable = new Date() < freeUntil
  let penaltyCents = 0
  if (!refundable) {
    const snap = snapshotBreakdown({ priceSnapshot: r.priceSnapshot })
    const firstNight = snap?.nightly?.[0]?.priceCents
    const snapRooms = Number((snap as unknown as { roomsCount?: number } | null)?.roomsCount)
    const rooms = snapRooms > 0 ? snapRooms : r.roomsCount
    if (typeof firstNight === 'number' && firstNight > 0) {
      penaltyCents = firstNight * rooms
    } else {
      const nights = snap?.nightly?.length || 0
      penaltyCents = nights > 0 ? Math.round(r.subtotalCents / nights) : 0
    }
  }
  return { refundable, penaltyCents, freeUntil: freeUntil.toISOString() }
}

/** تاريخ عربي لرسائل الإشعارات */
export function arDate(d: Date): string {
  return formatDateAr(d)
}
