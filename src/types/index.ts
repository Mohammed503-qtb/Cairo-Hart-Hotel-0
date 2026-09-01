// ─────────────────────────────────────────────────────────────
// SHARED TYPES — أنواع مشتركة بين الواجهات و APIs
// ─────────────────────────────────────────────────────────────

export type Role = 'GUEST' | 'RECEPTION' | 'ADMIN'

export interface AppSession {
  token: string
  role: Role
  name: string
  expiresAt: string
}

export interface HotelPublic {
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
}

export interface RoomTypePublic {
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
}

export interface QuotePublic {
  nights: number
  roomsCount: number
  currency: string
  taxPercent: number
  nightly: { date: string; priceCents: number; rateName: string }[]
  subtotalCents: number
  discountCents: number
  taxCents: number
  grandTotalCents: number
}

export interface AvailabilityItem {
  roomType: RoomTypePublic
  availableCount: number
  quote: QuotePublic
}

export interface GuestSummary {
  id: string
  fullName: string
  phone: string
  whatsapp?: string | null
  email?: string | null
  nationality?: string | null
}

export interface ReservationPublic {
  id: string
  bookingReference: string
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
  taxCents: number
  grandTotalCents: number
  paidCents: number
  paymentStatus: string
  paymentMethod?: string | null
  specialRequests?: string | null
  createdAt: string
  guest: GuestSummary
  roomType: { id: string; name: string; basePriceCents: number }
  stayId?: string | null
}

export interface StaySummary {
  id: string
  reference: string
  status: string
  checkInAt: string
  expectedCheckOutAt: string
  actualCheckOutAt?: string | null
  room: { id: string; number: string; floor: number; status: string }
  roomType: { id: string; name: string; bedConfig: string; sizeSqm: number }
  guest: GuestSummary
  reservation: {
    id: string
    bookingReference: string
    adults: number
    children: number
    grandTotalCents: number
    paidCents: number
    paymentStatus: string
  }
}

export interface ServiceRequestPublic {
  id: string
  reference: string
  category: string
  title: string
  description?: string | null
  priority: string
  status: string
  assignedTo?: string | null
  createdAt: string
  updatedAt: string
  completedAt?: string | null
  stay?: { id: string; reference: string; roomNumber: string; guestName: string }
  updates?: RequestUpdatePublic[]
}

export interface RequestUpdatePublic {
  id: string
  status?: string | null
  note?: string | null
  byName: string
  byRole: string
  createdAt: string
}

export interface MessagePublic {
  id: string
  sender: 'GUEST' | 'RECEPTION'
  senderName: string
  body: string
  createdAt: string
}

export interface BillLine {
  description: string
  amountCents: number
  category?: string
  date?: string
}

export interface BillPublic {
  stayId: string
  stayReference: string
  roomTotalCents: number
  roomSubtotalCents: number
  roomTaxCents: number
  extraCharges: BillLine[]
  extraTotalCents: number
  payments: { id: string; method: string; amountCents: number; createdAt: string; recordedBy?: string | null }[]
  totalChargesCents: number
  totalPaidCents: number
  balanceCents: number
  currency: string
}

export interface NotificationPublic {
  id: string
  audience: string
  type: string
  title: string
  body: string
  read: boolean
  createdAt: string
}

export interface DashboardStats {
  arrivalsToday: number
  departuresToday: number
  inHouseGuests: number
  inHouseStays: number
  pendingRequests: number
  urgentRequests: number
  occupancyPercent: number
  totalRooms: number
  occupiedRooms: number
  availableRooms: number
  outOfOrderRooms: number
  revenueMonthCents: number
  activeGuestCodes: number
  activeStaffCodes: number
}
