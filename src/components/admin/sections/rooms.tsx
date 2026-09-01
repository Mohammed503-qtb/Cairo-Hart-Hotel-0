'use client'

// ─────────────────────────────────────────────────────────────
// ROOMS — الغرف الفعلية (فلاتر + جدول + إدارة كاملة)
// ─────────────────────────────────────────────────────────────
import { useMemo, useState } from 'react'
import { Plus, Pencil, Trash2, Loader2, MoreVertical, User, DoorOpen } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Textarea } from '@/components/ui/textarea'
import { Skeleton } from '@/components/ui/skeleton'
import {
  Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle,
} from '@/components/ui/dialog'
import {
  AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription,
  AlertDialogFooter, AlertDialogHeader, AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import {
  DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuLabel,
  DropdownMenuSeparator, DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import {
  Select, SelectContent, SelectItem, SelectTrigger, SelectValue,
} from '@/components/ui/select'
import { api } from '@/lib/api-client'
import { formatDateAr, ROOM_STATUS_LABELS } from '@/lib/format'
import type { RoomAdmin, RoomTypeAdmin } from '../types'
import { useLoader, ErrorState, useBusyAction, EmptyState, SectionHeader, RoomStatusBadge, Ltr, TableSkeleton } from '../shared'

const QUICK_STATUSES = [
  { value: 'AVAILABLE', label: 'متاحة' },
  { value: 'CLEANING', label: 'تنظيف جارٍ' },
  { value: 'DIRTY', label: 'تحتاج تنظيف' },
  { value: 'OUT_OF_ORDER', label: 'خارج الخدمة' },
]

const EDITABLE_STATUSES = [
  { value: 'AVAILABLE', label: 'متاحة' },
  { value: 'RESERVED', label: 'محجوزة' },
  { value: 'CLEANING', label: 'تنظيف جارٍ' },
  { value: 'DIRTY', label: 'تحتاج تنظيف' },
  { value: 'OUT_OF_ORDER', label: 'خارج الخدمة' },
]

export default function RoomsSection() {
  const { data, loading, error, reload } = useLoader<{ rooms: RoomAdmin[] }>(() => api('/api/admin/rooms'))
  const { data: typesData } = useLoader<{ roomTypes: RoomTypeAdmin[] }>(() => api('/api/admin/room-types'))
  const { busy, run, toast } = useBusyAction()

  const [floorFilter, setFloorFilter] = useState('all')
  const [statusFilter, setStatusFilter] = useState('all')
  const [typeFilter, setTypeFilter] = useState('all')

  const [createOpen, setCreateOpen] = useState(false)
  const [createForm, setCreateForm] = useState({ number: '', floor: '1', roomTypeId: '' })
  const [editTarget, setEditTarget] = useState<RoomAdmin | null>(null)
  const [editForm, setEditForm] = useState({ floor: '', roomTypeId: '', status: '', notes: '' })
  const [deleteTarget, setDeleteTarget] = useState<RoomAdmin | null>(null)

  const rooms = data?.rooms ?? []
  const types = typesData?.roomTypes ?? []
  const floors = useMemo(() => Array.from(new Set(rooms.map((r) => r.floor))).sort((a, b) => a - b), [rooms])

  const filtered = rooms.filter(
    (r) =>
      (floorFilter === 'all' || String(r.floor) === floorFilter) &&
      (statusFilter === 'all' || r.status === statusFilter) &&
      (typeFilter === 'all' || r.roomTypeId === typeFilter)
  )

  const openEdit = (r: RoomAdmin) => {
    setEditTarget(r)
    setEditForm({ floor: String(r.floor), roomTypeId: r.roomTypeId, status: r.status, notes: r.notes ?? '' })
  }

  const create = () =>
    run(async () => {
      if (!createForm.number.trim()) throw new Error('رقم الغرفة مطلوب')
      if (!createForm.roomTypeId) throw new Error('اختر نوع الغرفة')
      await api('/api/admin/rooms', {
        method: 'POST',
        body: {
          number: createForm.number.trim(),
          floor: parseInt(createForm.floor, 10) || 1,
          roomTypeId: createForm.roomTypeId,
        },
      })
      toast({ title: `تمت إضافة الغرفة ${createForm.number.trim()}` })
      setCreateOpen(false)
      setCreateForm({ number: '', floor: '1', roomTypeId: '' })
      await reload()
    })

  const saveEdit = () =>
    run(async () => {
      if (!editTarget) return
      await api(`/api/admin/rooms/${editTarget.id}`, {
        method: 'PATCH',
        body: {
          floor: parseInt(editForm.floor, 10) || 1,
          roomTypeId: editForm.roomTypeId,
          status: editForm.status,
          notes: editForm.notes,
        },
      })
      toast({ title: `تم تحديث الغرفة ${editTarget.number}` })
      setEditTarget(null)
      await reload()
    })

  const quickStatus = (r: RoomAdmin, status: string) =>
    run(async () => {
      await api(`/api/admin/rooms/${r.id}`, { method: 'PATCH', body: { status } })
      toast({ title: `الغرفة ${r.number} → ${ROOM_STATUS_LABELS[status]}` })
      await reload()
    })

  const doDelete = () =>
    run(async () => {
      if (!deleteTarget) return
      const res = await api<{ deleted?: boolean; message?: string }>(`/api/admin/rooms/${deleteTarget.id}`, { method: 'DELETE' })
      toast({ title: res.message ?? 'تم حذف الغرفة' })
      setDeleteTarget(null)
      await reload()
    })

  if (error) {
    return <Card><CardContent><ErrorState message={error} onRetry={reload} /></CardContent></Card>
  }

  return (
    <div className="space-y-4">
      <SectionHeader
        title="الغرف"
        description={`${rooms.length} غرفة — ${rooms.filter((r) => r.status === 'OCCUPIED').length} مشغولة · ${rooms.filter((r) => r.status === 'OUT_OF_ORDER').length} خارج الخدمة`}
        action={
          <Button onClick={() => setCreateOpen(true)} className="gap-2" size="sm">
            <Plus className="w-4 h-4" /> إضافة غرفة
          </Button>
        }
      />

      {/* الفلاتر */}
      <div className="grid grid-cols-3 gap-2">
        <Select value={floorFilter} onValueChange={setFloorFilter}>
          <SelectTrigger className="w-full" size="sm"><SelectValue placeholder="كل الطوابق" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">كل الطوابق</SelectItem>
            {floors.map((f) => (
              <SelectItem key={f} value={String(f)}>الطابق {f}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={statusFilter} onValueChange={setStatusFilter}>
          <SelectTrigger className="w-full" size="sm"><SelectValue placeholder="كل الحالات" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">كل الحالات</SelectItem>
            {Object.entries(ROOM_STATUS_LABELS).map(([v, l]) => (
              <SelectItem key={v} value={v}>{l}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <Select value={typeFilter} onValueChange={setTypeFilter}>
          <SelectTrigger className="w-full" size="sm"><SelectValue placeholder="كل الأنواع" /></SelectTrigger>
          <SelectContent>
            <SelectItem value="all">كل الأنواع</SelectItem>
            {types.map((t) => (
              <SelectItem key={t.id} value={t.id}>{t.name}</SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      <Card className="border-border/60 overflow-hidden">
        <CardContent className="p-0">
          {loading ? (
            <TableSkeleton rows={7} cols={6} />
          ) : filtered.length === 0 ? (
            <EmptyState icon={DoorOpen} title="لا توجد غرف مطابقة" description="غيّر الفلاتر أو أضف غرفة جديدة" />
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-sm min-w-[720px]">
                <thead>
                  <tr className="border-b text-xs text-muted-foreground bg-muted/40">
                    <th className="text-start font-medium px-4 py-2.5">الغرفة</th>
                    <th className="text-start font-medium px-2 py-2.5">الطابق</th>
                    <th className="text-start font-medium px-2 py-2.5">النوع</th>
                    <th className="text-start font-medium px-2 py-2.5">الحالة</th>
                    <th className="text-start font-medium px-2 py-2.5">الضيف الحالي</th>
                    <th className="text-start font-medium px-2 py-2.5">ملاحظات</th>
                    <th className="text-start font-medium px-4 py-2.5 w-14"></th>
                  </tr>
                </thead>
                <tbody>
                  {filtered.map((r) => (
                    <tr key={r.id} className="border-b last:border-0 hover:bg-accent/50 transition-colors">
                      <td className="px-4 py-3">
                        <Ltr className="text-base font-extrabold text-primary">{r.number}</Ltr>
                      </td>
                      <td className="px-2 py-3 text-muted-foreground tabular-nums">{r.floor}</td>
                      <td className="px-2 py-3 text-muted-foreground">{r.roomTypeName}</td>
                      <td className="px-2 py-3"><RoomStatusBadge status={r.status} /></td>
                      <td className="px-2 py-3">
                        {r.guestName ? (
                          <div className="flex items-center gap-1.5">
                            <User className="w-3.5 h-3.5 text-muted-foreground shrink-0" />
                            <div className="min-w-0">
                              <p className="font-medium truncate">{r.guestName}</p>
                              {r.expectedCheckOut && (
                                <p className="text-[10px] text-muted-foreground">خروج: {formatDateAr(r.expectedCheckOut)}</p>
                              )}
                            </div>
                          </div>
                        ) : (
                          <span className="text-muted-foreground text-xs">—</span>
                        )}
                      </td>
                      <td className="px-2 py-3 text-xs text-muted-foreground max-w-40 truncate" title={r.notes ?? ''}>
                        {r.notes || '—'}
                      </td>
                      <td className="px-4 py-3">
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="icon" className="h-8 w-8" aria-label={`إجراءات الغرفة ${r.number}`}>
                              <MoreVertical className="w-4 h-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end" className="w-44">
                            <DropdownMenuLabel>تبديل سريع للحالة</DropdownMenuLabel>
                            {QUICK_STATUSES.map((s) => (
                              <DropdownMenuItem
                                key={s.value}
                                disabled={busy || r.status === s.value}
                                onClick={() => quickStatus(r, s.value)}
                              >
                                {s.label}
                              </DropdownMenuItem>
                            ))}
                            <DropdownMenuSeparator />
                            <DropdownMenuItem onClick={() => openEdit(r)}>
                              <Pencil className="w-3.5 h-3.5 ml-1.5" /> تعديل الغرفة
                            </DropdownMenuItem>
                            <DropdownMenuItem className="text-destructive" onClick={() => setDeleteTarget(r)}>
                              <Trash2 className="w-3.5 h-3.5 ml-1.5" /> حذف
                            </DropdownMenuItem>
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* إضافة غرفة */}
      <Dialog open={createOpen} onOpenChange={setCreateOpen}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>إضافة غرفة</DialogTitle>
            <DialogDescription>غرفة فعلية جديدة — تبدأ بحالة «متاحة»</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-1.5">
              <Label>رقم الغرفة *</Label>
              <Input value={createForm.number} onChange={(e) => setCreateForm({ ...createForm, number: e.target.value })} placeholder="107" dir="ltr" />
            </div>
            <div className="space-y-1.5">
              <Label>الطابق (1-30)</Label>
              <Input type="number" min={1} max={30} value={createForm.floor} onChange={(e) => setCreateForm({ ...createForm, floor: e.target.value })} dir="ltr" />
            </div>
            <div className="space-y-1.5">
              <Label>نوع الغرفة *</Label>
              <Select value={createForm.roomTypeId} onValueChange={(v) => setCreateForm({ ...createForm, roomTypeId: v })}>
                <SelectTrigger className="w-full"><SelectValue placeholder="اختر النوع" /></SelectTrigger>
                <SelectContent>
                  {types.map((t) => (
                    <SelectItem key={t.id} value={t.id}>{t.name} — {t.roomsCount} غرفة</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setCreateOpen(false)}>إلغاء</Button>
            <Button onClick={create} disabled={busy} className="gap-2">
              {busy && <Loader2 className="w-4 h-4 animate-spin" />} إضافة
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* تعديل غرفة */}
      <Dialog open={!!editTarget} onOpenChange={(v) => !v && setEditTarget(null)}>
        <DialogContent className="max-w-sm">
          <DialogHeader>
            <DialogTitle>تعديل الغرفة {editTarget?.number}</DialogTitle>
            <DialogDescription>لا يمكن ضبط «مشغولة» يدويًا — الحجز يتم عبر تسجيل الوصول</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="space-y-1.5">
              <Label>الطابق</Label>
              <Input type="number" min={1} max={30} value={editForm.floor} onChange={(e) => setEditForm({ ...editForm, floor: e.target.value })} dir="ltr" />
            </div>
            <div className="space-y-1.5">
              <Label>نوع الغرفة</Label>
              <Select value={editForm.roomTypeId} onValueChange={(v) => setEditForm({ ...editForm, roomTypeId: v })}>
                <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                <SelectContent>
                  {types.map((t) => (
                    <SelectItem key={t.id} value={t.id}>{t.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label>الحالة</Label>
              <Select value={editForm.status} onValueChange={(v) => setEditForm({ ...editForm, status: v })}>
                <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
                <SelectContent>
                  {EDITABLE_STATUSES.map((s) => (
                    <SelectItem key={s.value} value={s.value}>{s.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
              {editTarget?.status === 'OCCUPIED' && (
                <p className="text-[11px] text-muted-foreground leading-relaxed">
                  الغرفة مشغولة حاليًا بتسجيل وصول — تغيير الحالة تجاوز إداري.
                </p>
              )}
            </div>
            <div className="space-y-1.5">
              <Label>ملاحظات</Label>
              <Textarea value={editForm.notes} onChange={(e) => setEditForm({ ...editForm, notes: e.target.value })} rows={2} placeholder="صيانة تكييف…" />
            </div>
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setEditTarget(null)}>إلغاء</Button>
            <Button onClick={saveEdit} disabled={busy} className="gap-2">
              {busy && <Loader2 className="w-4 h-4 animate-spin" />} حفظ
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* حذف محمي */}
      <AlertDialog open={!!deleteTarget} onOpenChange={(v) => !v && setDeleteTarget(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>حذف الغرفة {deleteTarget?.number}؟</AlertDialogTitle>
            <AlertDialogDescription>
              الحذف نهائي ولا يتاح إلا للغرف <b>بدون أي سجل إقامات</b>. إن كانت الغرفة لها تاريخ إقامات
              فاستخدم حالة «خارج الخدمة» بدلًا من الحذف للحفاظ على السجلات.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>تراجع</AlertDialogCancel>
            <AlertDialogAction onClick={doDelete} className="bg-destructive text-white hover:bg-destructive/90">
              حذف نهائي
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
