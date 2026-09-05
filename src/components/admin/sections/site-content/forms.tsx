'use client'

// ─────────────────────────────────────────────────────────────
// SITE CONTENT FORMS — نماذج أقسام محتوى الموقع السبعة
// الأب (index.tsx) يدير حالة القسم والحفظ عبر PATCH site-content
// عدا الغرف (بطاقات أنواع الغرف → PATCH room-types) والتواصل
// (بيانات الفندق → PATCH hotel) ولهما مصادر ومصادر حفظ خاصة
// ─────────────────────────────────────────────────────────────
import { useMemo, useRef, useState } from 'react'
import {
  BedDouble, ChevronDown, ChevronUp, FileText, Hotel, ImageOff, Info, Loader2, PanelBottom,
  PanelTop, Phone, Plus, Save, Trash2, Upload, X,
} from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Badge } from '@/components/ui/badge'
import { Skeleton } from '@/components/ui/skeleton'
import { Select, SelectContent, SelectItem, SelectTrigger } from '@/components/ui/select'
import { api } from '@/lib/api-client'
import { formatMoney } from '@/lib/format'
import { useToast } from '@/hooks/use-toast'
import {
  DEFAULT_CONTENT, type AmenityItem, type FacilityCard, type GalleryImage, type IconKey,
  type NavLink, type SiteContentAll, type SiteSectionKey, type TrustItem,
} from '@/lib/site-content'
import type { HotelAdmin, RoomTypeAdmin } from '../../types'
import { useLoader, ErrorState, useBusyAction, EmptyState, dollarsToCents, centsToDollarsInput } from '../../shared'
import { apiUpload, ImageField, ImageLibraryDialog, IconSelect, ListRow, FieldRow, FormFooter } from './fields'

// ───────────── الـ props الموحدة ─────────────

export interface SectionFormProps<K extends SiteSectionKey> {
  value: SiteContentAll[K]
  onChange: (value: SiteContentAll[K]) => void
  busy: boolean
  dirty: boolean
  onSave: () => void
  onRevert: () => void
}

// ───────────── عناوين القسم (kicker/title/subtitle) ─────────────

interface HeadingsShape { kicker: string; title: string; subtitle: string }

function HeadingsFields<T extends HeadingsShape>({ value, onChange }: { value: T; onChange: (v: T) => void }) {
  return (
    <div className="grid gap-4">
      <FieldRow
        label="الكلمة الصغيرة فوق العنوان"
        value={value.kicker}
        onChange={(kicker) => onChange({ ...value, kicker })}
        placeholder="مثال: الإقامة"
        maxLength={40}
      />
      <FieldRow
        label="عنوان القسم"
        value={value.title}
        onChange={(title) => onChange({ ...value, title })}
        placeholder="عنوان كبير يظهر أعلى القسم"
        maxLength={100}
      />
      <FieldRow
        label="الوصف تحت العنوان"
        value={value.subtitle}
        onChange={(subtitle) => onChange({ ...value, subtitle })}
        placeholder="سطر وصفي قصير تحت العنوان"
        textarea
        rows={2}
        maxLength={600}
      />
    </div>
  )
}

/** مساعد ترتيب مصفوفة عام (تبديل عنصرين) */
function moved<T>(arr: T[], i: number, dir: -1 | 1): T[] {
  const j = i + dir
  if (j < 0 || j >= arr.length) return arr
  const next = [...arr]
  ;[next[i], next[j]] = [next[j], next[i]]
  return next
}

// ═════════════ 1. الترويسة ═════════════

export function HeaderForm({ value, onChange, busy, dirty, onSave, onRevert }: SectionFormProps<'header'>) {
  const patch = (p: Partial<SiteContentAll['header']>) => onChange({ ...value, ...p })

  const updateLink = (i: number, p: Partial<NavLink>) => {
    patch({ navLinks: value.navLinks.map((l, idx) => (idx === i ? { ...l, ...p } : l)) })
  }
  const moveLink = (i: number, dir: -1 | 1) => patch({ navLinks: moved(value.navLinks, i, dir) })
  const removeLink = (i: number) => patch({ navLinks: value.navLinks.filter((_, idx) => idx !== i) })
  const addLink = () => patch({ navLinks: [...value.navLinks, { href: '#', label: 'رابط جديد' }] })

  return (
    <div className="space-y-4">
      <Card className="border-border/60">
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2"><PanelTop className="w-4 h-4 text-primary" /> الهوية والأزرار</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <ImageField label="شعار الموقع" value={value.logoUrl} onChange={(logoUrl) => patch({ logoUrl })} />
          <div className="grid md:grid-cols-2 gap-4">
            <FieldRow
              label="اسم الموقع" value={value.siteName} onChange={(siteName) => patch({ siteName })}
              placeholder="فارغ = اسم الفندق" hint="يظهر بجانب الشعار — اتركه فارغًا لاستخدام اسم الفندق تلقائيًا" maxLength={60}
            />
            <FieldRow
              label="الشعار النصي" value={value.siteTagline} onChange={(siteTagline) => patch({ siteTagline })}
              placeholder="فارغ = الشعار التسويقي للفندق" hint="سطر صغير تحت الاسم — الفراغ يسقط لشعار الفندق" maxLength={90}
            />
            <FieldRow
              label="نص زر الحجز" value={value.bookButtonLabel} onChange={(bookButtonLabel) => patch({ bookButtonLabel })}
              placeholder="احجز الآن" maxLength={40}
            />
            <FieldRow
              label="نص زر إدارة الحجز" value={value.manageButtonLabel} onChange={(manageButtonLabel) => patch({ manageButtonLabel })}
              placeholder="إدارة حجزك" maxLength={40}
            />
          </div>
        </CardContent>
      </Card>

      <Card className="border-border/60">
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2">
            روابط التنقل
            <Badge variant="secondary" className="text-[10px] font-normal">{value.navLinks.length}/8</Badge>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <p className="text-xs text-muted-foreground -mt-1">ترتيب الروابط هنا هو ترتيبها في القائمة العلوية وفي روابط التذييل السريعة — يجب أن يبقى رابط واحد على الأقل.</p>
          {value.navLinks.map((link, i) => (
            <ListRow
              key={i}
              index={i}
              total={value.navLinks.length}
              onMove={moveLink}
              onRemove={removeLink}
              label={`الرابط ${i + 1} من ${value.navLinks.length}`}
              disableRemove={value.navLinks.length <= 1}
            >
              <div className="grid sm:grid-cols-2 gap-3">
                <FieldRow label="النص الظاهر" value={link.label} onChange={(v) => updateLink(i, { label: v })} maxLength={60} />
                <FieldRow
                  label="الرابط" value={link.href} onChange={(v) => updateLink(i, { href: v })}
                  dir="ltr" placeholder="#rooms أو https://…" maxLength={200}
                />
              </div>
            </ListRow>
          ))}
          <Button
            type="button" variant="outline" onClick={addLink} disabled={value.navLinks.length >= 8}
            className="gap-2 min-h-11 w-full sm:w-auto"
          >
            <Plus className="w-4 h-4" /> إضافة رابط
          </Button>
        </CardContent>
      </Card>

      <FormFooter dirty={dirty} busy={busy} onSave={onSave} onRevert={onRevert} saveLabel="حفظ الترويسة" />
    </div>
  )
}

