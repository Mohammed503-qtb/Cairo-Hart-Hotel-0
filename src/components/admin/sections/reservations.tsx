'use client'

// ─────────────────────────────────────────────────────────────
// RESERVATIONS — الحجوزات (فلاتر + بحث + صفحات + تفاصيل كاملة)
// ─────────────────────────────────────────────────────────────
import { useState } from 'react'
import { Search, ClipboardList, X } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Badge } from '@/components/ui/badge'
import {
  Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle,
} from '@/components/ui/dialog'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { api } from '@/lib/api-client'
import {
  formatMoney, formatDateAr, formatDateTimeAr, RESERVATION_STATUS_LABELS, PAYMENT_STATUS_LABELS,
  PAYMENT_METHOD_LABELS, SOURCE_LABELS, STAY_STATUS_LABELS,
} from '@/lib/format'
import type { Paginated, ReservationListItem, ReservationDetail, PriceSnapshot } from '../types'
import { useLoader, ErrorState, useBusyAction, EmptyState, SectionHeader, Ltr, TableSkeleton, Pager, ReservationStatusBadge, PaymentStatusBadge } from '../shared'

export default function ReservationsSection() {
  const [status, setStatus] = useState('all')
  const [q, setQ] = useState('')
  const [query, setQuery] = useState('')
  const [page, setPage] = useState(1)
  const [openId, setOpenId] = useState<string | null>(null)

  const { data, loading, error, reload } = useLoader<Paginated<ReservationListItem>>(
    () => api(`/api/admin/reservations?status=${status === 'all' ? '' : status}&q=${encodeURIComponent(query)}&page=${page}&limit=20`),
    [status, query, page]
  )
  const { run } = useBusyAction()

  const items = data?.items ?? []

  const search = () => {
    setPage(1)
    setQuery(q.trim())
  }

  const openDetail = (id: string) => setOpenId(id)

  return (
    <div className="space-y-4">
      <SectionHeader title="الحجوزات" description={`${data?.total ?? 0} حجز — كل القنوات`} />

      {/* الفلاتر */}
      <div className="flex flex-wrap items-center gap-2">
        <Select value={status} onValueChange={(v) => { setStatus(v); setPage(1) }}>
          <SelectTrigger size="sm" className="w-40"><SelectValue placeholder="كل الحالات" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">كل الحالات</SelectItem>
            {Object.entries(RESERVATION_STATUS_LABELS).map(([v, l]) => (
              <SelectItem key={v} value={v}>{l}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <div className="relative flex-1 min-w-44 max-w-xs">
          <Search className="absolute right-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <Input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && search()}
            placeholder="مرجع / اسم الضيف / هاتف…"
            className="pr-8 h-9"
          />
          {q && (
            <button
              onClick={() => { setQ(''); setQuery(''); setPage(1) }}
              className="absolute left-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
              aria-label="مسح البحث"
            >
              <X className="w-4 h-4" />
            </button>
          )}
        </div>
        <Button variant="outline" size="sm" onClick={search} className="gap-1.5">بحث</Button>
        <Button variant="ghost" size="sm" onClick={() => run(async () => { await reload() })} className="mr-auto gap-1.5">
          تحديث
        </Button>
      </div>

      <Card className="border-border/60 overflow-hidden">
        <CardContent className="p-0">
          {loading ? (
            <TableSkeleton rows={8} cols={7} />
          ) : error ? (
            <ErrorState message={error} onRetry={reload} />
          ) : items.length === 0 ? (
            <EmptyState icon={ClipboardList} title="لا توجد حجوزات مطابقة" description="غيّر الفلاتر أو مصطلح البحث" />
          ) : (
            <>
              <div className="overflow-x-auto">
                <table className="w-full text-sm min-w-[900px]">
                  <thead>
                    <tr className="border-b text-xs text-muted-foreground bg-muted/40">
                      <th className="text-start font-medium px-4 py-2.5">المرجع</th>
                      <th className="text-start font-medium px-2 py-2.5">الضيف</th>
                      <th className="text-start font-medium px-2 py-2.5">النوع</th>
                      <th className="text-start font-medium px-2 py-2.5">المواعيد</th>
                      <th className="text-start font-medium px-2 py-2.5">الليالي</th>
                      <th className="text-start font-medium px-2 py-2.5">الإجمالي / المدفوع</th>
                      <th className="text-start font-medium px-2 py-2.5">الدفع</th>
                      <th className="text-start font-medium px-2 py-2.5">الحالة</th>
                      <th className="text-start font-medium px-4 py-2.5">المصدر</th>
                    </tr>
                  </thead>
                  <tbody>
                    {items.map((r) => (
                      <tr
                        key={r.id}
                        onClick={() => openDetail(r.id)}
                        className="border-b last:border-0 hover:bg-accent/50 transition-colors cursor-pointer"
                      >
                        <td className="px-4 py-3"><Ltr className="text-xs font-bold text-primary">{r.reference}</Ltr></td>
                        <td className="px-2 py-3">
                          <p className="font-medium">{r.guestName}</p>
                          <Ltr className="text-[10px] text-muted-foreground">{r.guestPhone}</Ltr>
                        </td>
                        <td className="px-2 py-3 text-xs text-muted-foreground">{r.roomTypeName}</td>
                        <td className="px-2 py-3 text-xs text-muted-foreground whitespace-nowrap">
                          {formatDateAr(r.checkIn)} ← {formatDateAr(r.checkOut)}
                        </td>
                        <td className="px-2 py-3 tabular-nums text-center">{r.nights}</td>
                        <td className="px-2 py-3 whitespace-nowrap">
                          <p className="font-bold tabular-nums">{formatMoney(r.grandTotalCents)}</p>
                          {r.paidCents > 0 && (
                            <p className="text-[10px] text-success tabular-nums">مدفوع: {formatMoney(r.paidCents)}</p>
                          )}
                        </td>
                        <td className="px-2 py-3"><PaymentStatusBadge status={r.paymentStatus} /></td>
                        <td className="px-2 py-3"><ReservationStatusBadge status={r.status} /></td>
                        <td className="px-4 py-3">
                          <Badge variant="outline" className="text-[10px]">{SOURCE_LABELS[r.source] ?? r.source}</Badge>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              <div className="px-4">
                <Pager page={data?.page ?? 1} pages={data?.pages ?? 1} total={data?.total} onPage={setPage} />
              </div>
            </>
          )}
        </CardContent>
      </Card>

      {/* تفاصيل الحجز */}
      {openId && <ReservationDetailDialog id={openId} onClose={() => setOpenId(null)} />}
    </div>
  )
}

function ReservationDetailDialog({ id, onClose }: { id: string; onClose: () => void }) {
  const { data, loading, error } = useLoader<{ reservation: ReservationDetail }>(
    () => api(`/api/admin/reservations/${id}`)
  )
  const r = data?.reservation

  return (
    <Dialog open={!!id} onOpenChange={(v) => !v && onClose()}>
      <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 flex-wrap">
            <Ltr className="text-lg">{r?.reference ?? '…'}</Ltr>
            {r && <ReservationStatusBadge status={r.status} />}
            {r && <PaymentStatusBadge status={r.paymentStatus} />}
          </DialogTitle>
          <DialogDescription>
            {r ? `أُنشئ ${formatDateTimeAr(r.createdAt)} — ${SOURCE_LABELS[r.source] ?? r.source}` : 'جارٍ التحميل…'}
          </DialogDescription>
        </DialogHeader>

        {loading ? (
          <div className="space-y-3 py-4">
            {Array.from({ length: 3 }).map((_, i) => <div key={i} className="h-20 rounded-lg bg-muted animate-pulse" />)}
          </div>
        ) : error ? (
          <ErrorState message={error} />
        ) : r ? (
          <div className="space-y-5">
            {/* الضيف */}
            <section className="rounded-lg border p-4">
              <h3 className="text-sm font-bold mb-2.5">بيانات الضيف</h3>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-sm">
                <div><p className="text-xs text-muted-foreground">الاسم</p><p className="font-medium">{r.guest.fullName}</p></div>
                <div><p className="text-xs text-muted-foreground">الهاتف</p><Ltr className="text-xs">{r.guest.phone}</Ltr></div>
                <div><p className="text-xs text-muted-foreground">البريد</p><Ltr className="text-xs">{r.guest.email ?? '—'}</Ltr></div>
                <div><p className="text-xs text-muted-foreground">الجنسية</p><p className="text-xs">{r.guest.nationality ?? '—'}</p></div>
                <div><p className="text-xs text-muted-foreground">النوع</p><p className="text-xs font-medium">{r.roomType.name}</p></div>
                <div><p className="text-xs text-muted-foreground">الضيوف</p><p className="text-xs">{r.adults} بالغ + {r.children} طفل</p></div>
                <div><p className="text-xs text-muted-foreground">الليالي</p><p className="text-xs tabular-nums">{r.nights} ({formatDateAr(r.checkIn)} ← {formatDateAr(r.checkOut)})</p></div>
                <div>
                  <p className="text-xs text-muted-foreground">طريقة الدفع</p>
                  <p className="text-xs">{PAYMENT_METHOD_LABELS[r.paymentMethod ?? ''] ?? '—'}</p>
                </div>
              </div>
              {r.specialRequests && (
                <p className="mt-3 rounded-md bg-accent/60 p-2.5 text-xs leading-relaxed">
                  <b>طلبات خاصة:</b> {r.specialRequests}
                </p>
              )}
            </section>

            {/* لقطة السعر */}
            <PriceSnapshotSection snapshot={r.priceSnapshot} currency={r.currency} />

            {/* المدفوعات */}
            <section className="rounded-lg border p-4">
              <div className="flex items-center justify-between mb-2.5">
                <h3 className="text-sm font-bold">المدفوعات</h3>
                <Badge variant="outline">
                  المدفوع {formatMoney(r.paidCents)} من {formatMoney(r.grandTotalCents)}
                </Badge>
              </div>
              {r.payments.length === 0 ? (
                <p className="text-sm text-muted-foreground py-2">لا توجد مدفوعات مسجلة</p>
              ) : (
                <div className="space-y-1.5">
                  {r.payments.map((p) => (
                    <div key={p.id} className="flex items-center justify-between gap-3 rounded-md bg-muted/40 px-3 py-2 text-sm">
                      <div className="min-w-0">
                        <p className="font-medium">{PAYMENT_METHOD_LABELS[p.method] ?? p.method}</p>
                        <p className="text-[11px] text-muted-foreground">
                          {formatDateTimeAr(p.createdAt)}
                          {p.recordedBy && ` · ${p.recordedBy}`}
                        </p>
                      </div>
                      <p className={`font-bold tabular-nums shrink-0 ${p.status === 'COMPLETED' ? 'text-success' : 'text-destructive'}`}>
                        {formatMoney(p.amountCents)}
                      </p>
                    </div>
                  ))}
                </div>
              )}
            </section>

            {/* الإقامة المرتبطة */}
            {r.stay && (
              <section className="rounded-lg border border-primary/30 bg-primary/5 p-4">
                <h3 className="text-sm font-bold mb-2.5">الإقامة المرتبطة</h3>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-sm">
                  <div><p className="text-xs text-muted-foreground">المرجع</p><Ltr className="text-xs font-bold">{r.stay.reference}</Ltr></div>
                  <div><p className="text-xs text-muted-foreground">الغرفة</p><p className="font-bold text-lg leading-6"><Ltr>{r.stay.roomNumber}</Ltr></p></div>
                  <div><p className="text-xs text-muted-foreground">الحالة</p><p className="text-xs">{STAY_STATUS_LABELS[r.stay.status] ?? r.stay.status}</p></div>
                  <div>
                    <p className="text-xs text-muted-foreground">المغادرة المتوقعة</p>
                    <p className="text-xs">{formatDateAr(r.stay.expectedCheckOutAt)}</p>
                  </div>
                </div>
              </section>
            )}
          </div>
        ) : null}
      </DialogContent>
    </Dialog>
  )
}

function PriceSnapshotSection({ snapshot, currency }: { snapshot: PriceSnapshot; currency: string }) {
  const nightly = Array.isArray(snapshot.nightly) ? snapshot.nightly : []
  return (
    <section className="rounded-lg border p-4">
      <div className="flex items-center justify-between mb-2.5 flex-wrap gap-2">
        <h3 className="text-sm font-bold">لقطة السعر وقت الحجز</h3>
        <p className="text-[11px] text-muted-foreground">
          {snapshot.bookedAt ? `حُجز في ${formatDateTimeAr(snapshot.bookedAt)}` : ''}
          {typeof snapshot.taxPercent === 'number' ? ` · ضريبة ${snapshot.taxPercent}%` : ''}
        </p>
      </div>
      {nightly.length === 0 ? (
        <p className="text-sm text-muted-foreground py-2">لا توجد تفاصيل ليالٍ محفوظة</p>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-sm min-w-[320px]">
            <thead>
              <tr className="border-b text-xs text-muted-foreground">
                <th className="text-start font-medium py-2">الليلة</th>
                <th className="text-start font-medium py-2">المعدل</th>
                <th className="text-start font-medium py-2">السعر</th>
              </tr>
            </thead>
            <tbody>
              {nightly.map((n, i) => (
                <tr key={`${n.date}-${i}`} className="border-b last:border-0">
                  <td className="py-2 text-xs">{formatDateAr(n.date)}</td>
                  <td className="py-2 text-xs text-muted-foreground">{n.rateName || 'السعر الأساسي'}</td>
                  <td className="py-2 font-bold tabular-nums text-sm">{formatMoney(n.priceCents, currency)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
      <div className="mt-3 grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs border-t pt-3">
        <div><p className="text-muted-foreground">المجموع الفرعي</p><p className="font-bold tabular-nums">{formatMoney(snapshot.subtotalCents ?? 0, currency)}</p></div>
        <div><p className="text-muted-foreground">الخصم</p><p className="font-bold tabular-nums">{formatMoney(snapshot.discountCents ?? 0, currency)}</p></div>
        <div>
          <p className="text-muted-foreground">الضريبة{typeof snapshot.taxPercent === 'number' ? ` (${snapshot.taxPercent}%)` : ''}</p>
          <p className="font-bold tabular-nums">{formatMoney(snapshot.taxCents ?? 0, currency)}</p>
        </div>
        <div><p className="text-muted-foreground">الإجمالي</p><p className="font-extrabold tabular-nums text-primary">{formatMoney(snapshot.grandTotalCents ?? 0, currency)}</p></div>
      </div>
      {(snapshot.cancellationPolicy || snapshot.checkInTime || snapshot.checkOutTime) && (
        <div className="mt-3 rounded-md bg-muted/40 p-2.5 text-[11px] text-muted-foreground leading-relaxed space-y-1">
          {snapshot.cancellationPolicy && <p><b>سياسة الإلغاء وقت الحجز:</b> {snapshot.cancellationPolicy}</p>}
          <p>
            {snapshot.checkInTime ? `تسجيل الوصول ${snapshot.checkInTime}` : ''}
            {snapshot.checkOutTime ? ` · المغادرة ${snapshot.checkOutTime}` : ''}
          </p>
        </div>
      )}
    </section>
  )
}
