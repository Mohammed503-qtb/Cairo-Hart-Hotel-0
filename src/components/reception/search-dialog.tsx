'use client'

// ─────────────────────────────────────────────────────────────
// SEARCH DIALOG — بحث عام فوري (debounce) بالمرجع/الاسم/الهاتف/الغرفة
// ─────────────────────────────────────────────────────────────

import { useEffect, useRef, useState } from 'react'
import { api } from '@/lib/api-client'
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '@/components/ui/dialog'
import { Input } from '@/components/ui/input'
import { Skeleton } from '@/components/ui/skeleton'
import { Badge } from '@/components/ui/badge'
import { Search, CalendarSearch, UserSearch, Loader2 } from 'lucide-react'
import type { SearchResults } from './types'
import { RefCode, ReservationStatusBadge, PaymentStatusBadge, EmptyState } from './bits'
import { formatDateAr } from '@/lib/format'

export default function SearchDialog({
  open,
  onClose,
  onSelectStay,
  onSelectReservation,
}: {
  open: boolean
  onClose: () => void
  onSelectStay: (stayId: string, tab?: 'bill' | 'guest' | 'messages') => void
  onSelectReservation: (r: SearchResults['reservations'][number]) => void
}) {
  const [q, setQ] = useState('')
  const [results, setResults] = useState<SearchResults | null>(null)
  const [loading, setLoading] = useState(false)
  const inputRef = useRef<HTMLInputElement>(null)
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null)

  useEffect(() => {
    if (open) {
      setTimeout(() => inputRef.current?.focus(), 100)
    } else {
      setQ('')
      setResults(null)
    }
  }, [open])

  useEffect(() => {
    if (timerRef.current) clearTimeout(timerRef.current)
    const query = q.trim()
    if (query.length < 2) {
      setResults(null)
      setLoading(false)
      return
    }
    setLoading(true)
    timerRef.current = setTimeout(async () => {
      try {
        const res = await api<SearchResults>(`/api/reception/search?q=${encodeURIComponent(query)}`)
        setResults(res)
      } catch {
        setResults({ reservations: [], stays: [] })
      } finally {
        setLoading(false)
      }
    }, 350)
    return () => {
      if (timerRef.current) clearTimeout(timerRef.current)
    }
  }, [q])

  if (!open) return null

  return (
    <Dialog open onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="max-w-xl max-h-[80vh] overflow-y-auto" dir="rtl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Search className="w-5 h-5 text-primary" /> بحث عام
          </DialogTitle>
          <DialogDescription>بالمرجع، اسم الضيف، الهاتف، أو رقم الغرفة</DialogDescription>
        </DialogHeader>

        <div className="relative">
          <Input
            ref={inputRef}
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="HTL-2026-000421 / خالد / 201 / 967…"
            className="h-12 text-base font-bold pe-10"
            autoComplete="off"
          />
          {loading ? (
            <Loader2 className="w-5 h-5 animate-spin text-muted-foreground absolute end-3 top-3.5" />
          ) : null}
        </div>

        {q.trim().length < 2 ? (
          <p className="text-center text-sm text-muted-foreground py-4">اكتب حرفين على الأقل للبحث…</p>
        ) : loading && !results ? (
          <div className="space-y-2 py-2">
            <Skeleton className="h-14 rounded-lg" />
            <Skeleton className="h-14 rounded-lg" />
          </div>
        ) : results ? (
          <div className="space-y-4">
            {results.reservations.length === 0 && results.stays.length === 0 ? (
              <EmptyState title="لا نتائج مطابقة" icon={<Search className="w-7 h-7" />} subtitle={`بحث عن «${q.trim()}»`} />
            ) : null}

            {results.reservations.length > 0 ? (
              <section aria-label="نتائج الحجوزات">
                <p className="text-xs font-bold text-muted-foreground mb-1.5 flex items-center gap-1.5">
                  <CalendarSearch className="w-4 h-4" /> الحجوزات ({results.reservations.length})
                </p>
                <div className="space-y-1.5">
                  {results.reservations.map((r) => (
                    <button
                      key={r.id}
                      onClick={() => onSelectReservation(r)}
                      className="w-full text-start rounded-lg border bg-card p-2.5 hover:border-primary/40 transition-colors"
                    >
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="font-bold text-sm">{r.guestName}</span>
                        <RefCode>{r.bookingReference}</RefCode>
                        <ReservationStatusBadge status={r.status} />
                        <PaymentStatusBadge status={r.paymentStatus} />
                      </div>
                      <p className="text-[11px] text-muted-foreground mt-0.5">
                        {r.roomTypeName} · {formatDateAr(r.checkIn)} ← {formatDateAr(r.checkOut)} ·{' '}
                        <span dir="ltr" className="font-mono">{r.guestPhone}</span>
                      </p>
                    </button>
                  ))}
                </div>
              </section>
            ) : null}

            {results.stays.length > 0 ? (
              <section aria-label="نتائج الإقامات">
                <p className="text-xs font-bold text-muted-foreground mb-1.5 flex items-center gap-1.5">
                  <UserSearch className="w-4 h-4" /> الإقامات النشطة ({results.stays.length})
                </p>
                <div className="space-y-1.5">
                  {results.stays.map((s) => (
                    <button
                      key={s.id}
                      onClick={() => onSelectStay(s.id)}
                      className="w-full text-start rounded-lg border bg-card p-2.5 hover:border-primary/40 transition-colors"
                    >
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="font-bold text-sm">{s.guestName}</span>
                        <Badge variant="outline" className="font-mono">غرفة {s.roomNumber}</Badge>
                        <RefCode>{s.reference}</RefCode>
                      </div>
                      <p className="text-[11px] text-muted-foreground mt-0.5">
                        {s.roomTypeName} · خروج {formatDateAr(s.expectedCheckOutAt)} ·{' '}
                        <span dir="ltr" className="font-mono">{s.guestPhone}</span>
                      </p>
                    </button>
                  ))}
                </div>
              </section>
            ) : null}
          </div>
        ) : null}
      </DialogContent>
    </Dialog>
  )
}
