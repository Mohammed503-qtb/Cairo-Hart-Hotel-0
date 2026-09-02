'use client'

// ─────────────────────────────────────────────────────────────
// AUDIT LOG — سجل التدقيق (فلاتر + بحث + صفحات + تفاصيل JSON)
// ─────────────────────────────────────────────────────────────
import { useState } from 'react'
import { Search, ScrollText, X, FileJson } from 'lucide-react'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { api } from '@/lib/api-client'
import { formatDateTimeAr } from '@/lib/format'
import type { Paginated, AuditItem } from '../types'
import { useLoader, ErrorState, EmptyState, SectionHeader, Ltr, TableSkeleton, Pager, AuditRoleBadge } from '../shared'

const AUDIT_ACTIONS: Array<{ value: string; label: string }> = [
  { value: 'RESERVATION_CREATED', label: 'إنشاء حجز' },
  { value: 'RESERVATION_CONFIRMED', label: 'تأكيد حجز' },
  { value: 'RESERVATION_CANCELLED', label: 'إلغاء حجز' },
  { value: 'CHECK_IN', label: 'تسجيل وصول' },
  { value: 'CHECK_OUT', label: 'تسجيل خروج' },
  { value: 'ROOM_ASSIGNED', label: 'إسناد غرفة' },
  { value: 'ROOM_CHANGED', label: 'تعديل غرفة' },
  { value: 'ROOM_TYPE_CHANGED', label: 'تعديل نوع غرفة' },
  { value: 'RATE_CHANGED', label: 'تعديل معدل سعر' },
  { value: 'SETTINGS_UPDATED', label: 'تحديث الإعدادات' },
  { value: 'SERVICE_CATALOG_CHANGED', label: 'تعديل كتالوج الخدمات' },
  { value: 'STAFF_CHANGED', label: 'تعديل الطاقم' },
  { value: 'CODE_GENERATED', label: 'توليد كود' },
  { value: 'CODE_REVOKED', label: 'إبطال كود' },
  { value: 'CODE_LOGIN', label: 'دخول بكود' },
  { value: 'CODE_LOGIN_FAILED', label: 'محاولة دخول فاشلة' },
  { value: 'PAYMENT_RECORDED', label: 'تسجيل دفعة' },
  { value: 'REQUEST_CREATED', label: 'إنشاء طلب' },
  { value: 'REQUEST_UPDATED', label: 'تحديث طلب' },
  { value: 'EXTENSION_REQUESTED', label: 'طلب تمديد' },
  { value: 'EXTENSION_APPROVED', label: 'قبول تمديد' },
  { value: 'CHAT_MESSAGE', label: 'رسالة محادثة' },
  { value: 'CHARGE_ADDED', label: 'إضافة بند فاتورة' },
  { value: 'CHECKOUT_REQUESTED', label: 'طلب خروج' },
]

const ROLE_LABELS: Record<string, string> = {
  WEBSITE: 'الموقع', RECEPTION: 'الاستقبال', GUEST: 'ضيف', ADMIN: 'الإدارة', SYSTEM: 'النظام',
}

const ACTION_LABEL_MAP = Object.fromEntries(AUDIT_ACTIONS.map((a) => [a.value, a.label]))

export default function AuditLogSection() {
  const [action, setAction] = useState('all')
  const [q, setQ] = useState('')
  const [query, setQuery] = useState('')
  const [page, setPage] = useState(1)

  const { data, loading, error, reload } = useLoader<Paginated<AuditItem>>(
    () => api(`/api/admin/audit?action=${action === 'all' ? '' : action}&q=${encodeURIComponent(query)}&page=${page}`),
    [action, query, page]
  )

  const items = data?.items ?? []

  const search = () => {
    setPage(1)
    setQuery(q.trim())
  }

  return (
    <div className="space-y-4">
      <SectionHeader title="سجل التدقيق" description={`${data?.total ?? 0} حدث — كل العمليات الحساسة مسجلة`} />

      <div className="flex flex-wrap items-center gap-2">
        <Select value={action} onValueChange={(v) => { setAction(v); setPage(1) }}>
          <SelectTrigger size="sm" className="w-44"><SelectValue placeholder="كل الأفعال" /></SelectTrigger>
          <SelectContent className="max-h-72">
            <SelectItem value="all">كل الأفعال</SelectItem>
            {AUDIT_ACTIONS.map((a) => (
              <SelectItem key={a.value} value={a.value}>{a.label}</SelectItem>
            ))}
          </SelectContent>
        </Select>
        <div className="relative flex-1 min-w-44 max-w-xs">
          <Search className="absolute right-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
          <Input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && search()}
            placeholder="الفاعل / الكيان / المعرّف…"
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
        <Button variant="ghost" size="sm" onClick={reload} className="mr-auto gap-1.5">تحديث</Button>
      </div>

      <Card className="border-border/60 overflow-hidden">
        <CardContent className="p-0">
          {loading ? (
            <TableSkeleton rows={10} cols={5} />
          ) : error ? (
            <ErrorState message={error} onRetry={reload} />
          ) : items.length === 0 ? (
            <EmptyState icon={ScrollText} title="لا توجد أحداث مطابقة" />
          ) : (
            <>
              <div className="overflow-x-auto">
                <table className="w-full text-sm min-w-[760px]">
                  <thead>
                    <tr className="border-b text-xs text-muted-foreground bg-muted/40">
                      <th className="text-start font-medium px-4 py-2.5">الوقت</th>
                      <th className="text-start font-medium px-2 py-2.5">الفعل</th>
                      <th className="text-start font-medium px-2 py-2.5">الفاعل</th>
                      <th className="text-start font-medium px-2 py-2.5">الكيان</th>
                      <th className="text-start font-medium px-4 py-2.5">التفاصيل</th>
                    </tr>
                  </thead>
                  <tbody>
                    {items.map((l) => (
                      <tr key={l.id} className="border-b last:border-0 hover:bg-accent/50 transition-colors">
                        <td className="px-4 py-3 text-xs text-muted-foreground whitespace-nowrap">{formatDateTimeAr(l.createdAt)}</td>
                        <td className="px-2 py-3">
                          <AuditRoleBadge role={l.actorRole} label={ACTION_LABEL_MAP[l.action] ?? l.action} />
                        </td>
                        <td className="px-2 py-3">
                          <p className="text-xs font-medium">{l.actor}</p>
                          <p className="text-[10px] text-muted-foreground">{ROLE_LABELS[l.actorRole] ?? l.actorRole}</p>
                        </td>
                        <td className="px-2 py-3">
                          <p className="text-xs">{l.entityType}</p>
                          <Ltr className="text-[10px] text-muted-foreground">{l.entityId.slice(0, 14)}{l.entityId.length > 14 ? '…' : ''}</Ltr>
                        </td>
                        <td className="px-4 py-3">
                          <Popover>
                            <PopoverTrigger asChild>
                              <Button variant="ghost" size="sm" className="h-7 gap-1.5 text-xs">
                                <FileJson className="w-3.5 h-3.5" /> عرض
                              </Button>
                            </PopoverTrigger>
                            <PopoverContent side="left" className="w-80 max-h-72 overflow-auto" dir="ltr">
                              <pre className="text-[10px] leading-relaxed font-mono whitespace-pre-wrap break-all">
                                {formatDetails(l.details)}
                              </pre>
                            </PopoverContent>
                          </Popover>
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
    </div>
  )
}

function formatDetails(raw: string): string {
  try {
    const obj = JSON.parse(raw)
    return JSON.stringify(obj, null, 2)
  } catch {
    return raw
  }
}
