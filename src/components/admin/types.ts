// ─────────────────────────────────────────────────────────────
// ADMIN TYPES — أنواع استجابات /api/admin/*
// ─────────────────────────────────────────────────────────────
import type { DashboardStats } from '@/types'

export type SectionKey =
  | 'dashboard' | 'hotel' | 'room-types' | 'rooms' | 'rates' | 'services'
  | 'staff' | 'reservations' | 'guests' | 'reports' | 'audit'

export interface DashboardResponse {
  kpis: DashboardStats
  recentBookings: Array<{
    id: string
    reference: string
    guestName: string
    roomTypeName: string
    grandTotalCents: number
    status: string
    createdAt: string
  }>
  roomsByStatus: Record<string, number>
  alerts: { staleRequests: number; outOfOrderRooms: number }
  revenueByDay: Array<{ date: string; totalCents: number }>
}

export interface HotelAdmin {
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
  minAppVersion: string
  [key: string]: unknown
}

export interface RoomTypeAdmin {
  id: string
  name: string
  nameEn: string
  description: string
  capacityAdults: number
  capacityChildren: number
  bedConfig: string
  sizeSqm: number
  basePriceCents: number
  amenities: string[]
  images: string[]
  active: boolean
  sortOrder: number
  roomsCount: number
  reservationsCount: number
  ratesCount: number
  createdAt: string
}

export interface RoomAdmin {
  id: string
  number: string
  floor: number
  status: string
  notes: string | null
  roomTypeId: string
  roomTypeName: string
  guestName: string | null
  expectedCheckOut: string | null
  createdAt: string
}

export interface RateAdmin {
  id: string
  name: string
  roomTypeId: string
  roomTypeName: string
  roomTypeBasePriceCents: number
  startDate: string
  endDate: string
  priceCents: number
  active: boolean
  createdAt: string
}

export interface ServiceAdmin {
  id: string
  name: string
  nameEn: string
  description: string
  priceCents: number
  active: boolean
  sortOrder: number
  categoryId: string
  categoryName: string
  categoryKey: string
}

export interface ServiceCategoryAdmin {
  id: string
  name: string
  nameEn: string
  key: string
  icon: string
  sortOrder: number
  servicesCount: number
}

export interface StaffAdmin {
  id: string
  fullName: string
  role: string
  phone: string | null
  active: boolean
  createdAt: string
  lastCode: { codeMasked: string; type: string; status: string; expiresAt: string } | null
}

export interface AccessCodeAdmin {
  id: string
  codeMasked: string
  type: string
  status: string
  expiresAt: string
  lastUsedAt: string | null
  createdAt: string
  staffName: string | null
  staffRole: string | null
  guestName: string | null
  roomNumber: string | null
  stayReference: string | null
}

export interface ReservationListItem {
  id: string
  reference: string
  guestName: string
  guestPhone: string
  roomTypeName: string
  checkIn: string
  checkOut: string
  nights: number
  adults: number
  children: number
  grandTotalCents: number
  paidCents: number
  paymentStatus: string
  status: string
  source: string
  createdAt: string
  stayId: string | null
}

export interface Paginated<T> {
  items: T[]
  total: number
  page: number
  limit: number
  pages: number
}

export interface ReservationDetail {
  id: string
  reference: string
  status: string
  source: string
  checkIn: string
  checkOut: string
  nights: number
  adults: number
  children: number
  roomsCount: number
  currency: string
  subtotalCents: number
  discountCents: number
  taxCents: number
  grandTotalCents: number
  paidCents: number
  paymentStatus: string
  paymentMethod: string | null
  specialRequests: string | null
  createdAt: string
  confirmedAt: string | null
  cancelledAt: string | null
  guest: { id: string; fullName: string; phone: string; email: string | null; nationality: string | null }
  roomType: { id: string; name: string; nameEn: string; basePriceCents: number }
  payments: Array<{
    id: string
    method: string
    amountCents: number
    status: string
    reference: string | null
    note: string | null
    recordedBy: string | null
    createdAt: string
  }>
  stay: {
    id: string
    reference: string
    status: string
    checkInAt: string
    expectedCheckOutAt: string
    actualCheckOutAt: string | null
    roomNumber: string
  } | null
  priceSnapshot: PriceSnapshot
}

export interface PriceSnapshot {
  version?: number
  roomTypeName?: string
  nightly?: Array<{ date: string; priceCents: number; rateName: string }>
  subtotalCents?: number
  discountCents?: number
  taxCents?: number
  grandTotalCents?: number
  currency?: string
  taxPercent?: number
  roomsCount?: number
  cancellationPolicy?: string
  checkInTime?: string
  checkOutTime?: string
  bookedAt?: string
  [key: string]: unknown
}

export interface GuestAdmin {
  id: string
  fullName: string
  phone: string
  email: string | null
  nationality: string | null
  createdAt: string
  reservationsCount: number
  lastReservation: { bookingReference: string; checkIn: string; status: string } | null
}

export interface AuditItem {
  id: string
  action: string
  entityType: string
  entityId: string
  actor: string
  actorRole: string
  details: string
  createdAt: string
}

export interface ReportsResponse {
  effectiveRooms: number
  occupancyLast14Days: Array<{ date: string; label: string; percent: number; occupied: number }>
  revenueByMonth: Array<{ month: string; totalCents: number; count: number }>
  requestsStats: {
    total: number
    byStatus: Array<{ status: string; count: number }>
    completed: number
    active: number
    avgCompletionMinutes: number | null
    topServices: Array<{ title: string; count: number }>
  }
  guestsByNationality: Array<{ nationality: string; count: number }>
}

export interface NotificationItem {
  id: string
  audience: string
  type: string
  title: string
  body: string
  read: boolean
  createdAt: string
}
