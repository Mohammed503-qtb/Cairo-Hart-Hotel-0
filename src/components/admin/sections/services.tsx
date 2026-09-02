'use client'

// ─────────────────────────────────────────────────────────────
// SERVICES — الخدمات والأقسام (Tabs)
// ─────────────────────────────────────────────────────────────
import { useState } from 'react'
import { Plus, Pencil, Trash2, Loader2, ConciergeBell, FolderOpen } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Switch } from '@/components/ui/switch'
import { Skeleton } from '@/components/ui/skeleton'
import { Badge } from '@/components/ui/badge'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import {
  Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle,
} from '@/components/ui/dialog'
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription,
  AlertDialogFooter, AlertDialogHeader, AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { api } from '@/lib/api-client'
import { formatMoney } from '@/lib/format'
import type { ServiceAdmin, ServiceCategoryAdmin } from '../types'
import { useLoader, ErrorState, useBusyAction, EmptyState, SectionHeader, Ltr, TableSkeleton, dollarsToCents, centsToDollarsInput } from '../shared'

const CATEGORY_KEYS = [
  { value: 'HOUSEKEEPING', label: 'تنظيف (HOUSEKEEPING)' },
  { value: 'MAINTENANCE', label: 'صيانة (MAINTENANCE)' },
  { value: 'GUEST_SERVICES', label: 'ضيافة (GUEST_SERVICES)' },
  { value: 'OTHER', label: 'أخرى (OTHER)' },
]

export default function ServicesSection() {
  return (
    <Tabs defaultValue="services" dir="rtl" className="space-y-4">
      <div>
        <SectionHeader title="الخدمات" description="كتالوج الخدمات التي يطلبها الضيوف خلال الإقامة" />
        <TabsList className="grid grid-cols-2 w-full max-w-xs mb-4">
          <TabsTrigger value="services" className="gap-1.5"><ConciergeBell className="w-4 h-4" /> الخدمات</TabsTrigger>
          <TabsTrigger value="categories" className="gap-1.5"><FolderOpen className="w-4 h-4" /> الأقسام</TabsTrigger>
        </TabsList>
      </div>
      <TabsContent value="services" className="mt-0">
        <ServicesTab />
      </TabsContent>
      <TabsContent value="categories" className="mt-0">
        <CategoriesTab />
      </TabsContent>
    </Tabs>
  )
}

// ─────────────────────── تبويب الخدمات ───────────────────────

