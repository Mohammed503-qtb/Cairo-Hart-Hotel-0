'use client'

// ─────────────────────────────────────────────────────────────
// SITE CONTENT FIELDS — حقول مشتركة لنماذج إدارة محتوى الموقع
// apiUpload + ImageField (رفع/مكتبة/رابط) + IconSelect + ListRow
// + FieldRow + FormFooter + حوار مكتبة الصور
// ─────────────────────────────────────────────────────────────
import { useEffect, useId, useRef, useState } from 'react'
import { Check, ChevronDown, ChevronUp, ImageOff, Link2, Loader2, RotateCcw, Save, Trash2, Upload, Images as ImagesIcon } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Skeleton } from '@/components/ui/skeleton'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { Select, SelectContent, SelectItem, SelectTrigger } from '@/components/ui/select'
import { api } from '@/lib/api-client'
import { useAppStore } from '@/lib/store'
import { useToast } from '@/hooks/use-toast'
import { cn } from '@/lib/utils'
import { IMAGE_LIBRARY, ICON_LABELS, type IconKey } from '@/lib/site-content'
import { CONTENT_ICON_OPTIONS, ContentIcon } from '@/components/website/content-icons'

// ───────────── رفع صورة (multipart — لا يمر عبر api() JSON) ─────────────

/** رفع ملف صورة إلى /api/admin/upload — يرجع رابط الصورة أو يرمي Error برسالة عربية */
export async function apiUpload(file: File): Promise<string> {
  const token = useAppStore.getState().session?.token
  const fd = new FormData()
  fd.append('file', file)

  let res: Response
  try {
    res = await fetch('/api/admin/upload', {
      method: 'POST',
      headers: token ? { authorization: `Bearer ${token}` } : undefined,
      body: fd,
    })
  } catch {
    throw new Error('تعذر الاتصال بالخادم — تحقق من اتصالك وأعد المحاولة')
  }

  let json: { ok?: boolean; url?: unknown; error?: unknown } = {}
  try {
    json = (await res.json()) as typeof json
  } catch {
    json = {}
  }
  if (!res.ok || json.ok === false || typeof json.url !== 'string' || json.url === '') {
    const message = typeof json.error === 'string' && json.error !== '' ? json.error : 'تعذّر رفع الصورة'
    throw new Error(message)
  }
  return json.url
}

// ───────────── FieldRow — صف label + Input/Textarea ─────────────

export function FieldRow({
  label,
  value,
  onChange,
  placeholder,
  maxLength,
  textarea = false,
  rows = 3,
  dir,
  hint,
  disabled = false,
}: {
  label: string
  value: string
  onChange: (v: string) => void
  placeholder?: string
  maxLength?: number
  textarea?: boolean
  rows?: number
  dir?: 'ltr' | 'rtl'
  hint?: string
  disabled?: boolean
}) {
  const id = useId()
  return (
    <div className="space-y-1.5 min-w-0">
      <Label htmlFor={id}>{label}</Label>
      {textarea ? (
        <Textarea
          id={id}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          maxLength={maxLength}
          rows={rows}
          dir={dir}
          disabled={disabled}
          className="leading-relaxed"
        />
      ) : (
        <Input
          id={id}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder={placeholder}
          maxLength={maxLength}
          dir={dir}
          disabled={disabled}
        />
      )}
      {hint && <p className="text-[11px] text-muted-foreground leading-relaxed">{hint}</p>}
    </div>
  )
}

// ───────────── ListRow — صف قائمة قابل للترتيب والحذف ─────────────

export function ListRow({
  index,
  total,
  onMove,
  onRemove,
  label,
  disableRemove = false,
  children,
}: {
  index: number
  total: number
  onMove: (i: number, dir: -1 | 1) => void
  onRemove: (i: number) => void
  label?: string
  disableRemove?: boolean
  children: React.ReactNode
}) {
  return (
    <div className="rounded-lg border bg-card p-3 space-y-3">
      <div className="flex items-center justify-between gap-2">
        <span className="text-xs font-semibold text-muted-foreground">{label ?? `عنصر ${index + 1} من ${total}`}</span>
        <div className="flex items-center gap-0.5">
          <Button
            variant="ghost" size="icon" className="h-11 w-11"
            disabled={index === 0} onClick={() => onMove(index, -1)}
            aria-label={`تحريك العنصر ${index + 1} لأعلى`} title="تحريك لأعلى"
          >
            <ChevronUp className="w-4.5 h-4.5" />
          </Button>
          <Button
            variant="ghost" size="icon" className="h-11 w-11"
            disabled={index === total - 1} onClick={() => onMove(index, 1)}
            aria-label={`تحريك العنصر ${index + 1} لأسفل`} title="تحريك لأسفل"
          >
            <ChevronDown className="w-4.5 h-4.5" />
          </Button>
          <Button
            variant="ghost" size="icon" className="h-11 w-11 text-destructive hover:bg-destructive/10 hover:text-destructive"
            disabled={disableRemove} onClick={() => onRemove(index)}
            aria-label={`حذف العنصر ${index + 1}`} title="حذف"
          >
            <Trash2 className="w-4.5 h-4.5" />
          </Button>
        </div>
      </div>
      {children}
    </div>
  )
}

