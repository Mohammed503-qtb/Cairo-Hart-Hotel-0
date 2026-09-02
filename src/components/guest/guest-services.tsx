'use client'

// ─────────────────────────────────────────────────────────────
// GUEST SERVICES — تبويب الخدمات
// كتالوج الخدمات بالأقسام | طلباتي مع الحالة والخط الزمني
// ─────────────────────────────────────────────────────────────

import { useState } from 'react'
import { motion } from 'framer-motion'
import { ClipboardList, ConciergeBell, Plus, Sparkles } from 'lucide-react'
import { useGuest } from './guest-context'
import {
  CategoryIcon,
  EmptyState,
  RequestStatusBadge,
  SectionTitle,
  UrgentMark,
  pageMotion,
} from './bits'
import { Card, CardContent } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { Button } from '@/components/ui/button'
import { Tabs, TabsList, TabsTrigger, TabsContent } from '@/components/ui/tabs'
import { formatMoney, timeAgoAr } from '@/lib/format'
import RequestDialog, { type RequestPreset } from './request-dialog'
import RequestDetailDialog from './request-detail-dialog'
import type { GuestRequest } from './types'

export default function GuestServices() {
  const guest = useGuest()
  const [requestPreset, setRequestPreset] = useState<RequestPreset | null>(null)
  const [detailRequest, setDetailRequest] = useState<GuestRequest | null>(null)

  return (
    <motion.div {...pageMotion} className="space-y-4">
      <Tabs
        value={guest.servicesView}
        onValueChange={(v) => guest.setServicesView(v as 'catalog' | 'requests')}
      >
        <TabsList className="grid h-12 w-full grid-cols-2 rounded-2xl">
          <TabsTrigger value="catalog" className="gap-1.5 rounded-xl text-sm font-bold">
            <ConciergeBell className="h-4 w-4" aria-hidden />
            الكتالوج
          </TabsTrigger>
          <TabsTrigger value="requests" className="gap-1.5 rounded-xl text-sm font-bold">
            <ClipboardList className="h-4 w-4" aria-hidden />
            طلباتي
            {guest.requests.length > 0 ? (
              <span className="rounded-full bg-primary px-1.5 text-[10px] font-bold text-primary-foreground">
                {guest.requests.length}
              </span>
            ) : null}
          </TabsTrigger>
        </TabsList>

        {/* ─── الكتالوج ─── */}
        <TabsContent value="catalog" className="mt-4 space-y-5">
          <Button
            onClick={() => setRequestPreset({ category: 'OTHER', title: '' })}
            className="h-11 w-full gap-2 rounded-xl text-sm font-bold"
            variant="outline"
          >
            <Plus className="h-4 w-4" aria-hidden />
            طلب خاص (خارج الكتالوج)
          </Button>

          {guest.servicesLoading && guest.services.length === 0 ? (
            <CatalogSkeleton />
          ) : guest.services.length === 0 ? (
            <EmptyState
              icon={<Sparkles className="h-6 w-6" aria-hidden />}
              title="لا خدمات متاحة حاليًا"
              hint="يمكنك دائمًا استخدام «طلب خاص» أو مراسلة الاستقبال"
            />
          ) : (
            guest.services.map((cat) => (
              <section key={cat.id} aria-label={cat.name}>
                <SectionTitle icon={<CategoryIcon name={cat.icon} className="h-4.5 w-4.5" />}>
                  {cat.name}
                </SectionTitle>
                <div className="mt-3 space-y-2">
                  {cat.services.map((s) => (
                    <Card key={s.id} className="border-border/70 shadow-sm">
                      <CardContent className="flex items-center gap-3 p-3.5">
                        <div className="min-w-0 flex-1">
                          <p className="truncate text-sm font-bold">{s.name}</p>
                          <p className="mt-0.5 text-xs text-muted-foreground">
                            {s.priceCents > 0 ? (
                              <span className="font-bold text-foreground" dir="ltr">
                                {formatMoney(s.priceCents)}
                              </span>
                            ) : (
                              'مجانًا ضمن الإقامة'
                            )}
                          </p>
                        </div>
                        <Button
                          size="sm"
                          className="h-9 gap-1 rounded-lg px-3 text-xs font-bold"
                          onClick={() =>
                            setRequestPreset({
                              serviceId: s.id,
                              category: s.categoryKey,
                              title: s.name,
                            })
                          }
                        >
                          <Plus className="h-3.5 w-3.5" aria-hidden />
                          طلب
                        </Button>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              </section>
            ))
          )}
        </TabsContent>

        {/* ─── طلباتي ─── */}
        <TabsContent value="requests" className="mt-4 space-y-2.5">
          {guest.requestsLoading && guest.requests.length === 0 ? (
            <>
              <Skeleton className="h-20 rounded-2xl" />
              <Skeleton className="h-20 rounded-2xl" />
              <Skeleton className="h-20 rounded-2xl" />
            </>
          ) : guest.requests.length === 0 ? (
            <EmptyState
              icon={<ClipboardList className="h-6 w-6" aria-hidden />}
              title="لا طلبات بعد"
              hint="اطلب أي خدمة من الكتالوج وستظهر هنا مع حالتها لحظة بلحظة"
              action={
                <Button variant="outline" onClick={() => guest.setServicesView('catalog')}>
                  تصفح الخدمات
                </Button>
              }
            />
          ) : (
            guest.requests.map((r) => (
              <motion.button
                key={r.id}
                initial={{ opacity: 0, y: 6 }}
                animate={{ opacity: 1, y: 0 }}
                onClick={() => setDetailRequest(r)}
                className="w-full rounded-2xl border border-border/70 bg-card p-4 text-start shadow-sm transition-colors hover:border-primary/40"
              >
                <div className="flex items-start justify-between gap-3">
                  <div className="min-w-0 flex-1">
                    <p className="flex flex-wrap items-center gap-2 text-sm font-bold">
                      <span className="truncate">{r.title}</span>
                      {r.priority === 'URGENT' && <UrgentMark />}
                    </p>
                    <p className="mt-1 text-xs text-muted-foreground" dir="auto">
                      {r.reference} — {timeAgoAr(r.createdAt)}
                    </p>
                    {r.assignedTo ? (
                      <p className="mt-1 text-xs text-muted-foreground">المسند إلى: {r.assignedTo}</p>
                    ) : null}
                  </div>
                  <RequestStatusBadge status={r.status} />
                </div>
                {r.description ? (
                  <p className="mt-2 line-clamp-2 text-xs leading-relaxed text-muted-foreground">
                    {r.description}
                  </p>
                ) : null}
              </motion.button>
            ))
          )}
        </TabsContent>
      </Tabs>

      {/* حوارية إنشاء طلب */}
      <RequestDialog
        preset={requestPreset}
        onClose={() => setRequestPreset(null)}
        onCreated={() => {
          void guest.refreshRequests()
          guest.setServicesView('requests')
        }}
      />

      {/* حوارية تفاصيل الطلب */}
      <RequestDetailDialog
        request={detailRequest}
        onClose={() => setDetailRequest(null)}
        onChanged={() => void guest.refreshRequests()}
      />
    </motion.div>
  )
}

function CatalogSkeleton() {
  return (
    <div className="space-y-5" aria-busy="true" aria-label="جارٍ تحميل الخدمات">
      {Array.from({ length: 3 }).map((_, i) => (
        <div key={i} className="space-y-2">
          <Skeleton className="h-6 w-32 rounded-lg" />
          <Skeleton className="h-16 rounded-2xl" />
          <Skeleton className="h-16 rounded-2xl" />
        </div>
      ))}
    </div>
  )
}
