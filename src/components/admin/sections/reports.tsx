'use client'

// ─────────────────────────────────────────────────────────────
// REPORTS — التقارير (إشغال / إيراد / طلبات / جنسيات)
// ─────────────────────────────────────────────────────────────
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Progress } from '@/components/ui/progress'
import {
  ResponsiveContainer, LineChart, Line, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, CartesianGrid, Tooltip as RTooltip, Legend,
} from 'recharts'
import { api } from '@/lib/api-client'
import { formatMoney, REQUEST_STATUS_LABELS } from '@/lib/format'
import type { ReportsResponse } from '../types'
import { useLoader, ErrorState, EmptyState, useChartPalette } from '../shared'

export default function ReportsSection() {
  const { data, loading, error, reload } = useLoader<ReportsResponse>(() => api('/api/admin/reports'))
  const palette = useChartPalette()

  if (error) {
    return <Card><CardContent><ErrorState message={error} onRetry={reload} /></CardContent></Card>
  }

  const occupancy = (data?.occupancyLast14Days ?? []).map((d) => ({ label: d.label, percent: d.percent }))
  const revenue = (data?.revenueByMonth ?? []).map((m) => ({ month: m.month, total: m.totalCents / 100 }))
  const requestsStats = data?.requestsStats
  const statusPie = (requestsStats?.byStatus ?? []).map((s) => ({
    name: REQUEST_STATUS_LABELS[s.status] ?? s.status,
    value: s.count,
  }))
  const statusColors = [palette.gray, palette.gold, palette.coral, palette.primary, palette.warning, palette.success, palette.coral, palette.gray]
  const topServices = requestsStats?.topServices ?? []
  const maxServiceCount = topServices.length > 0 ? Math.max(...topServices.map((s) => s.count)) : 0
  const nationalities = data?.guestsByNationality ?? []
  const maxNat = nationalities.length > 0 ? Math.max(...nationalities.map((n) => n.count)) : 0

  return (
    <div className="space-y-4">
      <div>
        <h2 className="text-xl font-extrabold text-primary mb-0.5">التقارير</h2>
        <p className="text-sm text-muted-foreground">مؤشرات الأداء التشغيلي والمالي</p>
      </div>

      {/* الإشغال + الإيراد */}
      <div className="grid lg:grid-cols-2 gap-3">
        <Card className="border-border/60">
          <CardHeader className="pb-2">
            <CardTitle className="text-base">نسبة الإشغال — آخر 14 يومًا</CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <Skeleton className="h-56 w-full" />
            ) : occupancy.length === 0 ? (
              <EmptyState title="لا توجد بيانات" />
            ) : (
              <div dir="ltr" className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={occupancy} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="currentColor" opacity={0.12} vertical={false} />
                    <XAxis dataKey="label" tick={{ fontSize: 9 }} tickLine={false} axisLine={false} interval="preserveStartEnd" />
                    <YAxis tick={{ fontSize: 10 }} tickLine={false} axisLine={false} width={36} domain={[0, 100]} tickFormatter={(v: number) => `${v}%`} />
                    <RTooltip
                      content={({ active, payload, label }) => {
                        if (!active || !payload?.length) return null
                        return (
                          <div className="rounded-md border bg-popover px-3 py-1.5 text-xs shadow-md" dir="rtl">
                            <p className="text-muted-foreground">{label}</p>
                            <p className="font-bold">{payload[0].value}% إشغال</p>
                          </div>
                        )
                      }}
                    />
                    <Line type="monotone" dataKey="percent" stroke={palette.primary} strokeWidth={2.5} dot={false} activeDot={{ r: 4 }} name="الإشغال" />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            )}
            {data && (
              <p className="text-xs text-muted-foreground mt-1">
                المحسوبة على {data.effectiveRooms} غرفة فعّالة (بدون خارج الخدمة)
              </p>
            )}
          </CardContent>
        </Card>

        <Card className="border-border/60">
          <CardHeader className="pb-2">
            <CardTitle className="text-base">الإيراد — آخر 6 أشهر</CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <Skeleton className="h-56 w-full" />
            ) : revenue.length === 0 ? (
              <EmptyState title="لا توجد بيانات" />
            ) : (
              <div dir="ltr" className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={revenue} margin={{ top: 8, right: 8, left: 0, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="currentColor" opacity={0.12} vertical={false} />
                    <XAxis dataKey="month" tick={{ fontSize: 10 }} tickLine={false} axisLine={false} />
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
                    <Bar dataKey="total" fill={palette.gold} radius={[6, 6, 0, 0]} name="الإيراد" maxBarSize={44} />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* الطلبات + الجنسيات */}
      <div className="grid lg:grid-cols-2 gap-3">
        <Card className="border-border/60">
          <CardHeader className="pb-2">
            <CardTitle className="text-base">طلبات الخدمة</CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <Skeleton className="h-48 w-full" />
            ) : !requestsStats || requestsStats.total === 0 ? (
              <EmptyState title="لا توجد طلبات" />
            ) : (
              <>
                <div className="grid grid-cols-4 gap-2 mb-4">
                  <StatBox label="الإجمالي" value={requestsStats.total} />
                  <StatBox label="مكتمل" value={requestsStats.completed} tone="success" />
                  <StatBox label="نشط" value={requestsStats.active} tone="gold" />
                  <StatBox
                    label="متوسط الإنجاز"
                    value={requestsStats.avgCompletionMinutes !== null ? `${requestsStats.avgCompletionMinutes}د` : '—'}
                  />
                </div>

                <div className="grid grid-cols-2 gap-3 items-center">
                  <div dir="ltr" className="h-40">
                    <ResponsiveContainer width="100%" height="100%">
                      <PieChart>
                        <Pie data={statusPie} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={56} strokeWidth={0}>
                          {statusPie.map((entry, i) => (
                            <Cell key={entry.name} fill={statusColors[i % statusColors.length]} />
                          ))}
                        </Pie>
                        <Legend wrapperStyle={{ fontSize: 10, direction: 'rtl' }} iconSize={8} />
                        <RTooltip
                          content={({ active, payload }) => {
                            if (!active || !payload?.length) return null
                            return (
                              <div className="rounded-md border bg-popover px-3 py-1.5 text-xs shadow-md" dir="rtl">
                                {payload[0].name}: <b>{payload[0].value}</b>
                              </div>
                            )
                          }}
                        />
                      </PieChart>
                    </ResponsiveContainer>
                  </div>

                  <div className="space-y-2.5">
                    <p className="text-xs font-bold text-muted-foreground">أكثر الخدمات طلبًا</p>
                    {topServices.map((s) => (
                      <div key={s.title}>
                        <div className="flex items-center justify-between text-xs mb-1">
                          <span className="truncate">{s.title}</span>
                          <span className="font-bold tabular-nums shrink-0 mr-2">{s.count}</span>
                        </div>
                        <Progress value={maxServiceCount > 0 ? (s.count / maxServiceCount) * 100 : 0} className="h-1.5" />
                      </div>
                    ))}
                  </div>
                </div>
              </>
            )}
          </CardContent>
        </Card>

        <Card className="border-border/60">
          <CardHeader className="pb-2">
            <CardTitle className="text-base">الضيوف حسب الجنسية (أعلى 5)</CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <Skeleton className="h-48 w-full" />
            ) : nationalities.length === 0 ? (
              <EmptyState title="لا يوجد ضيوف" />
            ) : (
              <div className="space-y-3.5">
                {nationalities.map((n) => (
                  <div key={n.nationality}>
                    <div className="flex items-center justify-between text-sm mb-1">
                      <span className="font-medium">{n.nationality}</span>
                      <span className="text-muted-foreground tabular-nums text-xs">{n.count} ضيف</span>
                    </div>
                    <Progress value={maxNat > 0 ? (n.count / maxNat) * 100 : 0} className="h-2" />
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      </div>
    </div>
  )
}

function StatBox({ label, value, tone = 'default' }: { label: string; value: React.ReactNode; tone?: 'default' | 'success' | 'gold' }) {
  const tones: Record<string, string> = {
    default: 'text-foreground',
    success: 'text-success',
    gold: 'text-[#8a6d1f] dark:text-gold',
  }
  return (
    <div className="rounded-lg border bg-card p-2.5 text-center">
      <p className={`text-xl font-extrabold tabular-nums leading-7 ${tones[tone]}`}>{value}</p>
      <p className="text-[10px] text-muted-foreground mt-0.5">{label}</p>
    </div>
  )
}
