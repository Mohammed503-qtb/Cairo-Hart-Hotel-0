'use client'

// ─────────────────────────────────────────────────────────────
// SITE CONTENT SECTION — شاشة إدارة محتوى الموقع
// شريط تبويبات (header→footer) + نموذج لكل قسم مع تتبع dirty
// وحفظ PATCH /api/admin/site-content — الأب يدير الحالة والحفظ
// ─────────────────────────────────────────────────────────────
import { useState } from 'react'
import {
  Info, Loader2, PanelBottom, PanelTop, RotateCcw, Save, Image as ImageIcon,
  BedDouble, Waves, Images, MapPin, type LucideIcon,
} from 'lucide-react'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { cn } from '@/lib/utils'
import { api } from '@/lib/api-client'
import {
  DEFAULT_CONTENT, SITE_SECTION_LABELS,
  type SiteContentAll, type SiteSectionKey,
} from '@/lib/site-content'
import { useLoader, ErrorState, useBusyAction, SectionHeader } from '../../shared'
import {
  HeaderForm, HeroForm, RoomsForm, FacilitiesForm, GalleryForm, ContactForm, FooterForm,
} from './forms'

// ترتيب الموقع الحقيقي: الترويسة → التذييل
const TABS: Array<{ key: SiteSectionKey; icon: LucideIcon }> = [
  { key: 'header', icon: PanelTop },
  { key: 'hero', icon: ImageIcon },
  { key: 'rooms', icon: BedDouble },
  { key: 'facilities', icon: Waves },
  { key: 'gallery', icon: Images },
  { key: 'contact', icon: MapPin },
  { key: 'footer', icon: PanelBottom },
]

const SECTION_DESCRIPTIONS: Record<SiteSectionKey, string> = {
  header: 'الشعار واسم الموقع وروابط التنقل وأزرار الحجز والدخول',
  hero: 'الصورة الكبيرة والعنوان وشريط الثقة وأزرار الحجز',
  rooms: 'عناوين القسم + تعديل بطاقات أنواع الغرف وصورها ومزاياها',
  facilities: 'عناوين القسم وبطاقات المرافق وشبكة المزايا',
  gallery: 'عناوين القسم وصور المعرض المنتقاة بالترتيب',
  contact: 'عناوين القسم + بيانات التواصل الأساسية والسياسات',
  footer: 'النبذة وحقوق النشر وزر دخول التطبيق',
}

/** مقارنة عميقة مستقلة عن ترتيب المفاتيح (لتتبع dirty بأمان) */
function stableJson(v: unknown): string {
  if (v === null || typeof v !== 'object') return JSON.stringify(v) ?? 'null'
  if (Array.isArray(v)) return `[${v.map(stableJson).join(',')}]`
  const obj = v as Record<string, unknown>
  const keys = Object.keys(obj).sort()
  return `{${keys.map((k) => `${JSON.stringify(k)}:${stableJson(obj[k])}`).join(',')}}`
}

