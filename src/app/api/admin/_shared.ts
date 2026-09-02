// ─────────────────────────────────────────────────────────────
// ADMIN API — أدوات مشتركة لمسارات /api/admin/*
// (ملف غير مسار — لا يُعرَّب كـ endpoint)
// ─────────────────────────────────────────────────────────────

/** parse JSON string → string[] (amenities / images) */
export function parseJsonArray(v: string | null | undefined): string[] {
  if (!v) return []
  try {
    const x = JSON.parse(v)
    return Array.isArray(x) ? x.filter((i): i is string => typeof i === 'string') : []
  } catch {
    return []
  }
}

/** parse JSON string → object (priceSnapshot / audit details) */
export function parseJsonObject(v: string | null | undefined): Record<string, unknown> {
  if (!v) return {}
  try {
    const x = JSON.parse(v)
    return typeof x === 'object' && x !== null && !Array.isArray(x) ? (x as Record<string, unknown>) : {}
  } catch {
    return {}
  }
}

export function asString(v: unknown): string | undefined {
  return typeof v === 'string' ? v : undefined
}

export function asInt(v: unknown): number | undefined {
  if (typeof v === 'number' && Number.isFinite(v)) return Math.trunc(v)
  if (typeof v === 'string' && v.trim() !== '' && Number.isFinite(Number(v))) return Math.trunc(Number(v))
  return undefined
}

export function asBool(v: unknown): boolean | undefined {
  return typeof v === 'boolean' ? v : undefined
}

/** نهاية اليوم بعد إضافة أيام (لصلاحية الأكواد) */
export function endOfDayAfter(days: number): Date {
  const d = new Date()
  d.setDate(d.getDate() + days)
  d.setHours(23, 59, 59, 999)
  return d
}

export function startOfDay(d: Date): Date {
  const x = new Date(d)
  x.setHours(0, 0, 0, 0)
  return x
}

export function endOfDay(d: Date): Date {
  const x = new Date(d)
  x.setHours(23, 59, 59, 999)
  return x
}

/** يوم بتاريخ فقط (مقارنة الليالي) */
export function dayKey(d: Date): string {
  const x = new Date(d)
  return `${x.getFullYear()}-${String(x.getMonth() + 1).padStart(2, '0')}-${String(x.getDate()).padStart(2, '0')}`
}

export const ROOM_STATUSES = ['AVAILABLE', 'OCCUPIED', 'RESERVED', 'CLEANING', 'DIRTY', 'OUT_OF_ORDER'] as const
export const MANUALLY_SETTABLE_ROOM_STATUSES = ['AVAILABLE', 'RESERVED', 'CLEANING', 'DIRTY', 'OUT_OF_ORDER'] as const
export const ACTIVE_REQUEST_STATUSES = ['NEW', 'ACKNOWLEDGED', 'ASSIGNED', 'IN_PROGRESS', 'WAITING'] as const
export const SERVICE_CATEGORY_KEYS = ['HOUSEKEEPING', 'MAINTENANCE', 'GUEST_SERVICES', 'OTHER'] as const
export const STAFF_ROLES = ['RECEPTION', 'ADMIN', 'MANAGER'] as const

/** هل خطأ Prisma قيد فريد مكرر؟ */
export function isUniqueViolation(e: unknown): boolean {
  return typeof e === 'object' && e !== null && (e as { code?: string }).code === 'P2002'
}
