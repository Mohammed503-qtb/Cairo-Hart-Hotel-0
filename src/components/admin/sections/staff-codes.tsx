'use client'

// ─────────────────────────────────────────────────────────────
// STAFF & CODES — الطاقم وأكواد الوصول (Tabs)
// ─────────────────────────────────────────────────────────────
import { useState } from 'react'
import {
  Plus, Pencil, Loader2, KeyRound, Users, Copy, Check, ShieldAlert, Ban,
} from 'lucide-react'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Skeleton } from '@/components/ui/skeleton'
import { Badge } from '@/components/ui/badge'
import { Switch } from '@/components/ui/switch'
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
import { formatDateAr, formatDateTimeAr, timeAgoAr } from '@/lib/format'
import type { StaffAdmin, AccessCodeAdmin } from '../types'
import { useLoader, ErrorState, useBusyAction, EmptyState, SectionHeader, Ltr, TableSkeleton, CodeTypeBadge, CodeStatusBadge, StaffRoleBadge } from '../shared'

export default function StaffCodesSection() {
  return (
    <Tabs defaultValue="codes" dir="rtl" className="space-y-4">
      <div>
        <SectionHeader title="الطاقم والأكواد" description="موظفو الفندق وأكواد الدخول — كود فعّال واحد على الأكثر لكل موظف" />
        <TabsList className="grid grid-cols-2 w-full max-w-xs mb-4">
          <TabsTrigger value="codes" className="gap-1.5"><KeyRound className="w-4 h-4" /> الأكواد</TabsTrigger>
          <TabsTrigger value="staff" className="gap-1.5"><Users className="w-4 h-4" /> الطاقم</TabsTrigger>
        </TabsList>
      </div>
      <TabsContent value="codes" className="mt-0">
        <CodesTab />
      </TabsContent>
      <TabsContent value="staff" className="mt-0">
        <StaffTab />
      </TabsContent>
    </Tabs>
  )
}

// ─────────────────────── تبويب الأكواد ───────────────────────

interface GeneratedCode {
  code: string
  codeMasked: string
  expiresAt: string
  staffName: string
  days: number
  type: string
}