// ═════════════ 2. الهيرو الرئيسي ═════════════

const NEW_TRUST_ITEM: TrustItem = { ...DEFAULT_CONTENT.hero.trustItems[0] }

export function HeroForm({ value, onChange, busy, dirty, onSave, onRevert }: SectionFormProps<'hero'>) {
  const patch = (p: Partial<SiteContentAll['hero']>) => onChange({ ...value, ...p })

  const updateTrust = (i: number, p: Partial<TrustItem>) => {
    patch({ trustItems: value.trustItems.map((t, idx) => (idx === i ? { ...t, ...p } : t)) })
  }
  const moveTrust = (i: number, dir: -1 | 1) => patch({ trustItems: moved(value.trustItems, i, dir) })
  const removeTrust = (i: number) => patch({ trustItems: value.trustItems.filter((_, idx) => idx !== i) })
  const addTrust = () => patch({ trustItems: [...value.trustItems, { ...NEW_TRUST_ITEM }] })

  return (
    <div className="space-y-4">
      <Card className="border-border/60">
        <CardHeader className="pb-3">
          <CardTitle className="text-base">الواجهة الرئيسية (الهيرو)</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <ImageField label="صورة الهيرو الكبيرة" value={value.image} onChange={(image) => patch({ image })} previewClassName="h-48" />
          <div className="grid md:grid-cols-2 gap-4">
            <FieldRow
              label="الشارة الصغيرة" value={value.badge} onChange={(badge) => patch({ badge })}
              placeholder="مثال: عدن — اليمن" maxLength={60}
            />
            <FieldRow
              label="العنوان الرئيسي" value={value.title} onChange={(title) => patch({ title })}
              placeholder="فارغ = اسم الفندق" hint="العنوان الضخم أعلى الصورة — الفراغ يسقط لاسم الفندق" maxLength={90}
            />
            <FieldRow
              label="نص تعريفي" value={value.tagline} onChange={(tagline) => patch({ tagline })}
              placeholder="فارغ = الشعار التسويقي للفندق" textarea rows={3} maxLength={600}
            />
            <div className="grid sm:grid-cols-2 gap-4">
              <FieldRow
                label="نص زر التوفر" value={value.checkAvailabilityLabel} onChange={(v) => patch({ checkAvailabilityLabel: v })}
                placeholder="تحقق من التوفر" maxLength={40}
              />
              <FieldRow
                label="نص زر واتساب" value={value.whatsappLabel} onChange={(v) => patch({ whatsappLabel: v })}
                placeholder="تحدث معنا واتساب" maxLength={40}
              />
            </div>
          </div>
        </CardContent>
      </Card>

      <Card className="border-border/60">
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2">
            شريط الثقة
            <Badge variant="secondary" className="text-[10px] font-normal">{value.trustItems.length}/8</Badge>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <p className="text-xs text-muted-foreground -mt-1">شريط المزايا أسفل الهيرو — العناصر ذات العنوان الفارغ تُحذف عند الحفظ.</p>
          {value.trustItems.map((item, i) => (
            <ListRow
              key={i}
              index={i}
              total={value.trustItems.length}
              onMove={moveTrust}
              onRemove={removeTrust}
              label={`ميزة ${i + 1} من ${value.trustItems.length}`}
            >
              <div className="grid gap-3">
                <div className="grid sm:grid-cols-[180px_1fr] gap-3">
                  <IconSelect value={item.icon} onValueChange={(icon) => updateTrust(i, { icon })} />
                  <FieldRow label="العنوان" value={item.title} onChange={(v) => updateTrust(i, { title: v })} maxLength={60} placeholder="مثال: خدمة 24 ساعة" />
                </div>
                <FieldRow label="الوصف" value={item.text} onChange={(v) => updateTrust(i, { text: v })} maxLength={120} placeholder="سطر قصير تحت العنوان" />
              </div>
            </ListRow>
          ))}
          <Button
            type="button" variant="outline" onClick={addTrust} disabled={value.trustItems.length >= 8}
            className="gap-2 min-h-11 w-full sm:w-auto"
          >
            <Plus className="w-4 h-4" /> إضافة ميزة ثقة
          </Button>
        </CardContent>
      </Card>

      <FormFooter dirty={dirty} busy={busy} onSave={onSave} onRevert={onRevert} saveLabel="حفظ الهيرو" />
    </div>
  )
}

// ═════════════ 3. قسم الغرف (عناوين + أنواع الغرف) ═════════════

export function RoomsForm(props: SectionFormProps<'rooms'>) {
  const { value, onChange, busy, dirty, onSave, onRevert } = props
  return (
    <div className="space-y-4">
      <Card className="border-border/60">
        <CardHeader className="pb-3">
          <CardTitle className="text-base">عناوين قسم الغرف</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <HeadingsFields value={value} onChange={onChange} />
          <FormFooter dirty={dirty} busy={busy} onSave={onSave} onRevert={onRevert} saveLabel="حفظ العناوين" />
        </CardContent>
      </Card>

      <RoomTypesEditor />
    </div>
  )
}

