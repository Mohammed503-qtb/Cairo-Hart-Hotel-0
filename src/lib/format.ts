// ─────────────────────────────────────────────────────────────
// FORMAT — أدوات عرض عربية (آمنة للعميل — لا تتضمن imports خادمية)
// ─────────────────────────────────────────────────────────────

const AR_MONTHS = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
]

const AR_DAYS = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت']

function toDate(d: string | Date): Date {
  return typeof d === 'string' ? new Date(d) : d
}

/** $1,234.50 */
export function formatMoney(cents: number, currency = 'USD'): string {
  const value = (cents ?? 0) / 100
  const num = value.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
  return currency === 'USD' ? `$${num}` : `${num} ${currency}`
}

/** 10 سبتمبر 2026 */
export function formatDateAr(d: string | Date): string {
  const date = toDate(d)
  return `${date.getDate()} ${AR_MONTHS[date.getMonth()]} ${date.getFullYear()}`
}

/** الخميس، 10 سبتمبر 2026 */
export function formatDateWithDayAr(d: string | Date): string {
  const date = toDate(d)
  return `${AR_DAYS[date.getDay()]}، ${formatDateAr(date)}`
}

/** 10 سبتمبر 2026 — 02:30 م */
export function formatDateTimeAr(d: string | Date): string {
  const date = toDate(d)
  const h = date.getHours()
  const h12 = h % 12 === 0 ? 12 : h % 12
  const period = h < 12 ? 'ص' : 'م'
  const mm = String(date.getMinutes()).padStart(2, '0')
  return `${formatDateAr(date)} — ${h12}:${mm} ${period}`
}

/** 02:30 م */
export function formatTimeAr(d: string | Date): string {
  const date = toDate(d)
  const h = date.getHours()
  const h12 = h % 12 === 0 ? 12 : h % 12
  const period = h < 12 ? 'ص' : 'م'
  const mm = String(date.getMinutes()).padStart(2, '0')
  return `${h12}:${mm} ${period}`
}

/** منذ لحظات / منذ 5 دقائق / منذ 3 ساعات ... */
export function timeAgoAr(d: string | Date): string {
  const diff = Date.now() - toDate(d).getTime()
  const mins = Math.floor(diff / 60_000)
  if (mins < 1) return 'الآن'
  if (mins < 60) return `منذ ${mins} دقيقة`
  const hours = Math.floor(mins / 60)
  if (hours < 24) return `منذ ${hours} ساعة`
  const days = Math.floor(hours / 24)
  if (days < 30) return `منذ ${days} يوم`
  return formatDateAr(d)
}

export function nightsBetweenDates(a: string | Date, b: string | Date): number {
  const d1 = toDate(a); d1.setHours(0, 0, 0, 0)
  const d2 = toDate(b); d2.setHours(0, 0, 0, 0)
  return Math.max(0, Math.round((d2.getTime() - d1.getTime()) / 86_400_000))
}

/** تاريخ اليوم بصيغة input[type=date] */
export function todayInputValue(): string {
  const d = new Date()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${d.getFullYear()}-${m}-${day}`
}

export function addDaysInput(value: string, days: number): string {
  const d = new Date(value + 'T00:00:00')
  d.setDate(d.getDate() + days)
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${d.getFullYear()}-${m}-${day}`
}

// ───────────── تسميات الحالات الموحدة (عربي) ─────────────

export const RESERVATION_STATUS_LABELS: Record<string, string> = {
  PENDING: 'قيد الانتظار',
  CONFIRMED: 'مؤكد',
  CANCELLED: 'ملغي',
  CHECKED_IN: 'مسجّل دخول',
  COMPLETED: 'مكتمل',
  NO_SHOW: 'لم يحضر',
  EXPIRED: 'منتهي',
}

export const PAYMENT_STATUS_LABELS: Record<string, string> = {
  UNPAID: 'غير مدفوع',
  PARTIALLY_PAID: 'مدفوع جزئيًا',
  PAID: 'مدفوع',
  REFUNDED: 'مُسترد',
}

export const PAYMENT_METHOD_LABELS: Record<string, string> = {
  PAY_AT_HOTEL: 'الدفع في الفندق',
  CARD: 'بطاقة',
  CASH: 'نقدًا',
  ONLINE: 'دفع إلكتروني',
  TRANSFER: 'حوالة',
}

export const ROOM_STATUS_LABELS: Record<string, string> = {
  AVAILABLE: 'متاحة',
  OCCUPIED: 'مشغولة',
  RESERVED: 'محجوزة',
  CLEANING: 'قيد التنظيف',
  DIRTY: 'تحتاج تنظيف',
  OUT_OF_ORDER: 'خارج الخدمة',
}

export const REQUEST_STATUS_LABELS: Record<string, string> = {
  NEW: 'جديد',
  ACKNOWLEDGED: 'قيد الاطلاع',
  ASSIGNED: 'مُسند',
  IN_PROGRESS: 'قيد التنفيذ',
  WAITING: 'انتظار',
  COMPLETED: 'مكتمل',
  CANCELLED: 'ملغي',
  REJECTED: 'مرفوض',
}

export const PRIORITY_LABELS: Record<string, string> = {
  NORMAL: 'عادي',
  URGENT: 'عاجل',
}

export const STAY_STATUS_LABELS: Record<string, string> = {
  ACTIVE: 'نشطة',
  CHECKOUT_REQUESTED: 'طُلب الخروج',
  CLOSED: 'مغلقة',
}

export const SOURCE_LABELS: Record<string, string> = {
  WEBSITE: 'الموقع',
  WHATSAPP: 'واتساب',
  PHONE: 'هاتف',
  WALK_IN: 'حضور مباشر',
  RECEPTION: 'الاستقبال',
}

export const CHARGE_CATEGORY_LABELS: Record<string, string> = {
  SERVICE: 'خدمة',
  EXTRA: 'إضافي',
  PENALTY: 'غرامة',
  ROOM_EXTENSION: 'تمديد إقامة',
}

export const EXTENSION_STATUS_LABELS: Record<string, string> = {
  PENDING: 'قيد المراجعة',
  APPROVED: 'مقبول',
  REJECTED: 'مرفوض',
}
