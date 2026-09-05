'use client'

// ─────────────────────────────────────────────────────────────
// CONTENT ICONS — تحويل مفاتيح الأيقونات (IconKey) لمكونات Lucide
// مشترك بين موقع الفندق ولوحة إدارة المحتوى (منتقي الأيقونات)
// ─────────────────────────────────────────────────────────────
import {
  BedDouble, Clock, CalendarCheck2, Wifi, MessageCircle, SquareParking, Shirt,
  Tv, ShieldCheck, Star, Waves, Dumbbell, Utensils, Coffee, MapPin, Phone,
  Mail, Sparkles, ConciergeBell, Luggage, Car, Wind, BellRing, Bath,
  Binoculars, Users, type LucideIcon,
} from 'lucide-react'
import { ICON_LABELS, type IconKey } from '@/lib/site-content'

export const CONTENT_ICONS: Record<IconKey, LucideIcon> = {
  bed: BedDouble,
  clock: Clock,
  calendar: CalendarCheck2,
  wifi: Wifi,
  message: MessageCircle,
  parking: SquareParking,
  laundry: Shirt,
  tv: Tv,
  safe: ShieldCheck,
  star: Star,
  pool: Waves,
  gym: Dumbbell,
  restaurant: Utensils,
  coffee: Coffee,
  'map-pin': MapPin,
  phone: Phone,
  mail: Mail,
  sparkles: Sparkles,
  concierge: ConciergeBell,
  luggage: Luggage,
  car: Car,
  wind: Wind,
  bell: BellRing,
  bath: Bath,
  view: Binoculars,
  users: Users,
}

export const CONTENT_ICON_OPTIONS: Array<{ key: IconKey; label: string }> =
  (Object.keys(CONTENT_ICONS) as IconKey[]).map((key) => ({
    key,
    label: ICON_LABELS[key],
  }))

/** أيقونة قسم بالمفتاح — تسقط إلى sparkles عند مفتاح مجهول */
export function ContentIcon({ name, className }: { name: IconKey; className?: string }) {
  const Icon = CONTENT_ICONS[name] ?? Sparkles
  return <Icon className={className} />
}