/** محرر بطاقات أنواع الغرف — يقرأ من /api/admin/room-types ويحفظ كل نوع على حدة */
function RoomTypesEditor() {
  const { data, loading, error, reload } = useLoader<{ roomTypes: RoomTypeAdmin[] }>(() => api('/api/admin/room-types'))
  const types = data?.roomTypes ?? []

  if (error) {
    return (
      <Card className="border-border/60">
        <CardContent className="p-6"><ErrorState message={error} onRetry={reload} /></CardContent>
      </Card>
    )
  }

  return (
    <Card className="border-border/60">
      <CardHeader className="pb-3">
        <CardTitle className="text-base flex items-center items-baseline gap-2">
          <BedDouble className="w-4 h-4 text-primary self-center" /> بطاقات الغرف — أنواع الغرف
          <Badge variant="secondary" className="text-[10px] font-normal">{types.length}</Badge>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        <p className="text-xs text-muted-foreground -mt-1">
          هذه البطاقات تظهر في قسم الغرف بالموقع بالترتيب نفسه — الأولى من كل مجموعة صور هي الرئيسية. الإضافة والحذف من قسم «أنواع الغرف».
        </p>
        {loading ? (
          <div className="space-y-3">
            {Array.from({ length: 3 }).map((_, i) => (
              <div key={i} className="rounded-lg border p-3 space-y-3">
                <div className="flex items-center gap-3">
                  <Skeleton className="w-14 h-14 rounded-lg" />
                  <div className="flex-1 space-y-2">
                    <Skeleton className="h-5 w-40" />
                    <Skeleton className="h-4 w-56" />
                  </div>
                </div>
              </div>
            ))}
          </div>
        ) : types.length === 0 ? (
          <EmptyState
            title="لا توجد أنواع غرف"
            description="أضف أنواع الغرف من قسم «أنواع الغرف» في القائمة الجانبية ثم عدّلها هنا"
            icon={BedDouble}
          />
        ) : (
          types.map((t) => <RoomTypeCard key={t.id} roomType={t} />)
        )}
      </CardContent>
    </Card>
  )
}

interface RoomTypeFormState {
  name: string
  nameEn: string
  description: string
  bedConfig: string
  capacityAdults: string
  capacityChildren: string
  sizeSqm: string
  basePrice: string
  amenities: string[]
  images: string[]
}

function formFromType(t: RoomTypeAdmin): RoomTypeFormState {
  return {
    name: t.name,
    nameEn: t.nameEn,
    description: t.description,
    bedConfig: t.bedConfig,
    capacityAdults: String(t.capacityAdults),
    capacityChildren: String(t.capacityChildren),
    sizeSqm: t.sizeSqm ? String(t.sizeSqm) : '',
    basePrice: centsToDollarsInput(t.basePriceCents),
    amenities: [...t.amenities],
    images: [...t.images],
  }
}

