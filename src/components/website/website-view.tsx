'use client'

// ─────────────────────────────────────────────────────────────
// WEBSITE VIEW — موقع فندق قلب القاهرة (SPA الوضع الافتراضي)
// الهيكل: هيدر ثابت + هيرو/بحث + ثقة + غرف + مرافق + معرض
//         + تواصل + تذييل لاصق + نافذتا الحجز وإدارة الحجز
// ─────────────────────────────────────────────────────────────
import { useCallback, useEffect, useState } from 'react'
import { AlertTriangle, RefreshCw } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { api, ApiError } from '@/lib/api-client'
import type { HotelPublic, RoomTypePublic } from '@/types'
import { SiteHeader } from './site-header'
import { HeroSection } from './hero-section'
import { RoomsSection } from './rooms-section'
import { FacilitiesSection, GallerySection } from './facilities-gallery'
import { ContactSection, SiteFooter } from './contact-footer'
import { BookingDialog } from './booking-dialog'
import { ManageBookingDialog } from './manage-booking-dialog'
import { PrintPreviewDialog } from './print-confirmation'
import { defaultSearch } from './search-widget'
import { type SearchParams, type PrintData } from './helpers'

export default function WebsiteView() {
  // ── بيانات الفندق ──
  const [hotel, setHotel] = useState<HotelPublic | null>(null)
  const [roomTypes, setRoomTypes] = useState<RoomTypePublic[]>([])
  const [dataLoading, setDataLoading] = useState(true)
  const [dataError, setDataError] = useState<string | null>(null)

  // ── حالة البحث (ودجت الهيرو) ──
  const [search, setSearch] = useState<SearchParams>(defaultSearch)
  const [searchError, setSearchError] = useState<string | null>(null)

  // ── الحوارات ──
  const [bookingOpen, setBookingOpen] = useState(false)
  const [bookingPreset, setBookingPreset] = useState<{ search: SearchParams; roomTypeId?: string }>({
    search: defaultSearch(),
  })
  const [manageOpen, setManageOpen] = useState(false)
  const [managePresetRef, setManagePresetRef] = useState<string | undefined>(undefined)
  const [printData, setPrintData] = useState<PrintData | null>(null)
  const [printOpen, setPrintOpen] = useState(false)

  // ── جلب البيانات عند التحميل ──
  useEffect(() => {
    let cancelled = false
    const load = async () => {
      setDataLoading(true)
      setDataError(null)
      try {
        const [h, rt] = await Promise.all([
          api<{ hotel: HotelPublic }>('/api/public/hotel'),
          api<{ roomTypes: RoomTypePublic[] }>('/api/public/room-types'),
        ])
        if (cancelled) return
        setHotel(h.hotel)
        setRoomTypes(rt.roomTypes)
      } catch (e) {
        if (cancelled) return
        setDataError(e instanceof ApiError ? e.message : 'تعذر تحميل بيانات الفندق')
      } finally {
        if (!cancelled) setDataLoading(false)
      }
    }
    void load()
    return () => {
      cancelled = true
    }
  }, [])

  // ── فتح الحجز ──
  const openBooking = useCallback((s?: SearchParams, roomTypeId?: string) => {
    setBookingPreset({ search: s ?? search, roomTypeId })
    setBookingOpen(true)
  }, [search])

  // بحث الودجت → فتح نافذة الحجز على خطوة النتائج مع بحث تلقائي
  const handleWidgetSearch = useCallback(() => {
    if (search.checkOut <= search.checkIn) {
      setSearchError('تاريخ المغادرة يجب أن يكون بعد تاريخ الوصول')
      return
    }
    setSearchError(null)
    setBookingPreset({ search })
    setBookingOpen(true)
  }, [search])

  // زر «احجز الآن» من بطاقة غرفة → تحديد النوع مسبقًا
  const handleBookRoom = useCallback(
    (roomTypeId: string) => {
      setBookingPreset({ search, roomTypeId })
      setBookingOpen(true)
    },
    [search]
  )

  // إدارة الحجز (مع مرجع اختياري معبأ)
  const openManage = useCallback((reference?: string) => {
    setManagePresetRef(reference)
    setManageOpen(true)
  }, [])

  // من نافذة التأكيد: أغلق الحجز وافتح الإدارة بالمرجع
  const handleManageFromBooking = useCallback(
    (reference: string) => {
      setBookingOpen(false)
      setManagePresetRef(reference)
      setManageOpen(true)
    },
    []
  )

  return (
    <div className="flex min-h-screen flex-col bg-background">
      <SiteHeader onBook={() => openBooking()} onManage={() => openManage()} />

      <main className="flex-1">
        {dataError ? (
          <div className="flex flex-col items-center gap-3 p-10 text-center">
            <AlertTriangle className="size-10 text-warning" />
            <p className="text-sm font-semibold text-foreground">{dataError}</p>
            <Button variant="outline" onClick={() => window.location.reload()}>
              <RefreshCw className="size-4" />
              إعادة التحميل
            </Button>
          </div>
        ) : (
          <>
            <HeroSection
              hotel={hotel}
              loading={dataLoading}
              search={search}
              onSearchChange={(v) => {
                setSearch(v)
                if (v.checkOut > v.checkIn) setSearchError(null)
              }}
              onSearch={handleWidgetSearch}
              searchError={searchError}
            />

            <RoomsSection
              hotel={hotel}
              roomTypes={roomTypes}
              loading={dataLoading}
              onBook={handleBookRoom}
            />

            <FacilitiesSection />

            <GallerySection roomTypes={roomTypes} loading={dataLoading} />

            <ContactSection hotel={hotel} />
          </>
        )}
      </main>

      <SiteFooter hotel={hotel} loading={dataLoading} onManage={() => openManage()} />

      {/* الحوارات */}
      <BookingDialog
        open={bookingOpen}
        onOpenChange={setBookingOpen}
        hotel={hotel}
        initialSearch={bookingPreset.search}
        presetRoomTypeId={bookingPreset.roomTypeId}
        onManageBooking={handleManageFromBooking}
        onPrint={(data) => {
          setPrintData(data)
          setPrintOpen(true)
        }}
      />

      <ManageBookingDialog
        open={manageOpen}
        onOpenChange={setManageOpen}
        hotel={hotel}
        initialReference={managePresetRef}
        onPrint={(data) => {
          setPrintData(data)
          setPrintOpen(true)
        }}
      />

      <PrintPreviewDialog
        open={printOpen}
        onOpenChange={setPrintOpen}
        hotel={hotel}
        data={printData}
      />
    </div>
  )
}
