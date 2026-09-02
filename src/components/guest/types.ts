// ─────────────────────────────────────────────────────────────
// GUEST APP TYPES — أنواع تطبيق الضيف (مطابقة لاستجابات API)
// ─────────────────────────────────────────────────────────────
import type { MessagePublic, NotificationPublic, RequestUpdatePublic } from '@/types'

export type GuestTab = 'home' | 'stay' | 'services' | 'bill'

export type GuestDialogKind = 'chat' | 'extension' | 'room-change' | 'checkout' | 'feedback' | null

export interface GuestStayInfo {
  id: string
  reference: string
  status: string
  checkInAt: string
  expectedCheckOutAt: string
  actualCheckOutAt: string | null
  guestName: string
  room: { id: string; number: string; floor: number; status: string }
  roomType: {
    id: string
    name: string
    bedConfig: string
    sizeSqm: number
    basePriceCents: number
    amenities: string[]
    images: string[]
  }
  reservation: {
    id: string
    bookingReference: string
    status: string
    source: string
    checkIn: string
    checkOut: string
    adults: number
    children: number
    roomsCount: number
    currency: string
    subtotalCents: number
    taxCents: number
    grandTotalCents: number
    paidCents: number
    paymentStatus: string
    paymentMethod: string | null
    specialRequests: string | null
    createdAt: string
  }
}

export interface GuestHotelBrief {
  name: string
  phone: string
  whatsapp: string
  checkInTime: string
  checkOutTime: string
}

export interface GuestHotelFull extends GuestHotelBrief {
  address: string
  city: string
  email: string
  cancellationPolicy: string
  paymentPolicy: string
  childrenPolicy: string
  petsPolicy: string
  smokingPolicy: string
}

export interface GuestDashboardData {
  stay: GuestStayInfo & { totalNights: number; remainingNights: number }
  notifications: NotificationPublic[]
  unreadCount: number
  activeRequests: number
  balanceCents: number
  chargesCents: number
  currency: string
  hotel: GuestHotelBrief
}

export interface SnapshotNight {
  date: string
  priceCents: number
  rateName: string
}

export interface GuestStayData {
  stay: GuestStayInfo
  snapshot: {
    roomTypeName: string
    nightly: SnapshotNight[]
    subtotalCents: number
    taxCents: number
    grandTotalCents: number
    currency: string
    taxPercent: number
    roomsCount: number
    cancellationPolicy: string
    checkInTime: string
    checkOutTime: string
    bookedAt: string | null
  } | null
  nights: number
  remainingNights: number
  hotel: GuestHotelFull | null
}

export interface GuestRequest {
  id: string
  reference: string
  category: string
  title: string
  description: string | null
  priority: string
  status: string
  assignedTo: string | null
  createdAt: string
  updatedAt: string
  completedAt: string | null
  roomNumber: string
  updates: RequestUpdatePublic[]
}

export type ServiceCategoryKey = 'HOUSEKEEPING' | 'MAINTENANCE' | 'GUEST_SERVICES' | 'OTHER'

export interface GuestServiceItem {
  id: string
  name: string
  description: string
  priceCents: number
  categoryKey: ServiceCategoryKey
}

export interface GuestServiceCategory {
  id: string
  name: string
  key: ServiceCategoryKey
  icon: string
  services: GuestServiceItem[]
}

export interface GuestBillData {
  stayId: string
  stayReference: string
  roomNumber: string
  roomNights: number
  roomTotalCents: number
  roomSubtotalCents: number
  roomTaxCents: number
  extraCharges: {
    id: string
    description: string
    amountCents: number
    category: string
    date: string
  }[]
  extraTotalCents: number
  payments: {
    id: string
    method: string
    amountCents: number
    createdAt: string
    recordedBy: string | null
  }[]
  totalChargesCents: number
  totalPaidCents: number
  balanceCents: number
  currency: string
}

export interface RoomOption {
  roomId: string
  number: string
  floor: number
  typeName: string
  basePriceCents: number
  diffCents: number
}

export interface ExtensionQuote {
  nights: number
  currency: string
  taxPercent: number
  nightly: SnapshotNight[]
  subtotalCents: number
  taxCents: number
  grandTotalCents: number
}

export interface ExtensionResult {
  request: {
    id: string
    newCheckOut: string
    nights: number
    priceCents: number
    note: string | null
    status: string
    createdAt: string
  }
  quote: ExtensionQuote
}

export interface RoomChangeResult {
  request: {
    id: string
    toRoomNumber: string
    priceDiffCents: number
    remainingNights: number
    reason: string | null
    status: string
    createdAt: string
  }
}

export type GuestMessages = MessagePublic[]