/** بطاقة نوع غرفة قابلة للطي — تعديل كامل + حفظ PATCH بالحقول المتغيرة فقط */
function RoomTypeCard({ roomType }: { roomType: RoomTypeAdmin }) {
  const { toast } = useToast()
  const { busy, run } = useBusyAction()
  const [baseline, setBaseline] = useState<RoomTypeAdmin>(roomType)
  const [form, setForm] = useState<RoomTypeFormState | null>(null)
  const [open, setOpen] = useState(false)
  const [amenityInput, setAmenityInput] = useState('')
  const [uploading, setUploading] = useState(false)
  const [libOpen, setLibOpen] = useState(false)
  const fileRef = useRef<HTMLInputElement>(null)

  const state = form ?? formFromType(baseline)
  const set = (p: Partial<RoomTypeFormState>) => setForm((prev) => ({ ...(prev ?? formFromType(baseline)), ...p }))

  const dirty = useMemo(
    () => form !== null && JSON.stringify(form) !== JSON.stringify(formFromType(baseline)),
    [form, baseline]
  )

  // صور النوع
  const addImages = (urls: string[]) => {
    if (urls.length === 0) return
    set({ images: [...state.images, ...urls] })
  }
  const moveImage = (i: number, dir: -1 | 1) => set({ images: moved(state.images, i, dir) })
  const removeImage = (i: number) => set({ images: state.images.filter((_, idx) => idx !== i) })

  const uploadImages = async (files: FileList | null) => {
    if (!files || files.length === 0) return
    setUploading(true)
    try {
      const urls: string[] = []
      for (const f of Array.from(files)) urls.push(await apiUpload(f))
      addImages(urls)
      toast({ title: `تم رفع ${urls.length} ${urls.length === 1 ? 'صورة' : 'صور'}`, description: 'احفظ النوع لتظهر على الموقع' })
    } catch (e) {
      toast({ title: 'تعذّر رفع الصور', description: e instanceof Error ? e.message : 'حدث خطأ غير متوقع', variant: 'destructive' })
    } finally {
      setUploading(false)
      if (fileRef.current) fileRef.current.value = ''
    }
  }

  // المزايا
  const addAmenity = (v: string) => {
    const a = v.trim()
    if (a && !state.amenities.includes(a)) set({ amenities: [...state.amenities, a] })
    setAmenityInput('')
  }

  const save = () =>
    run(async () => {
      if (!state.name.trim()) throw new Error('اسم النوع مطلوب')
      const cents = dollarsToCents(state.basePrice)
      if (cents === null || cents <= 0) throw new Error('أدخل سعرًا أساسيًا صحيحًا بالدولار')
      const adults = parseInt(state.capacityAdults, 10)
      if (!Number.isFinite(adults) || adults < 1 || adults > 8) throw new Error('عدد البالغين يجب أن يكون بين 1 و 8')
      const children = parseInt(state.capacityChildren, 10)
      if (!Number.isFinite(children) || children < 0 || children > 6) throw new Error('عدد الأطفال يجب أن يكون بين 0 و 6')
      const sizeSqm = parseInt(state.sizeSqm, 10) || 0
      if (sizeSqm < 0 || sizeSqm > 500) throw new Error('المساحة يجب أن تكون بين 0 و 500 م²')

      const payload: Record<string, unknown> = {}
      if (state.name.trim() !== baseline.name) payload.name = state.name.trim()
      if (state.nameEn !== baseline.nameEn) payload.nameEn = state.nameEn
      if (state.description !== baseline.description) payload.description = state.description
      if (state.bedConfig !== baseline.bedConfig) payload.bedConfig = state.bedConfig
      if (adults !== baseline.capacityAdults) payload.capacityAdults = adults
      if (children !== baseline.capacityChildren) payload.capacityChildren = children
      if (sizeSqm !== baseline.sizeSqm) payload.sizeSqm = sizeSqm
      if (cents !== baseline.basePriceCents) payload.basePriceCents = cents
      if (JSON.stringify(state.amenities) !== JSON.stringify(baseline.amenities)) payload.amenities = state.amenities
      if (JSON.stringify(state.images) !== JSON.stringify(baseline.images)) payload.images = state.images

      if (Object.keys(payload).length === 0) {
        toast({ title: 'لا توجد تغييرات في هذا النوع' })
        return
      }
      const res = await api<{ roomType: RoomTypeAdmin }>(`/api/admin/room-types/${baseline.id}`, { method: 'PATCH', body: payload })
      setBaseline(res.roomType)
      setForm(null)
      toast({ title: 'تم حفظ نوع الغرفة', description: 'يظهر في الموقع فورًا' })
    })

  return (
    <div className="rounded-lg border">
      <button
        type="button"
        onClick={() => setOpen(!open)}
        aria-expanded={open}
        className="w-full flex items-center gap-3 p-3 text-start hover:bg-accent/50 rounded-lg transition-colors"
      >
        {state.images[0] ? (
          <img src={state.images[0]} alt={state.name} className="w-14 h-14 rounded-lg object-cover border shrink-0" />
        ) : (
          <div className="w-14 h-14 rounded-lg border bg-muted flex items-center justify-center text-muted-foreground shrink-0">
            <ImageOff className="w-5 h-5" />
          </div>
        )}
        <div className="min-w-0 flex-1">
          <h4 className="font-bold truncate">{state.name}</h4>
          <p className="text-xs text-muted-foreground truncate">
            {roomType.roomsCount} غرفة · {formatMoney(baseline.basePriceCents)} لليلة
          </p>
        </div>
        {dirty && <Badge variant="outline" className="shrink-0 text-[10px] border-gold/50 text-gold">تغييرات غير محفوظة</Badge>}
        <ChevronDown className={`w-4.5 h-4.5 text-muted-foreground shrink-0 transition-transform ${open ? 'rotate-180' : ''}`} />
      </button>

      {open && (
        <div className="px-3 pb-3 space-y-4 border-t pt-3">
          {/* صور النوع */}
          <section className="space-y-2">
            <div className="flex items-center justify-between gap-2">
              <Label>صور النوع ({state.images.length})</Label>
              <div className="flex gap-1.5">
                <input
                  ref={fileRef}
                  type="file"
                  accept="image/png,image/jpeg,image/webp,image/gif,image/svg+xml"
                  multiple
                  hidden
                  onChange={(e) => uploadImages(e.target.files)}
                />
                <Button type="button" variant="outline" size="sm" onClick={() => fileRef.current?.click()} disabled={uploading} className="gap-1.5 min-h-11">
                  {uploading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Upload className="w-4 h-4" />} رفع صورة
                </Button>
                <Button type="button" variant="outline" size="sm" onClick={() => setLibOpen(true)} className="gap-1.5 min-h-11">
                  من المكتبة
                </Button>
              </div>
            </div>
            {state.images.length > 0 && (
              <div className="grid grid-cols-2 sm:grid-cols-4 md:grid-cols-5 gap-2">
                {state.images.map((img, i) => (
                  <div key={`${img}-${i}`} className="rounded-lg border bg-card p-1.5 space-y-1">
                    <div className="relative aspect-video rounded-md overflow-hidden border bg-muted">
                      <img src={img} alt={`${state.name} — صورة ${i + 1}`} className="w-full h-full object-cover" />
                      {i === 0 && (
                        <span className="absolute top-1 right-1 rounded bg-primary/90 text-primary-foreground text-[10px] font-bold px-1.5 py-0.5">رئيسية</span>
                      )}
                    </div>
                    <div className="flex justify-center gap-0.5">
                      <Button type="button" variant="ghost" size="icon" className="h-9 w-9" disabled={i === 0} onClick={() => moveImage(i, -1)} aria-label={`تحريك الصورة ${i + 1} لأعلى`}>
                        <ChevronUp className="w-4 h-4" />
                      </Button>
                      <Button type="button" variant="ghost" size="icon" className="h-9 w-9" disabled={i === state.images.length - 1} onClick={() => moveImage(i, 1)} aria-label={`تحريك الصورة ${i + 1} لأسفل`}>
                        <ChevronDown className="w-4 h-4" />
                      </Button>
                      <Button type="button" variant="ghost" size="icon" className="h-9 w-9 text-destructive hover:bg-destructive/10" onClick={() => removeImage(i)} aria-label={`حذف الصورة ${i + 1}`}>
                        <Trash2 className="w-4 h-4" />
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            )}
            <p className="text-[11px] text-muted-foreground">الترتيب يحدد ترتيب العرض — الصورة الأولى هي الرئيسية في بطاقة الغرفة.</p>
            <ImageLibraryDialog open={libOpen} onOpenChange={setLibOpen} onPick={addImages} multiple title={`صور ${state.name}`} />
          </section>

          {/* البيانات */}
          <section className="grid sm:grid-cols-2 gap-4">
            <FieldRow label="الاسم (عربي)" value={state.name} onChange={(name) => set({ name })} maxLength={80} />
            <FieldRow label="الاسم (إنجليزي)" value={state.nameEn} onChange={(nameEn) => set({ nameEn })} dir="ltr" maxLength={80} />
            <FieldRow label="تجهيز السرير" value={state.bedConfig} onChange={(bedConfig) => set({ bedConfig })} placeholder="سرير ملكي واحد" maxLength={80} />
            <FieldRow label="السعر الأساسي لليلة ($)" value={state.basePrice} onChange={(basePrice) => set({ basePrice })} dir="ltr" placeholder="50.00" maxLength={12} />
            <div className="space-y-1.5">
              <Label>البالغون (1-8)</Label>
              <Select value={state.capacityAdults} onValueChange={(v) => set({ capacityAdults: v })}>
                <SelectTrigger className="w-full"><span className="tabular-nums">{state.capacityAdults}</span></SelectTrigger>
                <SelectContent>
                  {Array.from({ length: 8 }, (_, i) => i + 1).map((n) => (
                    <SelectItem key={n} value={String(n)}><span className="tabular-nums">{n}</span></SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label>الأطفال (0-6)</Label>
              <Select value={state.capacityChildren} onValueChange={(v) => set({ capacityChildren: v })}>
                <SelectTrigger className="w-full"><span className="tabular-nums">{state.capacityChildren}</span></SelectTrigger>
                <SelectContent>
                  {Array.from({ length: 7 }, (_, i) => i).map((n) => (
                    <SelectItem key={n} value={String(n)}><span className="tabular-nums">{n}</span></SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <FieldRow label="المساحة (م²)" value={state.sizeSqm} onChange={(sizeSqm) => set({ sizeSqm })} dir="ltr" placeholder="22" maxLength={4} />
            <FieldRow label="الوصف" value={state.description} onChange={(description) => set({ description })} textarea rows={3} maxLength={600} />
          </section>

          {/* المزايا */}
          <section className="space-y-1.5">
            <Label>المزايا (اكتب ثم Enter)</Label>
            <div className="flex gap-2">
              <Input
                value={amenityInput}
                onChange={(e) => setAmenityInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    e.preventDefault()
                    addAmenity(amenityInput)
                  }
                }}
                placeholder="واي فاي مجاني"
                maxLength={60}
              />
              <Button type="button" variant="outline" size="sm" onClick={() => addAmenity(amenityInput)} className="min-h-11 px-4">إضافة</Button>
            </div>
            {state.amenities.length > 0 && (
              <div className="flex flex-wrap gap-1.5 pt-1.5">
                {state.amenities.map((a) => (
                  <Badge key={a} variant="secondary" className="gap-1 pr-1.5">
                    {a}
                    <button
                      type="button"
                      onClick={() => set({ amenities: state.amenities.filter((x) => x !== a) })}
                      className="rounded-full hover:bg-destructive/20 p-0.5"
                      aria-label={`حذف ميزة ${a}`}
                    >
                      <X className="w-3 h-3" />
                    </button>
                  </Badge>
                ))}
              </div>
            )}
          </section>

          <div className="flex justify-end border-t pt-3">
            <Button type="button" onClick={save} disabled={busy} className="gap-2 min-h-11 min-w-40">
              {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
              {dirty ? 'حفظ هذا النوع' : 'لا توجد تغييرات'}
            </Button>
          </div>
        </div>
      )}
    </div>
  )
}

// ═════════════ 4. المرافق ═════════════

const NEW_FACILITY_CARD: FacilityCard = {
  image: DEFAULT_CONTENT.facilities.cards[0].image,
  title: 'مرفق جديد',
  text: '',
}
const NEW_AMENITY: AmenityItem = { icon: 'sparkles', label: 'ميزة جديدة' }

export function FacilitiesForm({ value, onChange, busy, dirty, onSave, onRevert }: SectionFormProps<'facilities'>) {
  const patch = (p: Partial<SiteContentAll['facilities']>) => onChange({ ...value, ...p })

  const updateCard = (i: number, p: Partial<FacilityCard>) => {
    patch({ cards: value.cards.map((c, idx) => (idx === i ? { ...c, ...p } : c)) })
  }
  const moveCard = (i: number, dir: -1 | 1) => patch({ cards: moved(value.cards, i, dir) })
  const removeCard = (i: number) => patch({ cards: value.cards.filter((_, idx) => idx !== i) })
  const addCard = () => patch({ cards: [...value.cards, { ...NEW_FACILITY_CARD }] })

  const updateAmenity = (i: number, p: Partial<AmenityItem>) => {
    patch({ amenities: value.amenities.map((a, idx) => (idx === i ? { ...a, ...p } : a)) })
  }
  const moveAmenity = (i: number, dir: -1 | 1) => patch({ amenities: moved(value.amenities, i, dir) })
  const removeAmenity = (i: number) => patch({ amenities: value.amenities.filter((_, idx) => idx !== i) })
  const addAmenity = () => patch({ amenities: [...value.amenities, { ...NEW_AMENITY }] })

  return (
    <div className="space-y-4">
      <Card className="border-border/60">
        <CardHeader className="pb-3"><CardTitle className="text-base">عناوين قسم المرافق</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <HeadingsFields value={value} onChange={onChange} />
          <FormFooter dirty={dirty} busy={busy} onSave={onSave} onRevert={onRevert} saveLabel="حفظ العناوين والقوائم" />
        </CardContent>
      </Card>

      <Card className="border-border/60">
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2">
            بطاقات المرافق
            <Badge variant="secondary" className="text-[10px] font-normal">{value.cards.length}/8</Badge>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <p className="text-xs text-muted-foreground -mt-1">بطاقات الصور داخل قسم المرافق — البطاقات ذات العنوان الفارغ تُحذف عند الحفظ.</p>
          {value.cards.map((card, i) => (
            <ListRow
              key={i}
              index={i}
              total={value.cards.length}
              onMove={moveCard}
              onRemove={removeCard}
              label={`بطاقة ${i + 1} من ${value.cards.length}`}
            >
              <div className="grid sm:grid-cols-[190px_1fr] gap-4">
                <ImageField label="صورة البطاقة" value={card.image} onChange={(image) => updateCard(i, { image })} aspect="square" />
                <div className="space-y-3">
                  <FieldRow label="العنوان" value={card.title} onChange={(v) => updateCard(i, { title: v })} maxLength={80} placeholder="مثال: المطعم" />
                  <FieldRow label="الوصف" value={card.text} onChange={(v) => updateCard(i, { text: v })} textarea rows={3} maxLength={600} />
                </div>
              </div>
            </ListRow>
          ))}
          <Button
            type="button" variant="outline" onClick={addCard} disabled={value.cards.length >= 8}
            className="gap-2 min-h-11 w-full sm:w-auto"
          >
            <Plus className="w-4 h-4" /> إضافة بطاقة
          </Button>
        </CardContent>
      </Card>

      <Card className="border-border/60">
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2">
            شبكة المزايا
            <Badge variant="secondary" className="text-[10px] font-normal">{value.amenities.length}/12</Badge>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <p className="text-xs text-muted-foreground -mt-1">شبكة الأيقونات أسفل بطاقات المرافق — المزايا ذات النص الفارغ تُحذف عند الحفظ.</p>
          {value.amenities.map((item, i) => (
            <ListRow
              key={i}
              index={i}
              total={value.amenities.length}
              onMove={moveAmenity}
              onRemove={removeAmenity}
              label={`ميزة ${i + 1} من ${value.amenities.length}`}
            >
              <div className="grid sm:grid-cols-[180px_1fr] gap-3">
                <IconSelect value={item.icon} onValueChange={(icon) => updateAmenity(i, { icon })} />
                <FieldRow label="النص" value={item.label} onChange={(v) => updateAmenity(i, { label: v })} maxLength={40} placeholder="واي فاي مجاني" />
              </div>
            </ListRow>
          ))}
          <Button
            type="button" variant="outline" onClick={addAmenity} disabled={value.amenities.length >= 12}
            className="gap-2 min-h-11 w-full sm:w-auto"
          >
            <Plus className="w-4 h-4" /> إضافة ميزة
          </Button>
        </CardContent>
      </Card>

      <FormFooter dirty={dirty} busy={busy} onSave={onSave} onRevert={onRevert} saveLabel="حفظ قسم المرافق" />
    </div>
  )
}

// ═════════════ 5. المعرض ═════════════

const MAX_GALLERY_IMAGES = 24

export function GalleryForm({ value, onChange, busy, dirty, onSave, onRevert }: SectionFormProps<'gallery'>) {
  const { toast } = useToast()
  const fileRef = useRef<HTMLInputElement>(null)
  const [uploading, setUploading] = useState(false)
  const [libOpen, setLibOpen] = useState(false)

  const patch = (p: Partial<SiteContentAll['gallery']>) => onChange({ ...value, ...p })

  const addImages = (urls: string[]) => {
    if (urls.length === 0 || value.images.length >= MAX_GALLERY_IMAGES) return
    const room = MAX_GALLERY_IMAGES - value.images.length
    const take = urls.slice(0, room)
    if (take.length < urls.length) {
      toast({ title: 'تم تجاوز الحد الأقصى', description: `الحد ${MAX_GALLERY_IMAGES} صورة — أُضيفت المتاحة فقط`, variant: 'destructive' })
    }
    if (take.length === 0) return
    const items: GalleryImage[] = take.map((src) => ({ src, title: '' }))
    patch({ images: [...value.images, ...items] })
  }

  const moveImage = (i: number, dir: -1 | 1) => patch({ images: moved(value.images, i, dir) })
  const removeImage = (i: number) => patch({ images: value.images.filter((_, idx) => idx !== i) })
  const updateTitle = (i: number, title: string) => {
    patch({ images: value.images.map((img, idx) => (idx === i ? { ...img, title } : img)) })
  }

  const uploadFiles = async (files: FileList | null) => {
    if (!files || files.length === 0) return
    setUploading(true)
    try {
      const urls: string[] = []
      for (const f of Array.from(files)) urls.push(await apiUpload(f))
      addImages(urls)
      toast({ title: `تم رفع ${urls.length} ${urls.length === 1 ? 'صورة' : 'صور'}`, description: 'احفظ القسم لتظهر على الموقع' })
    } catch (e) {
      toast({ title: 'تعذّر رفع الصور', description: e instanceof Error ? e.message : 'حدث خطأ غير متوقع', variant: 'destructive' })
    } finally {
      setUploading(false)
      if (fileRef.current) fileRef.current.value = ''
    }
  }

  const full = value.images.length >= MAX_GALLERY_IMAGES

  return (
    <div className="space-y-4">
      <Card className="border-border/60">
        <CardHeader className="pb-3"><CardTitle className="text-base">عناوين قسم المعرض</CardTitle></CardHeader>
        <CardContent className="space-y-4">
          <HeadingsFields value={value} onChange={onChange} />
          <FormFooter dirty={dirty} busy={busy} onSave={onSave} onRevert={onRevert} saveLabel="حفظ العناوين والصور" />
        </CardContent>
      </Card>

      <Card className="border-border/60">
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2">
            صور المعرض المنتقاة
            <Badge variant="secondary" className="text-[10px] font-normal">{value.images.length}/{MAX_GALLERY_IMAGES}</Badge>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="flex flex-wrap gap-2">
            <input
              ref={fileRef}
              type="file"
              accept="image/png,image/jpeg,image/webp,image/gif,image/svg+xml"
              multiple
              hidden
              onChange={(e) => uploadFiles(e.target.files)}
            />
            <Button type="button" onClick={() => fileRef.current?.click()} disabled={uploading || full} className="gap-2 min-h-11">
              {uploading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Upload className="w-4 h-4" />}
              رفع صور
            </Button>
            <Button type="button" variant="outline" onClick={() => setLibOpen(true)} disabled={full} className="gap-2 min-h-11">
              من المكتبة
            </Button>
          </div>

          <div className="rounded-lg border border-primary/30 bg-primary/5 p-3 flex items-start gap-2.5 text-xs text-muted-foreground">
            <Info className="w-4 h-4 shrink-0 mt-0.5 text-primary" />
            <p className="leading-relaxed">صور الغرف تُعرض في المعرض تلقائيًا بعد هذه الصور — أدر صور أنواع الغرف من تبويب «الغرف».</p>
          </div>

          {value.images.length === 0 ? (
            <EmptyState title="لا توجد صور بعد" description="ارفع صورًا أو اخترها من المكتبة لتظهر في معرض الفندق" icon={ImageOff} />
          ) : (
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-2.5">
              {value.images.map((img, i) => (
                <div key={`${img.src}-${i}`} className="rounded-lg border bg-card p-2 space-y-1.5">
                  <div className="relative aspect-square rounded-md overflow-hidden border bg-muted">
                    <img src={img.src} alt={img.title || `صورة ${i + 1}`} className="w-full h-full object-cover" />
                    {i === 0 && (
                      <span className="absolute top-1.5 right-1.5 rounded bg-primary/90 text-primary-foreground text-[10px] font-bold px-1.5 py-0.5">الأولى</span>
                    )}
                  </div>
                  <Input
                    value={img.title}
                    onChange={(e) => updateTitle(i, e.target.value)}
                    placeholder="عنوان الصورة"
                    maxLength={60}
                    className="h-9 text-xs"
                    aria-label={`عنوان الصورة ${i + 1}`}
                  />
                  <div className="flex justify-center gap-0.5">
                    <Button type="button" variant="ghost" size="icon" className="h-9 w-9" disabled={i === 0} onClick={() => moveImage(i, -1)} aria-label={`تحريك الصورة ${i + 1} لأعلى`}>
                      <ChevronUp className="w-4 h-4" />
                    </Button>
                    <Button type="button" variant="ghost" size="icon" className="h-9 w-9" disabled={i === value.images.length - 1} onClick={() => moveImage(i, 1)} aria-label={`تحريك الصورة ${i + 1} لأسفل`}>
                      <ChevronDown className="w-4 h-4" />
                    </Button>
                    <Button type="button" variant="ghost" size="icon" className="h-9 w-9 text-destructive hover:bg-destructive/10" onClick={() => removeImage(i)} aria-label={`حذف الصورة ${i + 1}`}>
                      <Trash2 className="w-4 h-4" />
                    </Button>
                  </div>
                </div>
              ))}
            </div>
          )}

          <ImageLibraryDialog open={libOpen} onOpenChange={setLibOpen} onPick={addImages} multiple title="صور المعرض" />
        </CardContent>
      </Card>

      <FormFooter dirty={dirty} busy={busy} onSave={onSave} onRevert={onRevert} saveLabel="حفظ المعرض" />
    </div>
  )
}

// ═════════════ 6. الموقع والتواصل (عناوين + بيانات الفندق + السياسات) ═════════════

const HOTEL_EDITABLE_FIELDS = [
  'name', 'tagline', 'phone', 'whatsapp', 'email', 'address', 'city', 'country',
  'cancellationPolicy', 'paymentPolicy', 'childrenPolicy', 'petsPolicy', 'smokingPolicy',
] as const
type HotelField = (typeof HOTEL_EDITABLE_FIELDS)[number]

const HOTEL_FIELD_LABELS: Record<HotelField, string> = {
  name: 'اسم الفندق',
  tagline: 'الشعار التسويقي',
  phone: 'الهاتف',
  whatsapp: 'واتساب',
  email: 'البريد الإلكتروني',
  address: 'العنوان',
  city: 'المدينة',
  country: 'الدولة',
  cancellationPolicy: 'سياسة الإلغاء',
  paymentPolicy: 'سياسة الدفع',
  childrenPolicy: 'سياسة الأطفال',
  petsPolicy: 'سياسة الحيوانات الأليفة',
  smokingPolicy: 'سياسة التدخين',
}

const LTR_FIELDS: HotelField[] = ['phone', 'whatsapp', 'email']
const isLtrField = (k: HotelField) => LTR_FIELDS.includes(k)

const EMPTY_HOTEL_FORM: Record<HotelField, string> = {
  name: '', tagline: '', phone: '', whatsapp: '', email: '', address: '', city: '', country: '',
  cancellationPolicy: '', paymentPolicy: '', childrenPolicy: '', petsPolicy: '', smokingPolicy: '',
}

export function ContactForm(props: SectionFormProps<'contact'>) {
  const { value, onChange, busy, dirty, onSave, onRevert } = props

  // بيانات التواصل والسياسات — مصدر مستقل من /api/admin/hotel
  const { data, loading, error, reload } = useLoader<{ hotel: HotelAdmin }>(() => api('/api/admin/hotel'))
  const { busy: hotelBusy, run, toast } = useBusyAction()
  const [form, setForm] = useState<Record<HotelField, string> | null>(null)

  const hotel = data?.hotel ?? null

  const initial = useMemo(() => {
    if (!hotel) return null
    const f: Record<HotelField, string> = { ...EMPTY_HOTEL_FORM }
    for (const key of HOTEL_EDITABLE_FIELDS) f[key] = String(hotel[key] ?? '')
    return f
  }, [hotel])

  const state = form ?? initial

  const hotelDirty = useMemo(() => {
    if (!initial || !state) return false
    return HOTEL_EDITABLE_FIELDS.some((k) => initial[k] !== state[k])
  }, [initial, state])

  const set = (key: HotelField, v: string) => {
    setForm((prev) => {
      const base = prev ?? initial ?? EMPTY_HOTEL_FORM
      return { ...base, [key]: v }
    })
  }

  const saveHotel = () =>
    run(async () => {
      if (!state) return
      const payload: Record<string, string> = {}
      for (const key of HOTEL_EDITABLE_FIELDS) {
        if (state[key] !== (initial?.[key] ?? '')) payload[key] = state[key]
      }
      if (Object.keys(payload).length === 0) {
        // لا تغييرات — إعادة الجلب فقط للتوازن
        await reload()
        return
      }
      if (payload.name !== undefined && payload.name.trim() === '') {
        throw new Error('اسم الفندق لا يمكن أن يكون فارغًا')
      }
      const res = await api<{ changedFields: string[]; note: string }>('/api/admin/hotel', { method: 'PATCH', body: payload })
      setForm(null)
      await reload()
      toast({
        title: res.changedFields.length > 0 ? 'تم حفظ بيانات التواصل والسياسات' : 'لا توجد تغييرات',
        description: res.note,
      })
    })

  if (error) {
    return (
      <div className="space-y-4">
        <ContactHeadingsCard value={value} onChange={onChange} busy={busy} dirty={dirty} onSave={onSave} onRevert={onRevert} />
        <Card className="border-border/60">
          <CardContent className="p-6"><ErrorState message={error} onRetry={reload} /></CardContent>
        </Card>
      </div>
    )
  }

  return (
    <div className="space-y-4">
      <ContactHeadingsCard value={value} onChange={onChange} busy={busy} dirty={dirty} onSave={onSave} onRevert={onRevert} />

      <Card className="border-border/60">
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2"><Hotel className="w-4 h-4 text-primary" /> بيانات التواصل الأساسية</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {loading || !state ? (
            <div className="grid md:grid-cols-2 gap-4">
              {Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className="space-y-2">
                  <Skeleton className="h-4 w-24" />
                  <Skeleton className="h-10 w-full" />
                </div>
              ))}
            </div>
          ) : (
            <>
              <p className="text-xs text-muted-foreground -mt-1">هذه البيانات تظهر في قسم التواصل بالموقع وتُستخدم في زر واتساب وصفحة الحجز — تحفظ مستقلة عن عناوين القسم.</p>
              <div className="grid md:grid-cols-2 gap-4">
                <FieldRow label={HOTEL_FIELD_LABELS.name} value={state.name} onChange={(v) => set('name', v)} maxLength={80} />
                <FieldRow label={HOTEL_FIELD_LABELS.tagline} value={state.tagline} onChange={(v) => set('tagline', v)} maxLength={120} />
                {HOTEL_EDITABLE_FIELDS.slice(2, 8).map((key) => (
                  <FieldRow
                    key={key}
                    label={HOTEL_FIELD_LABELS[key]}
                    value={state[key]}
                    onChange={(v) => set(key, v)}
                    dir={isLtrField(key) ? 'ltr' : undefined}
                    maxLength={key === 'address' ? 200 : key === 'email' ? 120 : 60}
                  />
                ))}
              </div>
            </>
          )}
        </CardContent>
      </Card>

      <Card className="border-border/60">
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2"><FileText className="w-4 h-4 text-primary" /> السياسات</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          {loading || !state ? (
            <div className="grid md:grid-cols-2 gap-4">
              {Array.from({ length: 4 }).map((_, i) => (
                <div key={i} className="space-y-2">
                  <Skeleton className="h-4 w-28" />
                  <Skeleton className="h-24 w-full" />
                </div>
              ))}
            </div>
          ) : (
            <div className="grid md:grid-cols-2 gap-4">
              {HOTEL_EDITABLE_FIELDS.slice(8).map((key) => (
                <FieldRow
                  key={key}
                  label={HOTEL_FIELD_LABELS[key]}
                  value={state[key]}
                  onChange={(v) => set(key, v)}
                  textarea
                  rows={3}
                  maxLength={600}
                />
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      <div className="flex flex-wrap items-center justify-end gap-2 pt-1 border-t pb-1">
        <Button
          type="button" onClick={saveHotel}
          disabled={hotelBusy || !state || !hotelDirty}
          className="gap-2 min-h-11 min-w-44"
        >
          {hotelBusy ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
          {hotelDirty ? 'حفظ بيانات التواصل والسياسات' : 'لا توجد تغييرات'}
        </Button>
      </div>
    </div>
  )
}

/** بطاقة عناوين قسم التواصل — حفظ منفصل عن بيانات الفندق */
function ContactHeadingsCard({ value, onChange, busy, dirty, onSave, onRevert }: SectionFormProps<'contact'>) {
  return (
    <Card className="border-border/60">
      <CardHeader className="pb-3">
        <CardTitle className="text-base flex items-center gap-2"><Phone className="w-4 h-4 text-primary" /> عناوين قسم التواصل</CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <HeadingsFields value={value} onChange={onChange} />
        <FormFooter dirty={dirty} busy={busy} onSave={onSave} onRevert={onRevert} saveLabel="حفظ العناوين" />
      </CardContent>
    </Card>
  )
}

// ═════════════ 7. التذييل ═════════════

export function FooterForm({ value, onChange, busy, dirty, onSave, onRevert }: SectionFormProps<'footer'>) {
  const patch = (p: Partial<SiteContentAll['footer']>) => onChange({ ...value, ...p })

  return (
    <div className="space-y-4">
      <Card className="border-border/60">
        <CardHeader className="pb-3">
          <CardTitle className="text-base flex items-center gap-2"><PanelBottom className="w-4 h-4 text-primary" /> التذييل</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <FieldRow
            label="نبذة عن الفندق" value={value.description} onChange={(description) => patch({ description })}
            placeholder="فارغ = العنوان من بيانات الفندق"
            hint="فقرة تعريفية تظهر في يسار التذييل — الفراغ يسقط لعنوان الفندق الوصفي"
            textarea rows={3} maxLength={600}
          />
          <div className="grid md:grid-cols-2 gap-4">
            <FieldRow
              label="حقوق النشر" value={value.copyright} onChange={(copyright) => patch({ copyright })}
              placeholder="فندق قلب القاهرة — جميع الحقوق محفوظة" maxLength={120}
            />
            <FieldRow
              label="نص زر دخول التطبيق" value={value.loginButtonLabel} onChange={(loginButtonLabel) => patch({ loginButtonLabel })}
              placeholder="منصة إدارة الإقامة — دخول التطبيق" maxLength={60}
            />
          </div>
          <p className="text-xs text-muted-foreground">روابط التذييل السريعة تتبع روابط تنقل الترويسة تلقائيًا — عدّلها من تبويب «الترويسة».</p>
        </CardContent>
      </Card>

      <FormFooter dirty={dirty} busy={busy} onSave={onSave} onRevert={onRevert} saveLabel="حفظ التذييل" />
    </div>
  )
}
