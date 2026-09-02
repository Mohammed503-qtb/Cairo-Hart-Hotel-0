'use client'

// ─────────────────────────────────────────────────────────────
// GUESTS — الضيوف (بحث + جدول + حجوزات الضيف)
// ─────────────────────────────────────────────────────────────
import { useState } from 'react'
import { Search, Users, X } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import {
  Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle,
} from '@/components/ui/dialog'
import { api } from '@/lib/api-client'
import { formatDateAr, formatMoney } from '@/lib/format'
import type { GuestAdmin, Paginated, ReservationListItem } from '../types'
import { useLoader, ErrorState, EmptyState, SectionHeader, Ltr, TableSkeleton, ReservationStatusBadge, PaymentStatusBadge } from '../shared'

export default function GuestsSection() {
  const [q, setQ] = useState('')
  const [query, setQuery] = useState('')
  const [openGuest, setOpenGuest] = useState<GuestAdmin | null>(null)

  const { data, loading, error, reload } = useLoader<{ guests: GuestAdmin[] }>(
    () => api(`/api/admin/guests?q=${encodeURIComponent(query)}`),
    [query]
  )

  const guests = data?.guests ?? []

  const search = () => setQuery(q.trim())

  return (
    <div className="space-y-4">
      <SectionHeader title="الضيوف" description={`${guests.length} ضيف في السجل`} />

      <div className="flex flex-wrap items-center gap-2">
        <div className="relative flex-1 min-w-48 max-w-xs">
          <Search className="absolute right-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <Input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && search()}
            placeholder="اسم / هاتف / بريد…"
            className="pr-8 h-9"
          />
          {q && (
            <button
              onClick={() => { setQ(''); setQuery('') }}
              className="absolute left-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
              aria-label="مسح البحث"
            >
              <X className="w-4 h-4" />
            </button>
          )}
        </div>
        <Button variant="outline" size="sm" onClick={search} className="gap-1.5">بحث</Button>
      </div>

      <Card className="border-border/60 overflow-hidden">
        <CardContent className="p-0">
          {loading ? (
            <TableSkeleton rows={6} cols={6} />
          ) : error ? (
            <ErrorState message={error} onRetry={reload} />
          ) : guests.length === 0 ? (
            <EmptyState icon={Users} title="لا يوجد ضيوف مطابقون" />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm min-w-[760px]">
                <thead>
                  <tr className="border-b text-xs text-muted-foreground bg-muted/40">
                    <th className="text-start font-medium px-4 py-2.5">الضيف</th>
                    <th className="text-start font-medium px-2 py-2.5">الهاتف</th>
                    <th className="text-start font-medium px-2 py-2.5">البريد</th>
                    <th className="text-start font-medium px-2 py-2.5">الجنسية</th>
                    <th className="text-start font-medium px-2 py-2.5">الحجوزات</th>
                    <th className="text-start font-medium px-4 py-2.5">آخر حجز</th>
                  </tr>
                </thead>
                <tbody>
                  {guests.map((g) => (
                    <tr
                      key={g.id}
                      onClick={() => setOpenGuest(g)}
                      className="border-b last:border-0 hover:bg-accent/50 transition-colors cursor-pointer"
                    >
                      <td className="px-4 py-3 font-medium">{g.fullName}</td>
                      <td className="px-2 py-3"><Ltr className="text-xs">{g.phone}</Ltr></td>
                      <td className="px-2 py-3"><Ltr className="text-[11px] text-muted-foreground">{g.email ?? '—'}</Ltr></td>
                      <td className="px-2 py-3 text-xs text-muted-foreground">{g.nationality ?? '—'}</td>
                      <td className="px-2 py-3">
                        <Badge variant="secondary" className="tabular-nums">{g.reservationsCount}</Badge>
                      </td>
                      <td className="px-4 py-3 text-xs">
                        {g.lastReservation ? (
                          <div>
                            <Ltr className="text-[11px] font-bold text-primary">{g.lastReservation.bookingReference}</Ltr>
                            <p className="text-[10px] text-muted-foreground">{formatDateAr(g.lastReservation.checkIn)}</p>
                          </div>
                        ) : (
                          <span className="text-muted-foreground">—</span>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {openGuest && <GuestReservationsDialog guest={openGuest} onClose={() => setOpenGuest(null)} />}
    </div>
  )
}

function GuestReservationsDialog({ guest, onClose }: { guest: GuestAdmin; onClose: () => void }) {
  const { data, loading, error } = useLoader<Paginated<ReservationListItem>>(
    () => api(`/api/admin/reservations?q=${encodeURIComponent(guest.phone)}&limit=50`)
  )
  const items = (data?.items ?? []).filter((r) => r.guestName === guest.fullName || r.guestPhone === guest.phone)

  return (
    <Dialog open onOpenChange={(v) => !v && onClose()}>
      <DialogContent className="max-w-2xl max-h-[85vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{guest.fullName}</DialogTitle>
          <DialogDescription>
            <Ltr className="text-xs">{guest.phone}</Ltr>
            {guest.nationality ? ` · ${guest.nationality}` : ''} · {items.length} حجز
          </DialogDescription>
        </DialogHeader>

        {loading ? (
          <div className="space-y-2">
            {Array.from({ length: 3 }).map((_, i) => <div key={i} className="h-16 rounded-lg bg-muted animate-pulse" />)}
          </div>
        ) : error ? (
          <ErrorState message={error} />
        ) : items.length === 0 ? (
          <EmptyState title="لا توجد حجوزات لهذا الضيف" />
        ) : (
          <div className="space-y-2">
            {items.map((r) => (
              <div key={r.id} className="rounded-lg border p-3 flex flex-wrap items-center gap-x-4 gap-y-1.5">
                <div className="min-w-0">
                  <Ltr className="text-xs font-bold text-primary">{r.reference}</Ltr>
                  <p className="text-[11px] text-muted-foreground">
                    {r.roomTypeName} · {formatDateAr(r.checkIn)} ← {formatDateAr(r.checkOut)} · {r.nights} ليلة
                  </p>
                </div>
                <div className="mr-auto flex items-center gap-2 flex-wrap">
                  <span className="font-bold tabular-nums text-sm">{formatMoney(r.grandTotalCents)}</span>
                  <PaymentStatusBadge status={r.paymentStatus} />
                  <ReservationStatusBadge status={r.status} />
                </div>
              </div>
            ))}
          </div>
        )}
      </DialogContent>
    </Dialog>
  )
}
