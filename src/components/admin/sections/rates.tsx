'use client'

// ─────────────────────────────────────────────────────────────
// RATES — الأسعار الموسمية لكل نوع غرفة
// ─────────────────────────────────────────────────────────────
import { useMemo, useState } from 'react'
import { Plus, Trash2, Loader2, CalendarRange, Info } from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Skeleton } from '@/components/ui/skeleton'
import { Badge } from '@/components/ui/badge'
import {
  Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle,
} from '@/components/ui/dialog'
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription,
  AlertDialogFooter, AlertDialogHeader, AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { api } from '@/lib/api-client'
import { formatDateAr, formatMoney, todayInputValue, addDaysInput } from '@/lib/format'
import type { RateAdmin, RoomTypeAdmin } from '../types'
import { useLoader, ErrorState, useBusyAction, EmptyState, SectionHeader, Ltr, dollarsToCents, dateInputToISO, isoToDateInput } from '../shared'

export default function RatesSection() {
  const { data, loading, error, reload } = useLoader<{ rates: RateAdmin[] }>(() => api('/api/admin/rates'))
  const { data: typesData } = useLoader<{ roomTypes: RoomTypeAdmin[] }>(() => api('/api/admin/room-types'))
  const { busy, run, toast } = useBusyAction()

  const [dialogOpen, setDialogOpen] = useState(false)
  const [dialogType, setDialogType] = useState<string>('')
  const [form, setForm] = useState({ name: '', startDate: todayInputValue(), endDate: addDaysInput(todayInputValue(), 30), price: '' })
  const [deleteTarget, setDeleteTarget] = useState<RateAdmin | null>(null)

  const rates = data?.rates ?? []
  const types = typesData?.roomTypes ?? []

  // تجميع المعدلات حسب النوع
  const byType = useMemo(() => {
    const map = new Map<string, { type: RoomTypeAdmin; rates: RateAdmin[] }>()
    for (const t of types) map.set(t.id, { type: t, rates: [] })
    for (const r of rates) {
      if (!map.has(r.roomTypeId)) map.set(r.roomTypeId, { type: { ...{ id: r.roomTypeId, name: r.roomTypeName } } as RoomTypeAdmin, rates: [] })
      map.get(r.roomTypeId)!.rates.push(r)
    }
    return Array.from(map.values())
  }, [rates, types])

  const openCreate = (roomTypeId?: string) => {
    setDialogType(roomTypeId ?? types[0]?.id ?? '')
    setForm({ name: '', startDate: todayInputValue(), endDate: addDaysInput(todayInputValue(), 30), price: '' })
    setDialogOpen(true)
  }

  const create = () =>
    run(async () => {
      if (!dialogType) throw new Error('اختر نوع الغرفة')
      if (!form.name.trim()) throw new Error('اسم المعدل مطلوب')
      const cents = dollarsToCents(form.price)
      if (cents === null || cents <= 0) throw new Error('أدخل سعرًا صحيحًا بالدولار')
      const start = dateInputToISO(form.startDate)
      const end = dateInputToISO(form.endDate, true)
      if (!start || !end) throw new Error('اختر نطاق التاريخين')
      const res = await api<{ warning?: string }>('/api/admin/rates', {
        method: 'POST',
        body: { roomTypeId: dialogType, name: form.name.trim(), startDate: start, endDate: end, priceCents: cents },
      })
      if (res.warning) {
        toast({ title: 'أُنشئ المعدل مع تحذير', description: res.warning, className: 'border-warning/40' })
      } else {
        toast({ title: 'تمت إضافة المعدل' })
      }
      setDialogOpen(false)
      await reload()
    })

  const doDelete = () =>
    run(async () => {
      if (!deleteTarget) return
      const res = await api<{ message?: string }>(`/api/admin/rates/${deleteTarget.id}`, { method: 'DELETE' })
      toast({ title: res.message ?? 'تم حذف المعدل' })
      setDeleteTarget(null)
      await reload()
    })

  if (error) {
    return <Card><CardContent><ErrorState message={error} onRetry={reload} /></CardContent></Card>
  }

  return (
    <div className="space-y-4">
      <SectionHeader
        title="الأسعار الموسمية"
        description="معدلات خاصة بنطاق زمني لكل نوع غرفة"
        action={
          <Button onClick={() => openCreate()} className="gap-2" size="sm" disabled={types.length === 0}>
            <Plus className="w-4 h-4" /> إضافة معدل
          </Button>
        }
      />

      <div className="rounded-lg border border-primary/25 bg-primary/5 p-3.5 flex items-start gap-2.5 text-sm">
        <Info className="w-4.5 h-4.5 shrink-0 mt-0.5 text-primary" />
        <p className="leading-relaxed text-foreground/90">
          السعر النهائي لليلة = <b>المعدل الموسمي المطابق</b> وإلا <b>السعر الأساسي</b> للنوع، مع زيادة نهاية الأسبوع %
          (من إعدادات الفندق) على ليالي الجمعة والسبت للحجوزات الجديدة. الحجوزات القديمة محفوظة بلقطات سعرها وقت الحجز.
        </p>
      </div>

      {loading ? (
        <div className="space-y-3">
          {Array.from({ length: 3 }).map((_, i) => (
            <Card key={i}><CardContent className="p-4 space-y-2">
              <Skeleton className="h-5 w-40" />
              <Skeleton className="h-10 w-full" />
            </CardContent></Card>
          ))}
        </div>
      ) : byType.length === 0 ? (
        <Card><CardContent><EmptyState title="لا توجد أنواع غرف" /></CardContent></Card>
      ) : (
        <div className="space-y-3">
          {byType.map(({ type, rates: typeRates }) => (
            <Card key={type.id} className="border-border/60 overflow-hidden">
              <CardHeader className="pb-2 py-3">
                <div className="flex items-center justify-between gap-2">
                  <CardTitle className="text-base flex items-center gap-2">
                    <CalendarRange className="w-4 h-4 text-primary" />
                    {type.name}
                    <span className="text-xs text-muted-foreground font-normal">
                      (الأساس: {formatMoney(type.basePriceCents ?? 0)})
                    </span>
                  </CardTitle>
                  <Button variant="outline" size="sm" onClick={() => openCreate(type.id)} className="gap-1.5 shrink-0" disabled={busy}>
                    <Plus className="w-3.5 h-3.5" /> معدل
                  </Button>
                </div>
              </CardHeader>
              <CardContent className="p-0">
                {typeRates.length === 0 ? (
                  <p className="px-4 py-5 text-sm text-muted-foreground text-center">لا توجد معدلات موسمية — يُستخدم السعر الأساسي دائمًا</p>
                ) : (
                  <div className="overflow-x-auto">
                    <table className="w-full text-sm min-w-[560px]">
                      <thead>
                        <tr className="border-b text-xs text-muted-foreground bg-muted/40">
                          <th className="text-start font-medium px-4 py-2">المعدل</th>
                          <th className="text-start font-medium px-2 py-2">من</th>
                          <th className="text-start font-medium px-2 py-2">إلى</th>
                          <th className="text-start font-medium px-2 py-2">السعر/ليلة</th>
                          <th className="text-start font-medium px-4 py-2 w-14"></th>
                        </tr>
                      </thead>
                      <tbody>
                        {typeRates.map((r) => (
                          <tr key={r.id} className="border-b last:border-0 hover:bg-accent/50 transition-colors">
                            <td className="px-4 py-2.5 font-medium">{r.name}</td>
                            <td className="px-2 py-2.5 text-muted-foreground text-xs">{formatDateAr(r.startDate)}</td>
                            <td className="px-2 py-2.5 text-muted-foreground text-xs">{formatDateAr(r.endDate)}</td>
                            <td className="px-2 py-2.5 font-bold tabular-nums text-gold">{formatMoney(r.priceCents)}</td>
                            <td className="px-4 py-2.5">
                              <Button variant="ghost" size="icon" className="h-8 w-8 text-destructive" onClick={() => setDeleteTarget(r)} aria-label={`حذف ${r.name}`}>
                                <Trash2 className="w-4 h-4" />
                              </Button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                )}
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* إضافة معدل */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>إضافة معدل موسمي</DialogTitle>
            <DialogDescription>سعر خاص لنوع غرفة خلال نطاق زمني</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-1.5">
              <Label>نوع الغرفة *</Label>
              <Select value={dialogType} onValueChange={setDialogType}>
                <SelectTrigger className="w-full"><SelectValue placeholder="اختر النوع" /></SelectTrigger>
                <SelectContent>
                  {types.map((t) => (
                    <SelectItem key={t.id} value={t.id}>{t.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label>اسم المعدل *</Label>
              <Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="الموسم الصيفي" />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label>من *</Label>
                <Input type="date" value={form.startDate} onChange={(e) => setForm({ ...form, startDate: e.target.value })} dir="ltr" />
              </div>
              <div className="space-y-1.5">
                <Label>إلى *</Label>
                <Input type="date" value={form.endDate} onChange={(e) => setForm({ ...form, endDate: e.target.value })} dir="ltr" />
              </div>
            </div>
            <div className="space-y-1.5">
              <Label>السعر لليلة ($) *</Label>
              <Input type="number" min={1} step="0.01" value={form.price} onChange={(e) => setForm({ ...form, price: e.target.value })} dir="ltr" placeholder="180" />
            </div>
            <p className="text-[11px] text-muted-foreground leading-relaxed">
              عند التداخل الزمني مع معدل آخر لنفس النوع، يسود المعدل الأحدث بدايةً لكل ليلة — وسيظهر لك تحذير.
            </p>
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setDialogOpen(false)}>إلغاء</Button>
            <Button onClick={create} disabled={busy} className="gap-2">
              {busy && <Loader2 className="w-4 h-4 animate-spin" />} إضافة
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* حذف معدل */}
      <AlertDialog open={!!deleteTarget} onOpenChange={(v) => !v && setDeleteTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>حذف معدل «{deleteTarget?.name}»؟</AlertDialogTitle>
            <AlertDialogDescription asChild>
              <div>
                <p>
                  النطاق <Ltr className="text-xs">{deleteTarget ? `${isoToDateInput(deleteTarget.startDate)} → ${isoToDateInput(deleteTarget.endDate)}` : ''}</Ltr>{' '}
                  لنوع «{deleteTarget?.roomTypeName}» — الحجوزات الجديدة ستعود للسعر الأساسي.
                </p>
                {deleteTarget && (
                  <p className="mt-2 flex items-center gap-1.5">
                    <Badge variant="outline" className="text-[10px]">ملاحظة</Badge>
                    الحجوزات التي حُجزت أثناء هذا المعدل تحتفظ بلقطة سعرها.
                  </p>
                )}
              </div>
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>تراجع</AlertDialogCancel>
            <AlertDialogAction onClick={doDelete} className="bg-destructive text-white hover:bg-destructive/90">
              حذف
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
