// ─────────────────────────────────────────────────────────────
// GUEST API HELPERS — مشترك بين مسارات ضيف (localhost only)
// كل الدوال تخص إقامة الجلسة حصرًا — عزل البيانات إلزامي
// ─────────────────────────────────────────────────────────────
import { Prisma } from '@prisma/client'
import { db } from '@/lib/db'
import { requireRole, type AuthContext } from '@/lib/auth'

export type GuestAuth = Extract<AuthContext, { role: 'GUEST' }>

/**
 * حارس موحد لمسارات الضيف — نفس requireRole(req, 'GUEST')
 * لكن يعيد نوع GUEST مُضيّقًا (stayId, guestName) لسلامة الأنواع
 */
export async function requireGuest(
  req: Request
): Promise<{ auth: GuestAuth } | { error: string; status: number }> {
  const guard = await requireRole(req, 'GUEST')
  if ('error' in guard) return guard
  return { auth: guard.auth as GuestAuth }
}

/** خطأ قابل للتحويل لاستجابة API */
export class GuestApiError extends Error {
  status: number
  constructor(message: string, status = 400) {
    super(message)
    this.status = status
  }
}

/** تحليل JSON مخزن كنص — يرجع [] عند الفشل */
export function safeJsonArray(value: string | null | undefined): string[] {
  try {
    const parsed: unknown = JSON.parse(value ?? '[]')
    if (!Array.isArray(parsed)) return []
    return parsed.filter((x): x is string => typeof x === 'string')
  } catch {
    return []
  }
}

/** بداية اليوم المحلي */
export function startOfDayLocal(d: Date | string): Date {
  const x = new Date(d)
  x.setHours(0, 0, 0, 0)
  return x
}

/** نهاية اليوم المحلي */
export function endOfDayLocal(d: Date | string): Date {
  const x = new Date(d)
  x.setHours(23, 59, 59, 999)
  return x
}

/** تحليل YYYY-MM-DD — يرجع null عند الصيغة/القيمة غير الصالحة */
export function parseDateInput(v: unknown): Date | null {
  if (typeof v !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(v.trim())) return null
  const d = new Date(`${v.trim()}T00:00:00`)
  return Number.isNaN(d.getTime()) ? null : d
}

/** عدد الليالي بحدود الأيام (لا طوابع زمنية) */
export function nightsBetweenDays(a: Date | string, b: Date | string): number {
  const x = startOfDayLocal(a)
  const y = startOfDayLocal(b)
  return Math.round((y.getTime() - x.getTime()) / 86_400_000)
}

// ───────────────────────────────────── إقامة الجلسة ─────────────────────────────────────

export type StayWithRelations = Prisma.StayGetPayload<{
  include: { room: { include: { roomType: true } }; reservation: true; guest: true }
}>

/** جلب إقامة الجلسة مع كل العلاقات */
export async function loadStay(stayId: string): Promise<StayWithRelations | null> {
  return db.stay.findUnique({
    where: { id: stayId },
    include: {
      room: { include: { roomType: true } },
      reservation: true,
      guest: true,
    },
  })
}

/** الشكل المسلسل للإقامة (تواريخ ISO + مصفوفات محالة) */
export function serializeStay(stay: StayWithRelations) {
  const rt = stay.room.roomType
  return {
    id: stay.id,
    reference: stay.reference,
    status: stay.status,
    checkInAt: stay.checkInAt.toISOString(),
    expectedCheckOutAt: stay.expectedCheckOutAt.toISOString(),
    actualCheckOutAt: stay.actualCheckOutAt?.toISOString() ?? null,
    guestName: stay.guest.fullName,
    room: {
      id: stay.room.id,
      number: stay.room.number,
      floor: stay.room.floor,
      status: stay.room.status,
    },
    roomType: {
      id: rt.id,
      name: rt.name,
      bedConfig: rt.bedConfig,
      sizeSqm: rt.sizeSqm,
      basePriceCents: rt.basePriceCents,
      amenities: safeJsonArray(rt.amenities),
      images: safeJsonArray(rt.images),
    },
    reservation: {
      id: stay.reservation.id,
      bookingReference: stay.reservation.bookingReference,
      status: stay.reservation.status,
      source: stay.reservation.source,
      checkIn: stay.reservation.checkIn.toISOString(),
      checkOut: stay.reservation.checkOut.toISOString(),
      adults: stay.reservation.adults,
      children: stay.reservation.children,
      roomsCount: stay.reservation.roomsCount,
      currency: stay.reservation.currency,
      subtotalCents: stay.reservation.subtotalCents,
      taxCents: stay.reservation.taxCents,
      grandTotalCents: stay.reservation.grandTotalCents,
      paidCents: stay.reservation.paidCents,
      paymentStatus: stay.reservation.paymentStatus,
      paymentMethod: stay.reservation.paymentMethod,
      specialRequests: stay.reservation.specialRequests,
      createdAt: stay.reservation.createdAt.toISOString(),
    },
  }
}