// ───────────── IconSelect — منتقي أيقونة ─────────────

export function IconSelect({ value, onValueChange, label = 'الأيقونة' }: { value: IconKey; onValueChange: (v: IconKey) => void; label?: string }) {
  const id = useId()
  return (
    <div className="space-y-1.5 min-w-0">
      <Label htmlFor={id}>{label}</Label>
      <Select value={value} onValueChange={(v) => onValueChange(v as IconKey)}>
        <SelectTrigger id={id} className="w-full">
          <span className="flex items-center gap-2 min-w-0">
            <ContentIcon name={value} className="w-4 h-4 shrink-0" />
            <span className="truncate">{ICON_LABELS[value]}</span>
          </span>
        </SelectTrigger>
        <SelectContent className="max-h-72">
          {CONTENT_ICON_OPTIONS.map((opt) => (
            <SelectItem key={opt.key} value={opt.key}>
              <span className="flex items-center gap-2">
                <ContentIcon name={opt.key} className="w-4 h-4 shrink-0" />
                <span>{opt.label}</span>
              </span>
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
    </div>
  )
}

// ───────────── مكتبة الصور (حوار مشترك) ─────────────

interface UploadedFile { url: string; bytes: number; modifiedAt: number }

/**
 * حوار مكتبة الصور — يجمع الصور المرفوعة (GET /api/admin/upload) +
 * مكتبة الصور الجاهزة. أحادي: النقر يختار فورًا. متعدد: تحديد + تأكيد.
 */
export function ImageLibraryDialog({
  open,
  onOpenChange,
  onPick,
  multiple = false,
  title = 'مكتبة الصور',
}: {
  open: boolean
  onOpenChange: (v: boolean) => void
  onPick: (urls: string[]) => void
  multiple?: boolean
  title?: string
}) {
  const [files, setFiles] = useState<UploadedFile[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [selected, setSelected] = useState<string[]>([])

  // تحديث قائمة الملفات المرفوعة عند كل فتح (القائمة القديمة تظهر حتى يكتمل الجلب)
  useEffect(() => {
    if (!open) return
    let alive = true
    api<{ files: UploadedFile[] }>('/api/admin/upload')
      .then((res) => {
        if (alive) {
          setFiles(res.files)
          setError(null)
        }
      })
      .catch((e) => {
        if (alive) setError(e instanceof Error ? e.message : 'تعذر تحميل مكتبة الصور')
      })
      .finally(() => {
        if (alive) setLoading(false)
      })
    return () => {
      alive = false
    }
  }, [open])

  // إعادة ضبط التحديد عند الإغلاق (سياق حدث — ليس داخل effect)
  const handleOpenChange = (v: boolean) => {
    if (!v) setSelected([])
    onOpenChange(v)
  }

  const pick = (url: string) => {
    onPick([url])
    handleOpenChange(false)
  }
  const toggle = (url: string) =>
    setSelected((prev) => (prev.includes(url) ? prev.filter((u) => u !== url) : [...prev, url]))
  const confirm = () => {
    if (selected.length === 0) return
    onPick(selected)
    handleOpenChange(false)
  }

  const cell = (url: string, isUploaded: boolean) => {
    const isSelected = selected.includes(url)
    return (
      <button
        type="button"
        onClick={() => (multiple ? toggle(url) : pick(url))}
        aria-pressed={multiple ? isSelected : undefined}
        aria-label={isUploaded ? 'صورة مرفوعة' : 'صورة جاهزة'}
        className={cn(
          'relative aspect-square rounded-lg overflow-hidden border-2 transition-all group',
          multiple && isSelected
            ? 'border-primary ring-2 ring-primary/30'
            : 'border-transparent hover:border-border'
        )}
      >
        <img src={url} alt="" loading="lazy" className="w-full h-full object-cover" />
        {multiple && (
          <span
            className={cn(
              'absolute top-1.5 left-1.5 rounded-md p-1 transition-colors',
              isSelected ? 'bg-primary text-primary-foreground' : 'bg-background/80 text-muted-foreground opacity-0 group-hover:opacity-100'
            )}
          >
            <Check className="w-3.5 h-3.5" />
          </span>
        )}
      </button>
    )
  }

  return (
    <Dialog open={open} onOpenChange={handleOpenChange}>
      <DialogContent className="max-w-2xl">
        <DialogHeader className="text-right">
          <DialogTitle>{title}</DialogTitle>
          <DialogDescription>
            {multiple ? 'اختر صورة أو أكثر لإضافتها — يمكنك دمج صور جاهزة مع صور رفعتها سابقًا' : 'اختر صورة لاستخدامها في هذا الحقل'}
          </DialogDescription>
        </DialogHeader>

        <div className="max-h-[60vh] overflow-y-auto space-y-4 pr-1">
          {loading ? (
            <div className="grid grid-cols-3 sm:grid-cols-4 gap-2">
              {Array.from({ length: 8 }).map((_, i) => (
                <Skeleton key={i} className="aspect-square rounded-lg" />
              ))}
            </div>
          ) : error ? (
            <p className="text-sm text-destructive text-center py-8">{error}</p>
          ) : (
            <>
              {files.length > 0 && (
                <section className="space-y-2">
                  <h4 className="text-xs font-bold text-muted-foreground flex items-center gap-1.5">
                    <Upload className="w-3.5 h-3.5" /> الصور المرفوعة ({files.length})
                  </h4>
                  <div className="grid grid-cols-3 sm:grid-cols-4 gap-2">
                    {files.map((f) => cell(f.url, true))}
                  </div>
                </section>
              )}
              <section className="space-y-2">
                <h4 className="text-xs font-bold text-muted-foreground flex items-center gap-1.5">
                  <ImagesIcon className="w-3.5 h-3.5" /> صور الفندق الجاهزة ({IMAGE_LIBRARY.length})
                </h4>
                <div className="grid grid-cols-3 sm:grid-cols-4 gap-2">
                  {IMAGE_LIBRARY.map((url) => cell(url, false))}
                </div>
              </section>
            </>
          )}
        </div>

        {multiple && (
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => handleOpenChange(false)} className="min-h-11">إغلاق</Button>
            <Button onClick={confirm} disabled={selected.length === 0} className="min-h-11 gap-2">
              <Check className="w-4 h-4" />
              {selected.length === 0 ? 'لم تُحدَّد صور' : `إضافة ${selected.length} ${selected.length === 1 ? 'صورة' : 'صور'}`}
            </Button>
          </DialogFooter>
        )}
      </DialogContent>
    </Dialog>
  )
}

// ───────────── ImageField — معاينة + رفع/مكتبة/رابط ─────────────

export function ImageField({
  value,
  onChange,
  label,
  aspect = 'wide',
  previewClassName,
}: {
  value: string
  onChange: (url: string) => void
  label?: string
  aspect?: 'wide' | 'square'
  previewClassName?: string
}) {
  const { toast } = useToast()
  const fileRef = useRef<HTMLInputElement>(null)
  const [uploading, setUploading] = useState(false)
  const [libOpen, setLibOpen] = useState(false)
  const [linkOpen, setLinkOpen] = useState(false)
  const [linkValue, setLinkValue] = useState('')
  const [linkError, setLinkError] = useState<string | null>(null)

  const basePreview =
    aspect === 'square'
      ? 'aspect-square w-full max-w-[176px] object-cover'
      : 'h-36 w-full object-cover'
  const containerCls = aspect === 'square' ? 'max-w-[176px]' : ''

  const upload = async (file: File | undefined) => {
    if (!file) return
    if (file.size > 5 * 1024 * 1024) {
      toast({ title: 'الصورة أكبر من الحد', description: 'حجم الصورة يجب أن يكون أقل من 5 ميغابايت', variant: 'destructive' })
      return
    }
    setUploading(true)
    try {
      const url = await apiUpload(file)
      onChange(url)
      toast({ title: 'تم رفع الصورة', description: 'احفظ القسم لتظهر على الموقع' })
    } catch (e) {
      toast({ title: 'تعذّر رفع الصورة', description: e instanceof Error ? e.message : 'حدث خطأ غير متوقع', variant: 'destructive' })
    } finally {
      setUploading(false)
      if (fileRef.current) fileRef.current.value = ''
    }
  }

  const applyLink = () => {
    const v = linkValue.trim()
    if (v === '' || (!v.startsWith('/') && !/^https?:\/\//i.test(v))) {
      setLinkError('الرابط يجب أن يبدأ بـ / أو http(s)://')
      return
    }
    onChange(v)
    setLinkError(null)
    setLinkValue('')
    setLinkOpen(false)
  }

  return (
    <div className="space-y-2 min-w-0">
      {label && <Label>{label}</Label>}
      <div className={cn('relative rounded-lg border overflow-hidden bg-muted', containerCls)}>
        {value ? (
          <img src={value} alt={label ?? 'صورة'} className={cn('block', basePreview, previewClassName)} />
        ) : (
          <div className={cn(basePreview, previewClassName, 'flex items-center justify-center text-muted-foreground')}>
            <ImageOff className="w-7 h-7" />
          </div>
        )}
      </div>
      <div className="flex flex-wrap gap-2">
        <input
          ref={fileRef}
          type="file"
          accept="image/png,image/jpeg,image/webp,image/gif,image/svg+xml"
          hidden
          onChange={(e) => upload(e.target.files?.[0])}
        />
        <Button
          type="button" variant="outline" size="sm"
          onClick={() => fileRef.current?.click()} disabled={uploading}
          className="gap-2 min-h-11"
        >
          {uploading ? <Loader2 className="w-4 h-4 animate-spin" /> : <Upload className="w-4 h-4" />}
          رفع صورة
        </Button>
        <Button type="button" variant="outline" size="sm" onClick={() => setLibOpen(true)} className="gap-2 min-h-11">
          <ImagesIcon className="w-4 h-4" /> من المكتبة
        </Button>
        <Popover open={linkOpen} onOpenChange={setLinkOpen}>
          <PopoverTrigger asChild>
            <Button type="button" variant="outline" size="sm" className="gap-2 min-h-11">
              <Link2 className="w-4 h-4" /> رابط
            </Button>
          </PopoverTrigger>
          <PopoverContent className="w-80" align="start">
            <div className="space-y-2">
              <Label htmlFor="img-link">رابط الصورة يدويًا</Label>
              <Input
                id="img-link"
                value={linkValue}
                onChange={(e) => { setLinkValue(e.target.value); setLinkError(null) }}
                onKeyDown={(e) => e.key === 'Enter' && applyLink()}
                placeholder="https://example.com/photo.jpg"
                dir="ltr"
              />
              {linkError && <p className="text-xs text-destructive">{linkError}</p>}
              <p className="text-[11px] text-muted-foreground leading-relaxed">
                يجب أن يبدأ الرابط بـ «/» (ملف داخلي) أو «http» (رابط خارجي).
              </p>
              <Button type="button" size="sm" onClick={applyLink} className="min-h-11 w-full">تطبيق الرابط</Button>
            </div>
          </PopoverContent>
        </Popover>
      </div>

      <ImageLibraryDialog open={libOpen} onOpenChange={setLibOpen} onPick={(urls) => onChange(urls[0] ?? '')} />
    </div>
  )
}

// ───────────── FormFooter — أزرار حفظ/تراجع ─────────────

export function FormFooter({
  dirty,
  busy,
  onSave,
  onRevert,
  saveLabel = 'حفظ التغييرات',
  idleLabel = 'لا توجد تغييرات',
}: {
  dirty: boolean
  busy: boolean
  onSave: () => void
  onRevert: () => void
  saveLabel?: string
  idleLabel?: string
}) {
  return (
    <div className="flex flex-wrap items-center justify-end gap-2 pt-2 border-t">
      <Button type="button" variant="outline" onClick={onRevert} disabled={!dirty || busy} className="gap-1.5 min-h-11">
        <RotateCcw className="w-4 h-4" /> تراجع
      </Button>
      <Button type="button" onClick={onSave} disabled={!dirty || busy} className="gap-2 min-h-11 min-w-36">
        {busy ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
        {dirty ? saveLabel : idleLabel}
      </Button>
    </div>
  )
}
