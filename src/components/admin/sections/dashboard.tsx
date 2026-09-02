'use client'

// ─────────────────────────────────────────────────────────────
// DASHBOARD — لوحة تحكم الإدارة
// ─────────────────────────────────────────────────────────────
import {
  BedDouble, Users, Wallet, ConciergeBell, KeyRound, AlertTriangle, Wrench, ArrowLeft,
} from 'lucide-react'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Progress } from '@/components/ui/progress'
import { Skeleton } from '@/components/ui/skeleton'
import {
  PieChart, Pie, Cell, ResponsiveContainer, Tooltip as RTooltip, AreaChart, Area,
  XAxis, YAxis, CartesianGrid,
} from 'recharts'
import { api } from '@/lib/api-client'
import { formatMoney, formatDateTimeAr, timeAgoAr, ROOM_STATUS_LABELS, RESERVATION_STATUS_LABELS } from '@/lib/format'
import type { DashboardResponse, SectionKey } from '../types'
import { useLoader, KpiCard, EmptyState, ErrorState, ReservationStatusBadge, useChartPalette, roomStatusColors, Ltr, SectionHeader } from '../shared'

export default function DashboardSection({ onNavigate }: { onNavigate: (key: SectionKey) => void }) {
  const { data, loading, error, reload } = useLoader<DashboardResponse>(() => api<DashboardResponse>('/api/admin/dashboard'))
  const palette = useChartPalette()

  if (error) {
    return (
      <Card><CardContent><ErrorState message={error} onRetry={reload} /></CardContent></Card>
    )
  }

  const k = data?.kpis
  const roomsByStatus = data?.roomsByStatus ?? {}
  const pieData = Object.entries(roomsByStatus)
    .filter(([, v]) => v > 0)
    .map(([status, value]) => ({ name: ROOM_STATUS_LABELS[status] ?? status, status, value }))
  const colors = roomStatusColors(palette)

  const revenueData = (data?.revenueByDay ?? []).map((d) => ({
    date: d.date.slice(5), // MM-DD
    total: d.totalCents / 100,
  }))

  return (
    <div className="space-y-4">
      <SectionHeader
        title="لوحة التحكم"
        description="نظرة شاملة على تشغيل الفندق الآن"
        action={
          <Button variant="outline" size="sm" onClick={reload} className="gap-2" disabled={loading}>
            تحديث
          </Button>
        }
      />

      {/* KPIs */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
        <KpiCard
          title="الإشغال"
          icon={BedDouble}
          busy={loading}
          value={<span>{k ? `${k.occupancyPercent}%` : '—'}</span>}
          sub={k ? `${k.occupiedRooms} مشغولة من ${k.totalRooms} غرفة` : undefined}
          progress={k?.occupancyPercent}
        />
        <KpiCard
          title="المقيمون"
          icon={Users}
          busy={loading}
          value={k ? k.inHouseGuests : '—'}
          sub={k ? `${k.inHouseStays} إقامة نشطة · وصول اليوم ${k.arrivalsToday} · مغادرة ${k.departuresToday}` : undefined}
        />
        <KpiCard
          title="إيراد الشهر"
          icon={Wallet}
          tone="gold"
          busy={loading}
          value={k ? formatMoney(k.revenueMonthCents) : '—'}
          sub="مدفوعات مكتملة هذا الشهر"
        />
        <KpiCard
          title="طلبات معلقة"
          icon={ConciergeBell}
          tone={k && k.urgentRequests > 0 ? 'danger' : 'default'}
          busy={loading}
          value={k ? k.pendingRequests : '—'}
          sub={k ? (k.urgentRequests > 0 ? `عاجل: ${k.urgentRequests} ⚠` : 'لا توجد طلبات عاجلة') : undefined}
        />
      </div>

      {/* الرسوم */}
      <div className="grid lg:grid-cols-5 gap-3">
        {/* حالة الغرف — دائري */}
        <Card className="lg:col-span-2 border-border/60">
          <CardHeader className="pb-2">
            <CardTitle className="text-base">حالة الغرف</CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <Skeleton className="h-56 w-full" />
            ) : pieData.length === 0 ? (
              <EmptyState title="لا توجد غرف" />
            ) : (
              <div dir="ltr" className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={pieData}
                      dataKey="value"
                      nameKey="name"
                      cx="50%"
                      cy="50%"
                      innerRadius={48}
                      outerRadius={72}
                      paddingAngle={3}
                      strokeWidth={0}
                    >
                      {pieData.map((entry) => (
                        <Cell key={entry.status} fill={colors[entry.status] ?? palette.gray} />
                      ))}
                    </Pie>
                    <RTooltip
                      content={({ active, payload }) => {
                        if (!active || !payload?.length) return null
                        const p = payload[0]
                        return (
                          <div className="rounded-md border bg-popover px-3 py-1.5 text-xs shadow-md" dir="rtl">
                            {p.name}: <b>{p.value}</b> غرفة
                          </div>
                        )
                      }}
                    />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            )}
            <div className="grid grid-cols-2 gap-x-3 gap-y-1.5 mt-2">
              {Object.entries(roomsByStatus).map(([status, count]) => (
                <div key={status} className="flex items-center gap-2 text-xs">
                  <span className="w-2.5 h-2.5 rounded-full shrink-0" style={{ background: colors[status] ?? palette.gray }} />
                  <span className="text-muted-foreground">{ROOM_STATUS_LABELS[status] ?? status}</span>
                  <span className="font-bold tabular-nums mr-auto">{count}</span>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        {/* الإيراد اليومي */}
        <Card className="lg:col-span-3 border-border/60">
          <CardHeader className="pb-2">
            <CardTitle className="text-base">الإيراد اليومي (آخر 14 يومًا)</CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <Skeleton className="h-56 w-full" />
            ) : (
              <div dir="ltr" className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <AreaChart data={revenueData} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
                    <defs>
                      <linearGradient id="revGradient" x1="0" y1="0" x2="0" y2="1">
                        <stop offset="0%" stopColor={palette.gold} stopOpacity={0.45} />
                        <stop offset="100%" stopColor={palette.gold} stopOpacity={0.05} />
                      </linearGradient>
                    </defs>
                    <CartesianGrid strokeDasharray="3 3" stroke="currentColor" opacity={0.12} vertical={false} />
                    <XAxis dataKey="date" tick={{ fontSize: 10 }} tickLine={false} axisLine={false} interval="preserveStartEnd" />
                    <YAxis tick={{ fontSize: 10 }} tickLine={false} axisLine={false} width={42} tickFormatter={(v: number) => `$${v}`} />
                    <RTooltip
                      content={({ active, payload, label }) => {
                        if (!active || !payload?.length) return null
                        return (
                          <div className="rounded-md border bg-popover px-3 py-1.5 text-xs shadow-md" dir="rtl">
                            <p className="text-muted-foreground">{label}</p>
                            <p className="font-bold">{formatMoney(Math.round((payload[0].value as number) * 100))}</p>
                          </div>
                        )
                      }}
                    />
                    <Area type="monotone" dataKey="total" stroke={palette.gold} strokeWidth={2} fill="url(#revGradient)" name="الإيراد" />
                  </AreaChart>
                </ResponsiveContainer>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* أحدث الحجوزات + الجانب */}
      <div className="grid lg:grid-cols-3 gap-3">
        <Card className="lg:col-span-2 border-border/60 overflow-hidden">
          <CardHeader className="pb-2">
            <CardTitle className="text-base">أحدث الحجوزات</CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            {loading ? (
              <div className="space-y-2 p-4">
                {Array.from({ length: 4 }).map((_, i) => <Skeleton key={i} className="h-10" />)}
              </div>
            ) : !data || data.recentBookings.length === 0 ? (
              <EmptyState title="لا توجد حجوزات بعد" />
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm min-w-[560px]">
                  <thead>
                    <tr className="border-b text-xs text-muted-foreground">
                      <th className="text-start font-medium px-4 py-2">المرجع</th>
                      <th className="text-start font-medium px-2 py-2">الضيف</th>
                      <th className="text-start font-medium px-2 py-2">النوع</th>
                      <th className="text-start font-medium px-2 py-2">الإجمالي</th>
                      <th className="text-start font-medium px-2 py-2">الحالة</th>
                      <th className="text-start font-medium px-4 py-2">أُنشئ</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.recentBookings.map((b) => (
                      <tr key={b.id} className="border-b last:border-0 hover:bg-accent/50 transition-colors">
                        <td className="px-4 py-2.5"><Ltr className="text-xs font-bold text-primary">{b.reference}</Ltr></td>
                        <td className="px-2 py-2.5 font-medium">{b.guestName}</td>
                        <td className="px-2 py-2.5 text-muted-foreground text-xs">{b.roomTypeName}</td>
                        <td className="px-2 py-2.5 font-bold tabular-nums">{formatMoney(b.grandTotalCents)}</td>
                        <td className="px-2 py-2.5">
                          <ReservationStatusBadge status={b.status} />
                        </td>
                        <td className="px-4 py-2.5 text-xs text-muted-foreground" title={formatDateTimeAr(b.createdAt)}>
                          {timeAgoAr(b.createdAt)}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </CardContent>
        </Card>

        <div className="space-y-3">
          {/* تنبيهات */}
          <Card className="border-border/60">
            <CardHeader className="pb-2">
              <CardTitle className="text-base flex items-center gap-2">
                <AlertTriangle className="w-4 h-4 text-warning" /> تنبيهات
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-2.5">
              {loading ? (
                <Skeleton className="h-16" />
              ) : (
                <>
                  <AlertRow
                    icon={<ConciergeBell className="w-4 h-4" />}
                    tone={data && data.alerts.staleRequests > 0 ? 'amber' : 'muted'}
                    text={data && data.alerts.staleRequests > 0 ? `${data.alerts.staleRequests} طلب معلّق منذ أكثر من 30 دقيقة` : 'لا توجد طلبات متأخرة'}
                  />
                  <AlertRow
                    icon={<Wrench className="w-4 h-4" />}
                    tone={data && data.alerts.outOfOrderRooms > 0 ? 'muted' : 'muted'}
                    text={data && data.alerts.outOfOrderRooms > 0 ? `${data.alerts.outOfOrderRooms} غرفة خارج الخدمة` : 'كل الغرف فعّالة'}
                  />
                </>
              )}
            </CardContent>
          </Card>

          {/* الأكواد النشطة */}
          <Card className="border-border/60">
            <CardHeader className="pb-2">
              <CardTitle className="text-base flex items-center gap-2">
                <KeyRound className="w-4 h-4 text-gold" /> الأكواد النشطة
              </CardTitle>
            </CardHeader>
            <CardContent>
              {loading ? (
                <Skeleton className="h-14" />
              ) : (
                <>
                  <div className="flex items-center justify-between text-sm py-1">
                    <span className="text-muted-foreground">أكواد ضيوف</span>
                    <span className="font-extrabold tabular-nums">{k?.activeGuestCodes ?? 0}</span>
                  </div>
                  <div className="flex items-center justify-between text-sm py-1 border-t">
                    <span className="text-muted-foreground">أكواد طاقم</span>
                    <span className="font-extrabold tabular-nums">{k?.activeStaffCodes ?? 0}</span>
                  </div>
                  <Button
                    variant="secondary"
                    size="sm"
                    className="w-full mt-3 gap-1.5"
                    onClick={() => onNavigate('staff')}
                  >
                    توليد كود <ArrowLeft className="w-3.5 h-3.5" />
                  </Button>
                </>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  )
}

function AlertRow({ icon, text, tone }: { icon: React.ReactNode; text: string; tone: 'amber' | 'muted' }) {
  return (
    <div className={`flex items-center gap-2.5 rounded-lg border p-2.5 text-xs ${tone === 'amber' ? 'border-warning/40 bg-warning/10 text-[#a16207] dark:text-warning' : 'border-border bg-muted/40 text-muted-foreground'}`}>
      <span className="shrink-0">{icon}</span>
      <span className="leading-relaxed">{text}</span>
    </div>
  )
}