export type SerializedStay = ReturnType<typeof serializeStay>

/** رصيد الإقامة = إجمالي الحجز + بنود الإقامة − مدفوعات الحجز */
export async function computeStayBalance(
  stay: { id: string } & {
    reservation: Pick<StayWithRelations['reservation'], 'grandTotalCents' | 'paidCents' | 'currency'>
  }
): Promise<{ chargesCents: number; balanceCents: number; currency: string }> {
  const agg = await db.charge.aggregate({
    _sum: { amountCents: true },
    where: { stayId: stay.id },
  })
  const chargesCents = agg._sum.amountCents ?? 0
  return {
    chargesCents,
    balanceCents: stay.reservation.grandTotalCents + chargesCents - stay.reservation.paidCents,
    currency: stay.reservation.currency,
  }
}

/** الفندق (سجل واحد) */
export async function loadHotel() {
  return db.hotel.findFirst()
}

/** معلومات الفندق المختصرة لواجهة الضيف */
export function hotelBrief(hotel: Awaited<ReturnType<typeof loadHotel>>) {
  if (!hotel) {
    return { name: 'الفندق', phone: '', whatsapp: '', checkInTime: '14:00', checkOutTime: '12:00' }
  }
  return {
    name: hotel.name,
    phone: hotel.phone,
    whatsapp: hotel.whatsapp,
    checkInTime: hotel.checkInTime,
    checkOutTime: hotel.checkOutTime,
  }
}

// ───────────────────────────────────── طلبات الخدمة ─────────────────────────────────────

export type RequestWithUpdates = Prisma.ServiceRequestGetPayload<{
  include: { updates: true }
}>

/** الشكل المسلسل لطلب خدمة مع تحديثاته + رقم الغرفة */
export function serializeRequest(
  request: RequestWithUpdates,
  roomNumber: string
) {
  return {
    id: request.id,
    reference: request.reference,
    category: request.category,
    title: request.title,
    description: request.description,
    priority: request.priority,
    status: request.status,
    assignedTo: request.assignedTo,
    createdAt: request.createdAt.toISOString(),
    updatedAt: request.updatedAt.toISOString(),
    completedAt: request.completedAt?.toISOString() ?? null,
    roomNumber,
    updates: request.updates.map((u) => ({
      id: u.id,
      status: u.status,
      note: u.note,
      byName: u.byName,
      byRole: u.byRole,
      createdAt: u.createdAt.toISOString(),
    })),
  }
}

// ───────────────────────────────────── لقطة الحجز ─────────────────────────────────────

export interface SnapshotNight {
  date: string
  priceCents: number
  rateName: string
}

export interface ReservationSnapshot {
  roomTypeName?: string
  nightly: SnapshotNight[]
  subtotalCents: number
  taxCents: number
  grandTotalCents: number
  currency: string
  taxPercent: number
  roomsCount: number
  cancellationPolicy?: string
  checkInTime?: string
  checkOutTime?: string
  bookedAt?: string
}

/** تحليل لقطة السعر المحفوظة مع الحجز */
export function parseSnapshot(raw: string): ReservationSnapshot | null {
  try {
    const parsed: unknown = JSON.parse(raw || '{}')
    if (typeof parsed !== 'object' || parsed === null) return null
    const s = parsed as Record<string, unknown>
    const nightly = Array.isArray(s.nightly)
      ? s.nightly
          .filter(
            (n): n is SnapshotNight =>
              typeof n === 'object' && n !== null && 'date' in n && 'priceCents' in n
          )
          .map((n) => ({
            date: String(n.date),
            priceCents: Number(n.priceCents) || 0,
            rateName: String(n.rateName ?? 'السعر الأساسي'),
          }))
      : []
    return {
      roomTypeName: typeof s.roomTypeName === 'string' ? s.roomTypeName : undefined,
      nightly,
      subtotalCents: Number(s.subtotalCents) || 0,
      taxCents: Number(s.taxCents) || 0,
      grandTotalCents: Number(s.grandTotalCents) || 0,
      currency: typeof s.currency === 'string' ? s.currency : 'USD',
      taxPercent: Number(s.taxPercent) || 0,
      roomsCount: Number(s.roomsCount) || 1,
      cancellationPolicy: typeof s.cancellationPolicy === 'string' ? s.cancellationPolicy : undefined,
      checkInTime: typeof s.checkInTime === 'string' ? s.checkInTime : undefined,
      checkOutTime: typeof s.checkOutTime === 'string' ? s.checkOutTime : undefined,
      bookedAt: typeof s.bookedAt === 'string' ? s.bookedAt : undefined,
    }
  } catch {
    return null
  }
}