function ServicesTab() {
  const { data, loading, error, reload } = useLoader<{ services: ServiceAdmin[] }>(() => api('/api/admin/services'))
  const { data: catsData } = useLoader<{ categories: ServiceCategoryAdmin[] }>(() => api('/api/admin/service-categories'))
  const { busy, run, toast } = useBusyAction()

  const [catFilter, setCatFilter] = useState('all')
  const [dialogOpen, setDialogOpen] = useState(false)
  const [editing, setEditing] = useState<ServiceAdmin | null>(null)
  const [form, setForm] = useState({ name: '', nameEn: '', description: '', price: '', categoryId: '', active: true })
  const [deleteTarget, setDeleteTarget] = useState<ServiceAdmin | null>(null)

  const services = data?.services ?? []
  const categories = catsData?.categories ?? []
  const filtered = services.filter((s) => catFilter === 'all' || s.categoryId === catFilter)

  const openCreate = () => {
    setEditing(null)
    setForm({ name: '', nameEn: '', description: '', price: '', categoryId: categories[0]?.id ?? '', active: true })
    setDialogOpen(true)
  }

  const openEdit = (s: ServiceAdmin) => {
    setEditing(s)
    setForm({
      name: s.name,
      nameEn: s.nameEn,
      description: s.description,
      price: s.priceCents ? centsToDollarsInput(s.priceCents) : '',
      categoryId: s.categoryId,
      active: s.active,
    })
    setDialogOpen(true)
  }

  const submit = () =>
    run(async () => {
      if (!form.name.trim()) throw new Error('اسم الخدمة مطلوب')
      if (!form.categoryId) throw new Error('اختر القسم')
      const cents = form.price.trim() === '' ? 0 : dollarsToCents(form.price)
      if (cents === null || cents < 0) throw new Error('أدخل سعرًا صحيحًا بالدولار (0 لمجانية)')
      const body = {
        name: form.name.trim(),
        nameEn: form.nameEn,
        description: form.description,
        priceCents: cents,
        categoryId: form.categoryId,
        active: form.active,
      }
      if (editing) {
        await api(`/api/admin/services/${editing.id}`, { method: 'PATCH', body })
        toast({ title: 'تم تحديث الخدمة' })
      } else {
        await api('/api/admin/services', { method: 'POST', body })
        toast({ title: 'تمت إضافة الخدمة' })
      }
      setDialogOpen(false)
      await reload()
    })

  const toggleActive = (s: ServiceAdmin) =>
    run(async () => {
      await api(`/api/admin/services/${s.id}`, { method: 'PATCH', body: { active: !s.active } })
      await reload()
    })

  const doDelete = () =>
    run(async () => {
      if (!deleteTarget) return
      const res = await api<{ deactivated?: boolean; deleted?: boolean; message?: string }>(`/api/admin/services/${deleteTarget.id}`, { method: 'DELETE' })
      toast({ title: res.deactivated ? 'تم تعطيل الخدمة' : 'تم حذف الخدمة', description: res.message })
      setDeleteTarget(null)
      await reload()
    })

  if (error) {
    return <Card><CardContent><ErrorState message={error} onRetry={reload} /></CardContent></Card>
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center gap-2">
        <Select value={catFilter} onValueChange={setCatFilter}>
          <SelectTrigger size="sm" className="w-44"><SelectValue placeholder="كل الأقسام" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">كل الأقسام</SelectItem>
            {categories.map((c) => (
              <SelectItem key={c.id} value={c.id}>{c.name}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <span className="text-xs text-muted-foreground">{filtered.length} خدمة</span>
        <Button onClick={openCreate} className="gap-2 mr-auto" size="sm" disabled={categories.length === 0}>
          <Plus className="w-4 h-4" /> إضافة خدمة
        </Button>
      </div>

      <Card className="border-border/60 overflow-hidden">
        <CardContent className="p-0">
          {loading ? (
            <TableSkeleton rows={8} cols={5} />
          ) : filtered.length === 0 ? (
            <EmptyState icon={ConciergeBell} title="لا توجد خدمات" description="أضف خدمات يطلبها الضيوف من تطبيق الإقامة" />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm min-w-[640px]">
                <thead>
                  <tr className="border-b text-xs text-muted-foreground bg-muted/40">
                    <th className="text-start font-medium px-4 py-2.5">الخدمة</th>
                    <th className="text-start font-medium px-2 py-2.5">القسم</th>
                    <th className="text-start font-medium px-2 py-2.5">السعر</th>
                    <th className="text-start font-medium px-2 py-2.5">نشطة</th>
                    <th className="text-start font-medium px-4 py-2.5 w-20"></th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((s) => (
                    <tr key={s.id} className={`border-b last:border-0 hover:bg-accent/50 transition-colors ${!s.active ? 'opacity-55' : ''}`}>
                      <td className="px-4 py-2.5">
                        <p className="font-medium">{s.name}</p>
                        {s.nameEn && <Ltr className="text-[10px] text-muted-foreground block">{s.nameEn}</Ltr>}
                      </td>
                      <td className="px-2 py-2.5">
                        <Badge variant="outline" className="text-xs">{s.categoryName}</Badge>
                      </td>
                      <td className="px-2 py-2.5 font-bold tabular-nums">
                        {s.priceCents === 0 ? <span className="text-success">مجاني</span> : formatMoney(s.priceCents)}
                      </td>
                      <td className="px-2 py-2.5">
                        <Switch checked={s.active} onCheckedChange={() => toggleActive(s)} disabled={busy} aria-label={`تفعيل ${s.name}`} />
                      </td>
                      <td className="px-4 py-2.5">
                        <div className="flex gap-1">
                          <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => openEdit(s)} aria-label={`تعديل ${s.name}`}>
                            <Pencil className="w-4 h-4" />
                          </Button>
                          <Button variant="ghost" size="icon" className="h-8 w-8 text-destructive" onClick={() => setDeleteTarget(s)} aria-label={`حذف ${s.name}`}>
                            <Trash2 className="w-4 h-4" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Dialog خدمة */}
      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>{editing ? `تعديل: ${editing.name}` : 'إضافة خدمة'}</DialogTitle>
            <DialogDescription>ستظهر للضيوف في تطبيق الإقامة حسب قسمها</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-1.5">
              <Label>الاسم *</Label>
              <Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="توصيل مطعم" />
            </div>
            <div className="space-y-1.5">
              <Label>الاسم (إنجليزي)</Label>
              <Input value={form.nameEn} onChange={(e) => setForm({ ...form, nameEn: e.target.value })} dir="ltr" />
            </div>
            <div className="space-y-1.5">
              <Label>الوصف</Label>
              <Textarea value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} rows={2} />
            </div>
            <div className="space-y-1.5">
              <Label>القسم *</Label>
              <Select value={form.categoryId} onValueChange={(v) => setForm({ ...form, categoryId: v })}>
                <SelectTrigger className="w-full"><SelectValue placeholder="اختر القسم" /></SelectTrigger>
                <SelectContent>
                  {categories.map((c) => (
                    <SelectItem key={c.id} value={c.id}>{c.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label>السعر ($) — اتركه فارغًا للمجانية</Label>
              <Input type="number" min={0} step="0.01" value={form.price} onChange={(e) => setForm({ ...form, price: e.target.value })} dir="ltr" placeholder="5" />
            </div>
            <div className="flex items-center gap-2">
              <Switch id="srv-active" checked={form.active} onCheckedChange={(v) => setForm({ ...form, active: v })} />
              <Label htmlFor="srv-active">{form.active ? 'نشطة' : 'معطّلة'}</Label>
            </div>
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setDialogOpen(false)}>إلغاء</Button>
            <Button onClick={submit} disabled={busy} className="gap-2">
              {busy && <Loader2 className="w-4 h-4 animate-spin" />} {editing ? 'حفظ' : 'إضافة'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* حذف/تعطيل خدمة */}
      <AlertDialog open={!!deleteTarget} onOpenChange={(v) => !v && setDeleteTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>حذف خدمة «{deleteTarget?.name}»؟</AlertDialogTitle>
            <AlertDialogDescription>
              إن كانت الخدمة مرتبطة بطلبات سابقة فسيتم <b>تعطيلها</b> بدل حذفها للحفاظ على السجلات. الخدمات غير
              المرتبطة تُحذف نهائيًا.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>تراجع</AlertDialogCancel>
            <AlertDialogAction onClick={doDelete} className="bg-destructive text-white hover:bg-destructive/90">متابعة</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}

// ─────────────────────── تبويب الأقسام ───────────────────────

function CategoriesTab() {
  const { data, loading, error, reload } = useLoader<{ categories: ServiceCategoryAdmin[] }>(() => api('/api/admin/service-categories'))
  const { busy, run, toast } = useBusyAction()

  const [dialogOpen, setDialogOpen] = useState(false)
  const [editing, setEditing] = useState<ServiceCategoryAdmin | null>(null)
  const [form, setForm] = useState({ name: '', key: 'OTHER', icon: '', sortOrder: '0' })
  const [deleteTarget, setDeleteTarget] = useState<ServiceCategoryAdmin | null>(null)

  const categories = data?.categories ?? []

  const openCreate = () => {
    setEditing(null)
    setForm({ name: '', key: 'OTHER', icon: '', sortOrder: '0' })
    setDialogOpen(true)
  }

  const openEdit = (c: ServiceCategoryAdmin) => {
    setEditing(c)
    setForm({ name: c.name, key: c.key, icon: c.icon, sortOrder: String(c.sortOrder) })
    setDialogOpen(true)
  }

  const submit = () =>
    run(async () => {
      if (!form.name.trim()) throw new Error('اسم القسم مطلوب')
      const body = { name: form.name.trim(), key: form.key, icon: form.icon, sortOrder: parseInt(form.sortOrder, 10) || 0 }
      if (editing) {
        await api(`/api/admin/service-categories/${editing.id}`, { method: 'PATCH', body })
        toast({ title: 'تم تحديث القسم' })
      } else {
        await api('/api/admin/service-categories', { method: 'POST', body })
        toast({ title: 'تمت إضافة القسم' })
      }
      setDialogOpen(false)
      await reload()
    })

  const doDelete = () =>
    run(async () => {
      if (!deleteTarget) return
      const res = await api<{ deleted?: boolean; message?: string }>(`/api/admin/service-categories/${deleteTarget.id}`, { method: 'DELETE' })
      toast({ title: 'تم حذف القسم', description: res.message })
      setDeleteTarget(null)
      await reload()
    })

  if (error) {
    return <Card><CardContent><ErrorState message={error} onRetry={reload} /></CardContent></Card>
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center gap-2">
        <span className="text-xs text-muted-foreground">{categories.length} قسم</span>
        <Button onClick={openCreate} className="gap-2 mr-auto" size="sm">
          <Plus className="w-4 h-4" /> إضافة قسم
        </Button>
      </div>

      {loading ? (
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-3">
          {Array.from({ length: 3 }).map((_, i) => <Skeleton key={i} className="h-28 rounded-xl" />)}
        </div>
      ) : categories.length === 0 ? (
        <Card><CardContent><EmptyState icon={FolderOpen} title="لا توجد أقسام" /></CardContent></Card>
      ) : (
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-3">
          {categories.map((c) => (
            <Card key={c.id} className="border-border/60">
              <CardContent className="p-4">
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0">
                    <h3 className="font-bold truncate">{c.name}</h3>
                    <Ltr className="text-[11px] text-muted-foreground block">{c.key}</Ltr>
                  </div>
                  <Badge variant="secondary" className="shrink-0">{c.servicesCount} خدمة</Badge>
                </div>
                <div className="flex gap-1 mt-3 pt-2.5 border-t">
                  <Button variant="ghost" size="sm" className="gap-1.5 h-8" onClick={() => openEdit(c)}>
                    <Pencil className="w-3.5 h-3.5" /> تعديل
                  </Button>
                  <Button variant="ghost" size="sm" className="gap-1.5 h-8 text-destructive" onClick={() => setDeleteTarget(c)}>
                    <Trash2 className="w-3.5 h-3.5" /> حذف
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>{editing ? `تعديل: ${editing.name}` : 'إضافة قسم'}</DialogTitle>
            <DialogDescription>الأقسام تُصنّف الخدمات في تطبيق الضيف والاستقبال</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-1.5">
              <Label>اسم القسم *</Label>
              <Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="خدمات إضافية" />
            </div>
            <div className="space-y-1.5">
              <Label>المفتاح *</Label>
              <Select value={form.key} onValueChange={(v) => setForm({ ...form, key: v })}>
                <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                <SelectContent>
                  {CATEGORY_KEYS.map((k) => (
                    <SelectItem key={k.value} value={k.value}>{k.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label>الأيقونة (lucide)</Label>
                <Input value={form.icon} onChange={(e) => setForm({ ...form, icon: e.target.value })} dir="ltr" placeholder="sparkles" />
              </div>
              <div className="space-y-1.5">
                <Label>الترتيب</Label>
                <Input type="number" value={form.sortOrder} onChange={(e) => setForm({ ...form, sortOrder: e.target.value })} dir="ltr" />
              </div>
            </div>
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setDialogOpen(false)}>إلغاء</Button>
            <Button onClick={submit} disabled={busy} className="gap-2">
              {busy && <Loader2 className="w-4 h-4 animate-spin" />} {editing ? 'حفظ' : 'إضافة'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <AlertDialog open={!!deleteTarget} onOpenChange={(v) => !v && setDeleteTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>حذف قسم «{deleteTarget?.name}»؟</AlertDialogTitle>
            <AlertDialogDescription>
              الحذف متاح فقط للأقسام <b>بدون خدمات نشطة</b> وبلا طلبات مرتبطة — وإلا يُرفض الحذف حفاظًا على السجلات.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>تراجع</AlertDialogCancel>
            <AlertDialogAction onClick={doDelete} className="bg-destructive text-white hover:bg-destructive/90">متابعة</AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
