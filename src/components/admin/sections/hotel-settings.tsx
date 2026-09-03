'use client'

// ─────────────────────────────────────────────────────────────
// HOTEL SETTINGS — إعدادات الفندق
// ─────────────────────────────────────────────────────────────
import { useMemo, useState } from 'react'
import { Save, Loader2, Info, Hotel, Phone, SlidersHorizontal, FileText, Smartphone } from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Skeleton } from '@/components/ui/skeleton'
import { api } from '@/lib/api-client'
import type { HotelAdmin } from '../types'
import { useLoader, ErrorState, useBusyAction, SectionHeader } from '../shared'

type FormState = Record<string, string>

const NUM_LIMITS: Record<string, { min: number; max: number; label: string }> = {
  taxPercent: { min: 0, max: 100, label: 'الضريبة %' },
  weekendSurchargePercent: { min: 0, max: 100, label: 'زيادة نهاية الأسبوع %' },
  minStayNights: { min: 1, max: 30, label: 'أقل ليالٍ' },
  maxStayNights: { min: 1, max: 60, label: 'أقصى ليالٍ' },
  bookingHorizonDays: { min: 1, max: 730, label: 'أفق الحجز (يوم)' },
}

export default function HotelSettingsSection() {
  const { data, loading, error, reload } = useLoader<{ hotel: HotelAdmin }>(() => api('/api/admin/hotel'))
  const { busy, run, toast } = useBusyAction()
  const [form, setForm] = useState<FormState | null>(null)

  const hotel = data?.hotel

  // تهيئة النموذج عند أول تحميل
  const initial: FormState | null = useMemo(() => {
    if (!hotel) return null
    const f: FormState = {}
    for (const key of [
      'name', 'tagline', 'description', 'phone', 'whatsapp', 'email', 'address', 'city', 'currency',
      'checkInTime', 'checkOutTime', 'taxPercent', 'weekendSurchargePercent', 'minStayNights',
      'maxStayNights', 'bookingHorizonDays', 'cancellationPolicy', 'paymentPolicy', 'childrenPolicy',
      'petsPolicy', 'smokingPolicy', 'minAppVersion',
    ]) {
      f[key] = String(hotel[key] ?? '')
    }
    return f
  }, [hotel])

  const state = form ?? initial
  const dirty = useMemo(() => {
    if (!initial || !state) return false
    return Object.keys(initial).some((k) => initial[k] !== state[k])
  }, [initial, state])

  const set = (key: string, value: string) => {
    setForm((prev) => ({ ...(prev ?? initial ?? {}), [key]: value }))
  }

  const save = () =>
    run(
      async () => {
        if (!state) return
        // إرسال الحقول المتغيرة فقط (الأرقام م convert)
        const payload: Record<string, unknown> = {}
        const initialMap = initial ?? {}
        for (const key of Object.keys(initialMap)) {
          if (state[key] !== initialMap[key]) {
            if (key in NUM_LIMITS) {
              const n = parseInt(state[key], 10)
              if (Number.isFinite(n)) payload[key] = n
            } else {
              payload[key] = state[key]
            }
          }
        }
        const res = await api<{ changedFields: string[]; note: string }>('/api/admin/hotel', { method: 'PATCH', body: payload })
        toast({ title: 'تم حفظ الإعدادات', description: res.note })
        setForm(null)
        await reload()
      }
    )

  if (error) {
    return <Card><CardContent><ErrorState message={error} onRetry={reload} /></CardContent></Card>
  }

  return (
    <div className="space-y-4 max-w-4xl">
      <SectionHeader
        title="إعدادات الفندق"
        description="بيانات الفندق وحدود الحجز والسياسات — مصدر الحقيقة لكل القنوات"
        action={
          <Button onClick={save} disabled={!dirty || busy || !state} className="gap-2 min-w-28" size="sm">
            {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
            {dirty ? 'حفظ التغييرات' : 'حفظ'}
          </Button>
        }
      />

      <div className="rounded-lg border border-gold/40 bg-gold/10 p-3.5 flex items-start gap-2.5 text-sm text-[#8a6d1f] dark:text-gold">
        <Info className="w-4.5 h-4.5 shrink-0 mt-0.5" />
        <p className="leading-relaxed">
          التغييرات على الضريبة وزيادة نهاية الأسبوع تؤثر على <b>الحجوزات الجديدة فقط</b> — الحجوزات القديمة تحتفظ بلقطة سعرها وقت الحجز.
        </p>
      </div>

      {loading || !state ? (
        <div className="space-y-4">
          {Array.from({ length: 3 }).map((_, i) => (
            <Card key={i}><CardContent className="p-6 space-y-3">
              <Skeleton className="h-5 w-40" />
              <Skeleton className="h-10 w-full" />
              <Skeleton className="h-10 w-2/3" />
            </CardContent></Card>
          ))}
        </div>
      ) : (
        <>
          {/* معلومات أساسية */}
          <Card className="border-border/60">
            <CardHeader className="pb-3">
              <CardTitle className="text-base flex items-center gap-2"><Hotel className="w-4 h-4 text-primary" /> المعلومات الأساسية</CardTitle>
            </CardHeader>
            <CardContent className="grid md:grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <Label htmlFor="name">اسم الفندق *</Label>
                <Input id="name" value={state.name} onChange={(e) => set('name', e.target.value)} />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="currency">العملة</Label>
                <Input id="currency" value={state.currency} onChange={(e) => set('currency', e.target.value)} placeholder="USD" dir="ltr" />
              </div>
              <div className="space-y-1.5 md:col-span-2">
                <Label htmlFor="tagline">الشعار التسويقي</Label>
                <Input id="tagline" value={state.tagline} onChange={(e) => set('tagline', e.target.value)} placeholder="ضيافة راقية في قلب المدينة" />
              </div>
              <div className="space-y-1.5 md:col-span-2">
                <Label htmlFor="description">الوصف</Label>
                <Textarea id="description" value={state.description} onChange={(e) => set('description', e.target.value)} rows={4} />
              </div>
            </CardContent>
          </Card>

          {/* التواصل */}
          <Card className="border-border/60">
            <CardHeader className="pb-3">
              <CardTitle className="text-base flex items-center gap-2"><Phone className="w-4 h-4 text-primary" /> التواصل والموقع</CardTitle>
            </CardHeader>
            <CardContent className="grid md:grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <Label htmlFor="phone">الهاتف</Label>
                <Input id="phone" value={state.phone} onChange={(e) => set('phone', e.target.value)} dir="ltr" />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="whatsapp">واتساب</Label>
                <Input id="whatsapp" value={state.whatsapp} onChange={(e) => set('whatsapp', e.target.value)} dir="ltr" />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="email">البريد الإلكتروني</Label>
                <Input id="email" value={state.email} onChange={(e) => set('email', e.target.value)} dir="ltr" />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="city">المدينة</Label>
                <Input id="city" value={state.city} onChange={(e) => set('city', e.target.value)} />
              </div>
              <div className="space-y-1.5 md:col-span-2">
                <Label htmlFor="address">العنوان</Label>
                <Input id="address" value={state.address} onChange={(e) => set('address', e.target.value)} />
              </div>
            </CardContent>
          </Card>

          {/* الحدود */}
          <Card className="border-border/60">
            <CardHeader className="pb-3">
              <CardTitle className="text-base flex items-center gap-2"><SlidersHorizontal className="w-4 h-4 text-primary" /> حدود الحجز والأسعار</CardTitle>
            </CardHeader>
            <CardContent className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div className="space-y-1.5">
                <Label htmlFor="checkInTime">وقت تسجيل الوصول</Label>
                <Input id="checkInTime" type="time" value={state.checkInTime} onChange={(e) => set('checkInTime', e.target.value)} dir="ltr" />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="checkOutTime">وقت المغادرة</Label>
                <Input id="checkOutTime" type="time" value={state.checkOutTime} onChange={(e) => set('checkOutTime', e.target.value)} dir="ltr" />
              </div>
              {Object.entries(NUM_LIMITS).map(([key, cfg]) => (
                <div key={key} className="space-y-1.5">
                  <Label htmlFor={key}>
                    {cfg.label}
                    <span className="text-muted-foreground text-[10px] mr-1">({cfg.min}-{cfg.max})</span>
                  </Label>
                  <Input
                    id={key}
                    type="number"
                    value={state[key]}
                    min={cfg.min}
                    max={cfg.max}
                    onChange={(e) => set(key, e.target.value)}
                    dir="ltr"
                    className={key === 'weekendSurchargePercent' ? 'border-gold/50' : ''}
                  />
                </div>
              ))}
              <p className="col-span-2 md:col-span-4 text-xs text-muted-foreground -mt-1">
                زيادة نهاية الأسبوع تُطبق على ليالي الجمعة والسبت للحجوزات الجديدة.
              </p>
            </CardContent>
          </Card>

          {/* تطبيق الضيف */}
          <Card className="border-border/60">
            <CardHeader className="pb-3">
              <CardTitle className="text-base flex items-center gap-2"><Smartphone className="w-4 h-4 text-primary" /> تطبيق الضيف (Flutter)</CardTitle>
            </CardHeader>
            <CardContent className="space-y-2">
              <div className="space-y-1.5 max-w-xs">
                <Label htmlFor="minAppVersion">أقل إصدار مسموح للتطبيق</Label>
                <Input
                  id="minAppVersion"
                  value={state.minAppVersion}
                  onChange={(e) => set('minAppVersion', e.target.value)}
                  placeholder="مثال: 1.2.0"
                  dir="ltr"
                />
              </div>
              <p className="text-xs text-muted-foreground leading-relaxed">
                اتركه فارغًا لإلغاء الفرض. عند تعيينه: تطبيق الضيف بإصدار أقل يُحجب عند الإطلاق بشاشة «تحديث مطلوب» حتى يُحدَّث من صفحة الإصدارات. يُستخدم عند بطلان إصدار قائم (كسر عقد) — لا يؤثر على الويب إطلاقًا.
              </p>
            </CardContent>
          </Card>

          {/* السياسات */}
          <Card className="border-border/60">
            <CardHeader className="pb-3">
              <CardTitle className="text-base flex items-center gap-2"><FileText className="w-4 h-4 text-primary" /> السياسات</CardTitle>
            </CardHeader>
            <CardContent className="grid md:grid-cols-2 gap-4">
              {[
                ['cancellationPolicy', 'سياسة الإلغاء'],
                ['paymentPolicy', 'سياسة الدفع'],
                ['childrenPolicy', 'سياسة الأطفال'],
                ['petsPolicy', 'سياسة الحيوانات الأليفة'],
                ['smokingPolicy', 'سياسة التدخين'],
              ].map(([key, label]) => (
                <div key={key} className="space-y-1.5">
                  <Label htmlFor={key}>{label}</Label>
                  <Textarea id={key} value={state[key]} onChange={(e) => set(key, e.target.value)} rows={3} />
                </div>
              ))}
            </CardContent>
          </Card>

          <div className="flex justify-end pb-2">
            <Button onClick={save} disabled={!dirty || busy} className="gap-2" size="sm">
              {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
              {dirty ? 'حفظ التغييرات' : 'لا توجد تغييرات'}
            </Button>
          </div>
        </>
      )}
    </div>
  )
}
