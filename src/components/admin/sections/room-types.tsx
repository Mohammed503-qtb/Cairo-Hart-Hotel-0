'use client'

// ─────────────────────────────────────────────────────────────
// ROOM TYPES — أنواع الغرف (بطاقات + إضافة/تعديل/حذف)
// ─────────────────────────────────────────────────────────────
import { useState } from 'react'
import { Plus, Pencil, Trash2, Loader2, X, Users2, Ruler, Banknote, ImageOff } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Badge } from '@/components/ui/badge'
import { Switch } from '@/components/ui/switch'
import { Skeleton } from '@/components/ui/skeleton'
import { Checkbox } from '@/components/ui/checkbox'
import {
  Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle,
} from '@/components/ui/dialog'
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription,
  AlertDialogFooter, AlertDialogHeader, AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select'
import { api } from '@/lib/api-client'
import { formatMoney } from '@/lib/format'
import type { RoomTypeAdmin } from '../types'
import { useLoader, ErrorState, useBusyAction, EmptyState, SectionHeader, Ltr, dollarsToCents, centsToDollarsInput } from '../shared'

const IMAGE_CHOICES = [
  '/images/room-single.png',
  '/images/room-double.png',
  '/images/room-deluxe.png',
  '/images/room-family.png',
  '/images/facility-lobby.png',
  '/images/facility-restaurant.png',
  '/images/facility-terrace.png',
  '/images/gallery-corridor.png',
]

interface FormState {
  name: string
  nameEn: string
  description: string
  capacityAdults: string
  capacityChildren: string
  bedConfig: string
  sizeSqm: string
  basePrice: string
  amenities: string[]
  images: string[]
  sortOrder: string
  active: boolean
}

const emptyForm: FormState = {
  name: '', nameEn: '', description: '', capacityAdults: '2', capacityChildren: '0',
  bedConfig: '', sizeSqm: '', basePrice: '', amenities: [], images: [], sortOrder: '0', active: true,
}