function CodesTab() {
  const { data, loading, error, reload } = useLoader<{ codes: AccessCodeAdmin[] }>(() => api('/api/admin/codes'))
  const { data: staffData } = useLoader<{ staff: StaffAdmin[] }>(() => api('/api/admin/staff'))
  const { busy, run, toast } = useBusyAction()

  const [typeFilter, setTypeFilter] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')

  const [genOpen, setGenOpen] = useState(false)
  const [genForm, setGenForm] = useState({ type: 'RECEPTION', staffId: '', days: '7' })
  const [generated, setGenerated] = useState<GeneratedCode | null>(null)
  const [copied, setCopied] = useState(false)
  const [revokeTarget, setRevokeTarget] = useState<AccessCodeAdmin | null>(null)

  const codes = (data?.codes ?? []).filter(
    (c) => (typeFilter === 'all' || c.type === typeFilter) && (statusFilter === 'all' || c.status === statusFilter)
  )
  const staff = staffData?.staff ?? []
  const eligibleStaff = staff.filter((s) =>
    genForm.type === 'RECEPTION' ? s.role === 'RECEPTION' && s.active : ['ADMIN', 'MANAGER'].includes(s.role) && s.active
  )

  const openGenerate = () => {
    setGenerated(null)
    setCopied(false)
    setGenForm({ type: 'RECEPTION', staffId: '', days: '7' })
    setGenOpen(true)
  }

  const generate = () =>
    run(async () => {
      if (!genForm.staffId) throw new Error('اختر الموظف')
      const res = await api<GeneratedCode>('/api/admin/codes', {
        method: 'POST',
        body: { type: genForm.type, staffId: genForm.staffId, days: parseInt(genForm.days, 10) || 7 },
      })
      setGenerated(res)
      toast({ title: 'تم توليد الكود — انسخه الآن', description: 'لن يظهر الكود الخام مرة أخرى' })
      await reload()
    })

  const copyCode = async () => {
    if (!generated) return
    try {
      await navigator.clipboard.writeText(generated.code)
      setCopied(true)
      toast({ title: 'نُسخ الكود إلى الحافظة' })
      setTimeout(() => setCopied(false), 2500)
    } catch {
      toast({ title: 'تعذر النسخ التلقائي — انسخ الكود يدويًا', variant: 'destructive' })
    }
  }

  const doRevoke = () =>
    run(async () => {
      if (!revokeTarget) return
      const res = await api<{ message?: string }>('/api/admin/codes/revoke', {
        method: 'POST',
        body: { codeId: revokeTarget.id },
      })
      toast({ title: 'تم إبطال الكود', description: res.message })
      setRevokeTarget(null)
      await reload()
    })

  if (error) {
    return <Card><CardContent><ErrorState message={error} onRetry={reload} /></CardContent></Card>
  }

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap items-center gap-2">
        <Select value={typeFilter} onValueChange={setTypeFilter}>
          <SelectTrigger size="sm" className="w-36"><SelectValue placeholder="كل الأنواع" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">كل الأنواع</SelectItem>
            <SelectItem value="GUEST">ضيف</SelectItem>
            <SelectItem value="RECEPTION">استقبال</SelectItem>
            <SelectItem value="ADMIN">إدارة</SelectItem>
          </SelectContent>
        </Select>
        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger size="sm" className="w-32"><SelectValue placeholder="كل الحالات" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">كل الحالات</SelectItem>
            <SelectItem value="ACTIVE">فعّال</SelectItem>
            <SelectItem value="EXPIRED">منتهي</SelectItem>
            <SelectItem value="REVOKED">ملغي</SelectItem>
          </SelectContent>
        </Select>
        <span className="text-xs text-muted-foreground">{codes.length} كود</span>
        <Button onClick={openGenerate} className="gap-2 mr-auto" size="sm">
          <KeyRound className="w-4 h-4" /> توليد كود
        </Button>
      </div>

      <Card className="border-border/60 overflow-hidden">
        <CardContent className="p-0">
          {loading ? (
            <TableSkeleton rows={6} cols={6} />
          ) : codes.length === 0 ? (
            <EmptyState icon={KeyRound} title="لا توجد أكواد مطابقة" />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm min-w-[820px]">
                <thead>
                  <tr className="border-b text-xs text-muted-foreground bg-muted/40">
                    <th className="text-start font-medium px-4 py-2.5">الكود</th>
                    <th className="text-start font-medium px-2 py-2.5">النوع</th>
                    <th className="text-start font-medium px-2 py-2.5">السياق</th>
                    <th className="text-start font-medium px-2 py-2.5">ينتهي في</th>
                    <th className="text-start font-medium px-2 py-2.5">آخر استخدام</th>
                    <th className="text-start font-medium px-2 py-2.5">الحالة</th>
                    <th className="text-start font-medium px-4 py-2.5 w-20"></th>
                  </tr>
                </thead>
                <tbody>
                  {codes.map((c) => (
                    <tr key={c.id} className={`border-b last:border-0 hover:bg-accent/50 transition-colors ${c.status === 'REVOKED' ? 'opacity-55' : ''}`}>
                      <td className="px-4 py-3"><Ltr className="font-bold text-sm">{c.codeMasked}</Ltr></td>
                      <td className="px-2 py-3"><CodeTypeBadge type={c.type} /></td>
                      <td className="px-2 py-3 text-xs">
                        {c.staffName ? (
                          <span className="font-medium">{c.staffName}</span>
                        ) : c.guestName ? (
                          <span>
                            ضيف — <span className="font-medium">{c.guestName}</span>
                            {c.roomNumber && <span className="text-muted-foreground"> (غرفة {c.roomNumber})</span>}
                          </span>
                        ) : (
                          <span className="text-muted-foreground">—</span>
                        )}
                      </td>
                      <td className="px-2 py-3 text-xs text-muted-foreground">{formatDateAr(c.expiresAt)}</td>
                      <td className="px-2 py-3 text-xs text-muted-foreground" title={c.lastUsedAt ? formatDateTimeAr(c.lastUsedAt) : ''}>
                        {c.lastUsedAt ? timeAgoAr(c.lastUsedAt) : 'لم يُستخدم'}
                      </td>
                      <td className="px-2 py-3"><CodeStatusBadge status={c.status} /></td>
                      <td className="px-4 py-3">
                        {c.status === 'ACTIVE' ? (
                          <Button variant="outline" size="sm" className="h-8 gap-1.5 text-destructive border-destructive/40 hover:bg-destructive/10" onClick={() => setRevokeTarget(c)} disabled={busy}>
                            <Ban className="w-3.5 h-3.5" /> إبطال
                          </Button>
                        ) : (
                          <span className="text-xs text-muted-foreground">—</span>
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

      {/* توليد كود */}
      <Dialog open={genOpen} onOpenChange={(v) => { setGenOpen(v); if (!v) setGenerated(null) }}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2"><KeyRound className="w-5 h-5 text-gold" /> توليد كود دخول</DialogTitle>
            <DialogDescription>الكود الخام يظهر مرة واحدة فقط عند التوليد — انسخه فورًا</DialogDescription>
          </DialogHeader>

          {generated ? (
            /* النتيجة — الكود الخام */
            <div className="space-y-4">
              <div className="rounded-xl border-2 border-gold/60 bg-[#10131c] p-5 text-center space-y-3 gold-glow">
                <p className="text-xs text-muted-foreground">
                  كود {generated.type === 'ADMIN' ? 'إدارة' : 'استقبال'} — {generated.staffName} ({generated.days} يومًا)
                </p>
                <Ltr className="block text-3xl font-extrabold tracking-[0.15em] text-gold select-all">{generated.code}</Ltr>
                <div className="flex items-center justify-center gap-2 text-[11px] text-muted-foreground/70">
                  <ShieldAlert className="w-3.5 h-3.5 text-warning" />
                  <span>انسخه الآن — لن يظهر مرة أخرى</span>
                </div>
              </div>
              <div className="flex items-center justify-between text-xs text-muted-foreground px-1">
                <span>ينتهي: {formatDateTimeAr(generated.expiresAt)}</span>
                <span>المخزّن: <Ltr className="text-[11px]">{generated.codeMasked}</Ltr></span>
              </div>
              <Button onClick={copyCode} className="w-full gap-2 h-11" variant={copied ? 'default' : 'secondary'}>
                {copied ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
                {copied ? 'تم النسخ' : 'نسخ الكود'}
              </Button>
            </div>
          ) : (
            <div className="space-y-4">
              <div className="space-y-1.5">
                <Label>نوع الكود *</Label>
                <Select value={genForm.type} onValueChange={(v) => setGenForm({ ...genForm, type: v, staffId: '' })}>
                  <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="RECEPTION">استقبال (R…)</SelectItem>
                    <SelectItem value="ADMIN">إدارة (A…)</SelectItem>
                  </SelectContent>
                </Select>
                <p className="text-[11px] text-muted-foreground">كود الضيف يُولَّد تلقائيًا عند تسجيل الوصول من الاستقبال</p>
              </div>
              <div className="space-y-1.5">
                <Label>الموظف *</Label>
                <Select value={genForm.staffId} onValueChange={(v) => setGenForm({ ...genForm, staffId: v })}>
                  <SelectTrigger className="w-full"><SelectValue placeholder="اختر الموظف المطابق للدور" /></SelectTrigger>
                  <SelectContent>
                    {eligibleStaff.length === 0 ? (
                      <SelectItem value="_" disabled>لا يوجد موظفون مطابقون</SelectItem>
                    ) : (
                      eligibleStaff.map((s) => (
                        <SelectItem key={s.id} value={s.id}>
                          {s.fullName} — {s.role === 'ADMIN' ? 'إدارة' : s.role === 'MANAGER' ? 'مدير' : 'استقبال'}
                        </SelectItem>
                      ))
                    )}
                  </SelectContent>
                </Select>
                {genForm.staffId && (() => {
                  const st = staff.find((s) => s.id === genForm.staffId)
                  const activeCode = st?.lastCode
                  if (activeCode && activeCode.status === 'ACTIVE') {
                    return (
                      <p className="text-[11px] text-warning leading-relaxed">
                        لدى {st?.fullName} كود فعّال حاليًا (<Ltr className="text-[10px]">{activeCode.codeMasked}</Ltr>) —
                        يُفضل إبطاله بعد تفعيل الكود الجديد لإبقاء كود فعّال واحد.
                      </p>
                    )
                  }
                  return null
                })()}
              </div>
              <div className="space-y-1.5">
                <Label>الصلاحية (أيام)</Label>
                <Select value={genForm.days} onValueChange={(v) => setGenForm({ ...genForm, days: v })}>
                  <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {Array.from({ length: 30 }, (_, i) => i + 1).map((d) => (
                      <SelectItem key={d} value={String(d)}>
                        {d} {d === 1 ? 'يوم' : d === 2 ? 'يومان' : 'أيام'}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                <p className="text-[11px] text-muted-foreground">تنتهي الصلاحية نهاية اليوم الأخير</p>
              </div>
            </div>
          )}

          <DialogFooter className="gap-2">
            {generated ? (
              <>
                <Button variant="outline" onClick={() => setGenOpen(false)}>إغلاق</Button>
                <Button variant="secondary" onClick={generate} disabled={busy} className="gap-2">
                  {busy && <Loader2 className="w-4 h-4 animate-spin" />} توليد آخر
                </Button>
              </>
            ) : (
              <>
                <Button variant="outline" onClick={() => setGenOpen(false)}>إلغاء</Button>
                <Button onClick={generate} disabled={busy || !genForm.staffId} className="gap-2">
                  {busy && <Loader2 className="w-4 h-4 animate-spin" />} توليد الكود
                </Button>
              </>
            )}
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* إبطال كود */}
      <AlertDialog open={!!revokeTarget} onOpenChange={(v) => !v && setRevokeTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>إبطال كود {revokeTarget?.codeMasked}؟</AlertDialogTitle>
            <AlertDialogDescription>
              {revokeTarget?.guestName
                ? `كود ضيف — ${revokeTarget.guestName} (غرفة ${revokeTarget.roomNumber}). سيفقد الضيف وصوله للتطبيق فورًا.`
                : `كود ${revokeTarget?.type === 'ADMIN' ? 'إدارة' : 'استقبال'} — ${revokeTarget?.staffName}. ستنتهي جلساته النشطة فورًا ولن يستطيع الدخول به.`}
              {' '}لن يمكن التراجع عن الإبطال.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>تراجع</AlertDialogCancel>
            <AlertDialogAction onClick={doRevoke} className="bg-destructive text-white hover:bg-destructive/90">
              إبطال الكود
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}

// ─────────────────────── تبويب الطاقم ───────────────────────

function StaffTab() {
  const { data, loading, error, reload } = useLoader<{ staff: StaffAdmin[] }>(() => api('/api/admin/staff'))
  const { busy, run, toast } = useBusyAction()

  const [dialogOpen, setDialogOpen] = useState(false)
  const [editing, setEditing] = useState<StaffAdmin | null>(null)
  const [form, setForm] = useState({ fullName: '', role: 'RECEPTION', phone: '' })

  const staff = data?.staff ?? []

  const openCreate = () => {
    setEditing(null)
    setForm({ fullName: '', role: 'RECEPTION', phone: '' })
    setDialogOpen(true)
  }

  const openEdit = (s: StaffAdmin) => {
    setEditing(s)
    setForm({ fullName: s.fullName, role: s.role, phone: s.phone ?? '' })
    setDialogOpen(true)
  }

  const submit = () =>
    run(async () => {
      if (!form.fullName.trim()) throw new Error('اسم الموظف مطلوب')
      if (editing) {
        await api(`/api/admin/staff/${editing.id}`, {
          method: 'PATCH',
          body: { fullName: form.fullName.trim(), phone: form.phone.trim() },
        })
        toast({ title: 'تم تحديث بيانات الموظف' })
      } else {
        await api('/api/admin/staff', {
          method: 'POST',
          body: { fullName: form.fullName.trim(), role: form.role, phone: form.phone.trim() },
        })
        toast({ title: 'تمت إضافة الموظف', description: 'يمكنك الآن توليد كود دخول له من تبويب الأكواد' })
      }
      setDialogOpen(false)
      await reload()
    })

  const toggleActive = (s: StaffAdmin) =>
    run(async () => {
      await api(`/api/admin/staff/${s.id}`, { method: 'PATCH', body: { active: !s.active } })
      if (s.active) {
        toast({ title: 'تم تعطيل الموظف', description: 'أُبطل كوده النشط وجلساته فورًا' })
      } else {
        toast({ title: 'تم تفعيل الموظف' })
      }
      await reload()
    })

  if (error) {
    return <Card><CardContent><ErrorState message={error} onRetry={reload} /></CardContent></Card>
  }

  return (
    <div className="space-y-3">
      <div className="flex items-center gap-2">
        <span className="text-xs text-muted-foreground">{staff.length} موظف</span>
        <Button onClick={openCreate} className="gap-2 mr-auto" size="sm">
          <Plus className="w-4 h-4" /> إضافة موظف
        </Button>
      </div>

      {loading ? (
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-3">
          {Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-44 rounded-xl" />)}
        </div>
      ) : staff.length === 0 ? (
        <Card><CardContent><EmptyState icon={Users} title="لا يوجد طاقم" /></CardContent></Card>
      ) : (
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-3">
          {staff.map((s) => (
            <Card key={s.id} className={`border-border/60 ${!s.active ? 'opacity-60' : ''}`}>
              <CardContent className="p-4 space-y-3">
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0">
                    <h3 className="font-bold truncate">{s.fullName}</h3>
                    <div className="mt-1"><StaffRoleBadge role={s.role} /></div>
                  </div>
                  <div className="flex items-center gap-1.5 shrink-0">
                    <Switch checked={s.active} onCheckedChange={() => toggleActive(s)} disabled={busy} aria-label={`تفعيل ${s.fullName}`} />
                    <Button variant="ghost" size="icon" className="h-8 w-8" onClick={() => openEdit(s)} aria-label={`تعديل ${s.fullName}`}>
                      <Pencil className="w-4 h-4" />
                    </Button>
                  </div>
                </div>

                {s.phone && (
                  <p className="text-xs text-muted-foreground" dir="ltr" style={{ textAlign: 'end' }}>{s.phone}</p>
                )}

                <div className="rounded-lg bg-muted/50 border p-2.5 space-y-1.5">
                  <p className="text-[11px] text-muted-foreground font-medium">أحدث كود</p>
                  {s.lastCode ? (
                    <div className="flex items-center justify-between gap-2">
                      <Ltr className="text-sm font-bold">{s.lastCode.codeMasked}</Ltr>
                      <div className="flex items-center gap-1.5">
                        <CodeTypeBadge type={s.lastCode.type} />
                        <CodeStatusBadge status={s.lastCode.status} />
                      </div>
                    </div>
                  ) : (
                    <p className="text-xs text-muted-foreground">لا يوجد كود — ولّد واحدًا من تبويب الأكواد</p>
                  )}
                  {s.lastCode && (
                    <p className="text-[10px] text-muted-foreground/70">
                      ينتهي: {formatDateAr(s.lastCode.expiresAt)}
                    </p>
                  )}
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <Dialog open={dialogOpen} onOpenChange={setDialogOpen}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>{editing ? `تعديل: ${editing.fullName}` : 'إضافة موظف'}</DialogTitle>
            <DialogDescription>
              {editing ? 'تعطيل الموظف لاحقًا يبطل كوده النشط وجلساته فورًا' : 'أضف الموظف ثم ولّد له كود دخول'}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-1.5">
              <Label>الاسم الكامل *</Label>
              <Input value={form.fullName} onChange={(e) => setForm({ ...form, fullName: e.target.value })} placeholder="محمد الاستقبال" />
            </div>
            <div className="space-y-1.5">
              <Label>الدور *</Label>
              <Select value={form.role} onValueChange={(v) => setForm({ ...form, role: v })} disabled={!!editing}>
                <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="RECEPTION">استقبال</SelectItem>
                  <SelectItem value="ADMIN">إدارة</SelectItem>
                  <SelectItem value="MANAGER">مدير</SelectItem>
                </SelectContent>
              </Select>
              {editing && <p className="text-[11px] text-muted-foreground">لا يمكن تغيير الدور بعد الإنشاء حفاظًا على الأكواد المرتبطة</p>}
            </div>
            <div className="space-y-1.5">
              <Label>الهاتف</Label>
              <Input value={form.phone} onChange={(e) => setForm({ ...form, phone: e.target.value })} dir="ltr" placeholder="+967…" />
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
    </div>
  )
}
