// ─────────────────────────────────────────────────────────────
// RECEPTION TYPES — أنواع واجهة الاستقبال (مطابقة لاستجابات API)
// ─────────────────────────────────────────────────────────────
import type { BillPublic, RequestUpdatePublic } from '@/types'

export type ViewKey = 'dashboard' | 'arrivals' | 'departures' | 'inhouse' | 'requests' | 'rooms'

export interface ReceptionStats {
  arrivalsToday: number
  departuresToday: number
  inHouseStays: number
  pendingRequests: number
  urgentRequests: number
  occupancyPercent: number
  totalRooms: number
  occupiedRooms: number
}

export interface DashboardArrival {
  reservationId: string
  bookingReference: string
  guestName: string
  guestPhone: string
  roomTypeId: string
  roomTypeName: string
  nights: number
  paidCents: number
  grandTotalCents: number
  paymentStatus: string
  checkIn: string
  checkOut: string
}

export interface DashboardDeparture {
  stayId: string
  reference: string
  guestName: string
  roomNumber: string
  balanceCents: number
  status: string
  expectedCheckOutAt: string
}

export interface DashboardRequest {
  id: string
  reference: string
  roomNumber: string
  guestName: string
  title: string
  priority: string
  status: string
  createdAt: string
}

export interface DashboardData {
  stats: ReceptionStats
  arrivals: DashboardArrival[]
  departures: DashboardDeparture[]
  pendingRequests: DashboardRequest[]
}

export interface ArrivalGuest {
  id: string
  fullName: string
  phone: string
  whatsapp?: string | null
  email?: string | null
  idNumber?: string | null
  nationality?: string | null
}

export interface ArrivalItem {
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
  hasStay: boolean
  guest: ArrivalGuest
  roomType: {
    id: string
    name: string
    basePriceCents: number
    capacityAdults: number
    capacityChildren: number
    bedConfig: string
    sizeSqm: number
  }
}

export interface DepartureItem {
  id: string
  reference: string
  status: string
  guestName: string
  guestPhone: string
  roomNumber: string
  roomTypeName: string
  checkInAt: string
  expectedCheckOutAt: string
  balanceCents: number
  activeRequests: number
  overdue: boolean
}

export interface InHouseStay {
  id: string
  reference: string
  status: string
  checkInAt: string
  expectedCheckOutAt: string
  guest: { fullName: string; phone: string }
  room: { number: string; floor: number }
  roomType: { name: string }
  activeRequests: number
  balanceCents: number
  reservation: {
    grandTotalCents: number
    paidCents: number
    paymentStatus: string
  }
}

export interface RequestItem {
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
  stay: { id: string; reference: string; roomNumber: string; guestName: string }
  updates: RequestUpdatePublic[]
}

export interface RoomItem {
  id: string
  number: string
  floor: number
  status: string
  notes?: string | null
  roomTypeId: string
  roomTypeName: string
  guestName?: string | null
  expectedCheckOutAt?: string | null
  activeStayId?: string | null
}

export interface ExtensionRequestItem {
  id: string
  newCheckOut: string
  nights: number
  priceCents: number
  note?: string | null
  status: string
  decidedBy?: string | null
  decidedAt?: string | null
  createdAt: string
  stay: {
    id: string
    reference: string
    roomNumber: string
    guestName: string
    expectedCheckOutAt: string
    stayStatus: string
  }
}

export interface RoomChangeRequestItem {
  id: string
  toRoomId: string
  toRoomNumber: string
  priceDiffCents: number
  reason?: string | null
  status: string
  decidedBy?: string | null
  decidedAt?: string | null
  createdAt: string
  stay: { id: string; reference: string; roomNumber: string; guestName: string; stayStatus: string }
}

export interface StayDetailData {
  stay: {
    id: string
    reference: string
    status: string
    checkInAt: string
    expectedCheckOutAt: string
    actualCheckOutAt?: string | null
  }
  guest: ArrivalGuest
  room: { id: string; number: string; floor: number; status: string; notes?: string | null }
  roomType: { id: string; name: string; bedConfig: string; sizeSqm: number }
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
    paymentMethod?: string | null
    specialRequests?: string | null
    priceSnapshot: {
      roomTypeName?: string
      nightly?: { date: string; priceCents: number; rateName: string }[]
      [key: string]: unknown
    }
  }
  bill: BillPublic
  requests: RequestItem[]
  extensionRequests: ExtensionRequestItem[]
  roomChangeRequests: RoomChangeRequestItem[]
  messages: { id: string; sender: string; senderName: string; body: string; createdAt: string }[]
}

export interface CheckInResult {
  stay: { id: string; reference: string }
  roomNumber: string
  guestCode: string
  guestName: string
  guestPhone: string
}

export interface SearchResults {
  reservations: {
    id: string
    bookingReference: string
    guestName: string
    guestPhone: string
    status: string
    checkIn: string
    checkOut: string
    roomTypeName: string
    paymentStatus: string
    stayId: string | null
  }[]
  stays: {
    id: string
    reference: string
    guestName: string
    guestPhone: string
    roomNumber: string
    roomTypeName: string
    status: string
    expectedCheckOutAt: string
  }[]
}

export interface NotificationItem {
  id: string
  type: string
  title: string
  body: string
  read: boolean
  createdAt: string
}