export default function RoomTypesSection() {
  const { data, loading, error, reload } = useLoader<{ roomTypes: RoomTypeAdmin[] }>(() => api('/api/admin/room-types'))
  const { busy, run, toast } = useBusyAction()

  const [dialogOpen, setDialogOpen] = useState(false)
  const [editing, setEditing] = useState<RoomTypeAdmin | null>(null)
  const [form, setForm] = useState<FormState>(emptyForm)
  const [amenityInput, setAmenityInput] = useState('')
  const [deleteTarget, setDeleteTarget] = useState<RoomTypeAdmin | null>(null)

  const types = data?.roomTypes ?? []

  const openCreate = () => {
    setEditing(null)
    setForm(emptyForm)
    setDialogOpen(true)
  }

  const openEdit = (t: RoomTypeAdmin) => {
    setEditing(t)
    setForm({
      name: t.name,
      nameEn: t.nameEn,
      description: t.description,
      capacityAdults: String(t.capacityAdults),
      capacityChildren: String(t.capacityChildren),
      bedConfig: t.bedConfig,
      sizeSqm: t.sizeSqm ? String(t.sizeSqm) : '',
      basePrice: centsToDollarsInput(t.basePriceCents),
      amenities: [...t.amenities],
      images: [...t.images],
      sortOrder: String(t.sortOrder),
      active: t.active,
    })
    setDialogOpen(true)
  }

  const submit = () =>
    run(async () => {
      const cents = dollarsToCents(form.basePrice)
      if (!form.name.trim()) throw new Error('اسم النوع مطلوب')
      if (cents === null || cents <= 0) throw new Error('أدخل سعرًا أساسيًا صحيحًا بالدولار')
      const body = {
        name: form.name.trim(),
        nameEn: form.nameEn,
        description: form.description,
        capacityAdults: parseInt(form.capacityAdults, 10) || 2,
        capacityChildren: parseInt(form.capacityChildren, 10) || 0,
        bedConfig: form.bedConfig,
        sizeSqm: parseInt(form.sizeSqm, 10) || 0,
        basePriceCents: cents,
        amenities: form.amenities,
        images: form.images,
        sortOrder: parseInt(form.sortOrder, 10) || 0,
        active: form.active,
      }
      if (editing) {
        await api(`/api/admin/room-types/${editing.id}`, { method: 'PATCH', body })
        toast({ title: 'تم تحديث نوع الغرفة' })
      } else {
        await api('/api/admin/room-types', { method: 'POST', body })
        toast({ title: 'تمت إضافة نوع الغرفة' })
      }
      setDialogOpen(false)
      await reload()
    })

  const doDelete = () =>
    run(async () => {
      if (!deleteTarget) return
      const res = await api<{ deactivated?: boolean; deleted?: boolean; message?: string }>(
        `/api/admin/room-types/${deleteTarget.id}`,
        { method: 'DELETE' }
      )
      if (res.deactivated) {
        toast({ title: 'تم تعطيل النوع', description: res.message })
      } else {
        toast({ title: 'تم حذف النوع', description: res.message })
      }
      setDeleteTarget(null)
      await reload()
    })

  const toggleActive = (t: RoomTypeAdmin) =>
    run(async () => {
      await api(`/api/admin/room-types/${t.id}`, { method: 'PATCH', body: { active: !t.active } })
      await reload()
    })

  if (error) {
    return <Card><CardContent><ErrorState message={error} onRetry={reload} /></CardContent></Card>
  }

  return (
    <div className="space-y-4">
      <SectionHeader
        title="أنواع الغرف"
        description={`${types.length} نوع — السعر الأساسي لكل نوع + المزايا والصور`}
        action={
          <Button onClick={openCreate} className="gap-2" size="sm">
            <Plus className="w-4 h-4" /> إضافة نوع
          </Button>
        }
      />

      {loading ? (
        <div className="grid md:grid-cols-2 xl:grid-cols-3 gap-3">
          {Array.from({ length: 4 }).map((_, i) => (
            <Card key={i}><CardContent className="p-4 space-y-3">
              <Skeleton className="h-32 w-full" />
              <Skeleton className="h-5 w-2/3" />
              <Skeleton className="h-4 w-1/2" />
            </CardContent></Card>
          ))}
        </div>
      ) : types.length === 0 ? (
        <Card><CardContent><EmptyState title="لا توجد أنواع غرف" description="أضف أول نوع غرفة ليظهر في الموقع ومحرك الحجز" /></CardContent></Card>
      ) : (
        <div className="grid md:grid-cols-2 xl:grid-cols-3 gap-3">
          {types.map((t) => (
            <Card key={t.id} className={`border-border/60 overflow-hidden ${!t.active ? 'opacity-60' : ''}`}>
              <div className="relative h-36 bg-muted">
                {t.images[0] ? (
                  <img src={t.images[0]} alt={t.name} className="w-full h-full object-cover" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-muted-foreground">
                    <ImageOff className="w-8 h-8" />
                  </div>
                )}
                <div className="absolute top-2 left-2 flex gap-1.5">
                  <Badge variant={t.active ? 'default' : 'secondary'} className={t.active ? 'bg-success text-white' : ''}>
                    {t.active ? 'نشط' : 'معطّل'}
                  </Badge>
                </div>
              </div>
              <CardContent className="p-4 space-y-2.5">
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0">
                    <h3 className="font-bold truncate">{t.name}</h3>
                    {t.nameEn && <Ltr className="text-[11px] text-muted-foreground block truncate">{t.nameEn}</Ltr>}
                  </div>
                  <div className="text-end shrink-0">
                    <p className="font-extrabold text-primary tabular-nums">{formatMoney(t.basePriceCents)}</p>
                    <p className="text-[10px] text-muted-foreground">لليلة</p>
                  </div>
                </div>

                <div className="flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted-foreground">
                  <span className="flex items-center gap-1"><Users2 className="w-3.5 h-3.5" /> {t.capacityAdults} بالغ + {t.capacityChildren} طفل</span>
                  {t.sizeSqm > 0 && <span className="flex items-center gap-1"><Ruler className="w-3.5 h-3.5" /> {t.sizeSqm} م²</span>}
                  <span className="flex items-center gap-1"><Banknote className="w-3.5 h-3.5" /> {t.roomsCount} غرفة فعلية</span>
                </div>

                {t.bedConfig && <p className="text-xs text-muted-foreground">{t.bedConfig}</p>}

                {t.amenities.length > 0 && (
                  <div className="flex flex-wrap gap-1">
                    {t.amenities.slice(0, 4).map((a) => (
                      <Badge key={a} variant="outline" className="text-[10px] font-normal">{a}</Badge>
                    ))}
                    {t.amenities.length > 4 && (
                      <Badge variant="outline" className="text-[10px] font-normal">+{t.amenities.length - 4}</Badge>
                    )}
                  </div>
                )}

                <div className="flex items-center justify-between gap-2 pt-1 border-t">
                  <div className="flex items-center gap-1.5">
                    <Switch checked={t.active} onCheckedChange={() => toggleActive(t)} disabled={busy} aria-label={`تفعيل ${t.name}`} />
                    <span className="text-xs text-muted-foreground">{t.active ? 'معروض' : 'مخفي'}</span>
                  </div>
                  <div className="flex gap-1">
                    <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => openEdit(t)} aria-label={`تعديل ${t.name}`}>
                      <Pencil className="w-4 h-4" />
                    </Button>
                    <Button variant="ghost" size="icon" className="h-8 w-8 text-destructive" onClick={() => setDeleteTarget(t)} aria-label={`حذف ${t.name}`}>
                      <Trash2 className="w-4 h-4" />
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Dialog إضافة/تعديل */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>{editing ? `تعديل: ${editing.name}` : 'إضافة نوع غرفة'}</DialogTitle>
            <DialogDescription>
              {editing ? 'عدّل بيانات النوع — التغييرات تظهر في الموقع فورًا' : 'نوع جديد سيظهر في محرك الحجز على الموقع'}
            </DialogDescription>
          </DialogHeader>

          <div className="grid sm:grid-cols-2 gap-4">
            <div className="space-y-1.5">
              <Label>الاسم (عربي) *</Label>
              <Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="غرفة اقتصادية" />
            </div>
            <div className="space-y-1.5">
              <Label>الاسم (إنجليزي)</Label>
              <Input value={form.nameEn} onChange={(e) => setForm({ ...form, nameEn: e.target.value })} dir="ltr" placeholder="Economy Room" />
            </div>
            <div className="space-y-1.5 sm:col-span-2">
              <Label>الوصف</Label>
              <Textarea value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} rows={3} />
            </div>

            <div className="space-y-1.5">
              <Label>البالغون (1-8)</Label>
              <Select value={form.capacityAdults} onValueChange={(v) => setForm({ ...form, capacityAdults: v })}>
                <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                <SelectContent>
                  {Array.from({ length: 8 }, (_, i) => i + 1).map((n) => (
                    <SelectItem key={n} value={String(n)}>{n}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label>الأطفال (0-6)</Label>
              <Select value={form.capacityChildren} onValueChange={(v) => setForm({ ...form, capacityChildren: v })}>
                <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                <SelectContent>
                  {Array.from({ length: 7 }, (_, i) => i).map((n) => (
                    <SelectItem key={n} value={String(n)}>{n}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label>تجهيز السرير</Label>
              <Input value={form.bedConfig} onChange={(e) => setForm({ ...form, bedConfig: e.target.value })} placeholder="سرير ملكي واحد" />
            </div>
            <div className="space-y-1.5">
              <Label>المساحة (م²)</Label>
              <Input type="number" min={0} max={500} value={form.sizeSqm} onChange={(e) => setForm({ ...form, sizeSqm: e.target.value })} dir="ltr" placeholder="22" />
            </div>
            <div className="space-y-1.5">
              <Label>السعر الأساسي لليلة ($) *</Label>
              <Input type="number" min={1} step="0.01" value={form.basePrice} onChange={(e) => setForm({ ...form, basePrice: e.target.value })} dir="ltr" placeholder="50" />
            </div>
            <div className="space-y-1.5">
              <Label>الترتيب</Label>
              <Input type="number" value={form.sortOrder} onChange={(e) => setForm({ ...form, sortOrder: e.target.value })} dir="ltr" />
            </div>

            {/* المزايا — tag input */}
            <div className="space-y-1.5 sm:col-span-2">
              <Label>المزايا (اكتب ثم Enter)</Label>
              <div className="flex gap-2">
                <Input
                  value={amenityInput}
                  onChange={(e) => setAmenityInput(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === 'Enter') {
                      e.preventDefault()
                      const v = amenityInput.trim()
                      if (v && !form.amenities.includes(v)) setForm({ ...form, amenities: [...form.amenities, v] })
                      setAmenityInput('')
                    }
                  }}
                  placeholder="واي فاي مجاني"
                />
                <Button
                  type="button" variant="outline" size="sm"
                  onClick={() => {
                    const v = amenityInput.trim()
                    if (v && !form.amenities.includes(v)) setForm({ ...form, amenities: [...form.amenities, v] })
                    setAmenityInput('')
                  }}
                >
                  إضافة
                </Button>
              </div>
              {form.amenities.length > 0 && (
                <div className="flex flex-wrap gap-1.5 pt-1.5">
                  {form.amenities.map((a) => (
                    <Badge key={a} variant="secondary" className="gap-1 pr-1">
                      {a}
                      <button
                        onClick={() => setForm({ ...form, amenities: form.amenities.filter((x) => x !== a) })}
                        className="rounded-full hover:bg-destructive/20 p-0.5"
                        aria-label={`حذف ${a}`}
                      >
                        <X className="w-3 h-3" />
                      </button>
                    </Badge>
                  ))}
                </div>
              )}
            </div>

            {/* الصور */}
            <div className="space-y-1.5 sm:col-span-2">
              <Label>الصور</Label>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                {IMAGE_CHOICES.map((img) => {
                  const checked = form.images.includes(img)
                  return (
                    <label
                      key={img}
                      className={`relative rounded-lg border-2 overflow-hidden cursor-pointer transition-all ${checked ? 'border-gold' : 'border-transparent hover:border-border'}`}
                    >
                      <img src={img} alt="" className="w-full h-20 object-cover" />
                      <div className="absolute top-1.5 left-1.5 bg-background/90 rounded">
                        <Checkbox
                          checked={checked}
                          onCheckedChange={(v) =>
                            setForm({ ...form, images: v ? [...form.images, img] : form.images.filter((x) => x !== img) })
                          }
                          aria-label={`صورة ${img}`}
                        />
                      </div>
                    </label>
                  )
                })}
              </div>
              {form.images.length > 0 && (
                <p className="text-xs text-muted-foreground">{form.images.length} صورة مختارة — الأولى هي الرئيسية</p>
              )}
            </div>

            <div className="flex items-center gap-2 sm:col-span-2">
              <Switch checked={form.active} onCheckedChange={(v) => setForm({ ...form, active: v })} id="rt-active" />
              <Label htmlFor="rt-active">{form.active ? 'نشط — يظهر في الموقع' : 'معطّل — مخفي من الحجز'}</Label>
            </div>
          </div>

          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setDialogOpen(false)}>إلغاء</Button>
            <Button onClick={submit} disabled={busy} className="gap-2">
              {busy && <Loader2 className="w-4 h-4 animate-spin" />}
              {editing ? 'حفظ التعديلات' : 'إضافة النوع'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* تأكيد الحذف */}
      <AlertDialog open={!!deleteTarget} onOpenChange={(v) => !v && setDeleteTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>حذف نوع «{deleteTarget?.name}»؟</AlertDialogTitle>
            <AlertDialogDescription asChild>
              <div className="space-y-2">
                {(deleteTarget?.roomsCount ?? 0) > 0 || (deleteTarget?.reservationsCount ?? 0) > 0 ? (
                  <p>
                    هذا النوع مرتبط بـ <b>{deleteTarget?.roomsCount} غرفة</b> و<b>{deleteTarget?.reservationsCount} حجز</b> —
                    سيتم <b>تعطيله</b> (إخفاؤه من الحجز) بدلًا من حذفه للحفاظ على سجلات الحجوزات.
                  </p>
                ) : (
                  <p>لا توجد ارتباطات — سيتم حذف النوع نهائيًا.</p>
                )}
              </div>
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>تراجع</AlertDialogCancel>
            <AlertDialogAction onClick={doDelete} className="bg-destructive text-white hover:bg-destructive/90">
              متابعة
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