export default function SiteContentSection() {
  const { data, loading, error, reload, setData } = useLoader<{ content: SiteContentAll }>(
    () => api('/api/admin/site-content')
  )
  const { busy, run, toast } = useBusyAction()

  const [activeTab, setActiveTab] = useState<SiteSectionKey>('header')
  // مسودات الأقسام المتغيرة — القيم غير الموجودة تسقط لمحتوى الخادم
  const [edits, setEdits] = useState<Partial<SiteContentAll>>({})

  const content = data?.content ?? null

  const activeValue = <K extends SiteSectionKey>(key: K): SiteContentAll[K] =>
    edits[key] ?? content?.[key] ?? DEFAULT_CONTENT[key]

  const setEdit = <K extends SiteSectionKey>(key: K, value: SiteContentAll[K]) => {
    setEdits((prev) => ({ ...prev, [key]: value }) as Partial<SiteContentAll>)
  }

  const isDirty = (key: SiteSectionKey): boolean => {
    if (!content) return false
    return stableJson(edits[key] ?? content[key]) !== stableJson(content[key])
  }

  const saveSection = (key: SiteSectionKey) =>
    run(async () => {
      if (!content) return
      const draft = edits[key] ?? content[key]
      const res = await api<{ content: SiteContentAll; changedFields: string[]; note: string }>(
        '/api/admin/site-content',
        { method: 'PATCH', body: { section: key, data: draft } }
      )
      toast({
        title: res.changedFields.length > 0 ? `تم حفظ ${SITE_SECTION_LABELS[key]}` : 'لا توجد تغييرات',
        description: res.note,
      })
      // تحديث المحتوى من الاستجابة وإسقاط المسودة
      setData({ content: res.content })
      setEdits((prev) => {
        const next = { ...prev }
        delete next[key]
        return next
      })
    })

  const revertSection = (key: SiteSectionKey) => {
    setEdits((prev) => {
      const next = { ...prev }
      delete next[key]
      return next
    })
  }

  if (error) {
    return (
      <Card className="border-border/60">
        <CardContent className="p-6"><ErrorState message={error} onRetry={reload} /></CardContent>
      </Card>
    )
  }

  const activeDirty = isDirty(activeTab)
  const isHeadingsTab = activeTab === 'rooms' || activeTab === 'contact'
  const saveLabel = isHeadingsTab ? 'حفظ العناوين' : 'حفظ التغييرات'

  const renderForm = () => {
    switch (activeTab) {
      case 'header':
        return (
          <HeaderForm
            value={activeValue('header')}
            onChange={(v) => setEdit('header', v)}
            busy={busy} dirty={activeDirty}
            onSave={() => saveSection('header')} onRevert={() => revertSection('header')}
          />
        )
      case 'hero':
        return (
          <HeroForm
            value={activeValue('hero')}
            onChange={(v) => setEdit('hero', v)}
            busy={busy} dirty={activeDirty}
            onSave={() => saveSection('hero')} onRevert={() => revertSection('hero')}
          />
        )
      case 'rooms':
        return (
          <RoomsForm
            value={activeValue('rooms')}
            onChange={(v) => setEdit('rooms', v)}
            busy={busy} dirty={activeDirty}
            onSave={() => saveSection('rooms')} onRevert={() => revertSection('rooms')}
          />
        )
      case 'facilities':
        return (
          <FacilitiesForm
            value={activeValue('facilities')}
            onChange={(v) => setEdit('facilities', v)}
            busy={busy} dirty={activeDirty}
            onSave={() => saveSection('facilities')} onRevert={() => revertSection('facilities')}
          />
        )
      case 'gallery':
        return (
          <GalleryForm
            value={activeValue('gallery')}
            onChange={(v) => setEdit('gallery', v)}
            busy={busy} dirty={activeDirty}
            onSave={() => saveSection('gallery')} onRevert={() => revertSection('gallery')}
          />
        )
      case 'contact':
        return (
          <ContactForm
            value={activeValue('contact')}
            onChange={(v) => setEdit('contact', v)}
            busy={busy} dirty={activeDirty}
            onSave={() => saveSection('contact')} onRevert={() => revertSection('contact')}
          />
        )
      case 'footer':
        return (
          <FooterForm
            value={activeValue('footer')}
            onChange={(v) => setEdit('footer', v)}
            busy={busy} dirty={activeDirty}
            onSave={() => saveSection('footer')} onRevert={() => revertSection('footer')}
          />
        )
    }
  }

  return (
    <div className="space-y-4 max-w-5xl">
      <SectionHeader
        title="محتوى الموقع"
        description={SECTION_DESCRIPTIONS[activeTab]}
        action={
          <div className="flex items-center gap-2">
            <Button
              type="button" variant="outline" size="sm"
              onClick={() => revertSection(activeTab)} disabled={!activeDirty || busy}
              className="gap-1.5 min-h-11"
            >
              <RotateCcw className="w-4 h-4" /> تراجع
            </Button>
            <Button
              type="button" size="sm"
              onClick={() => saveSection(activeTab)} disabled={!activeDirty || busy}
              className="gap-2 min-h-11 min-w-32"
            >
              {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
              {activeDirty ? saveLabel : 'لا توجد تغييرات'}
            </Button>
          </div>
        }
      />

      {/* شريط المعلومات */}
      <div className="rounded-lg border border-gold/40 bg-gold/10 p-3.5 flex items-start gap-2.5 text-sm text-[#8a6d1f] dark:text-gold">
        <Info className="w-4.5 h-4.5 shrink-0 mt-0.5" />
        <p className="leading-relaxed">
          كل تغيير يُحفظ هنا يظهر على موقع الفندق فورًا — القيم الفارغة تُسقط تلقائيًا لقيم الفندق الأساسية.
        </p>
      </div>

      {/* شريط التبويبات بترتيب الموقع */}
      <div className="flex gap-1.5 overflow-x-auto pb-1 -mx-1 px-1" role="tablist" aria-label="أقسام محتوى الموقع">
        {TABS.map(({ key, icon: Icon }) => {
          const active = activeTab === key
          const dirty = isDirty(key)
          return (
            <button
              key={key}
              role="tab"
              aria-selected={active}
              onClick={() => setActiveTab(key)}
              className={cn(
                'shrink-0 inline-flex items-center gap-2 rounded-full border px-4 min-h-11 text-sm font-medium transition-colors',
                active
                  ? 'bg-primary text-primary-foreground border-primary shadow-sm'
                  : 'bg-card text-muted-foreground hover:bg-accent hover:text-accent-foreground'
              )}
            >
              <Icon className="w-4 h-4 shrink-0" />
              {SITE_SECTION_LABELS[key]}
              {dirty && <span className="w-1.5 h-1.5 rounded-full bg-gold shrink-0" aria-label="تغييرات غير محفوظة" />}
            </button>
          )
        })}
      </div>

      {loading || !content ? (
        <div className="space-y-4">
          {Array.from({ length: 3 }).map((_, i) => (
            <Card key={i} className="border-border/60">
              <CardContent className="p-6 space-y-3">
                <Skeleton className="h-5 w-40" />
                <Skeleton className="h-36 w-full" />
                <Skeleton className="h-10 w-full" />
                <Skeleton className="h-10 w-2/3" />
              </CardContent>
            </Card>
          ))}
        </div>
      ) : (
        renderForm()
      )}
    </div>
  )
}
