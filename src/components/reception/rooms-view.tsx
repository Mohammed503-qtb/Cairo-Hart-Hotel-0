'use client'

// ─────────────────────────────────────────────────────────────
// ROOMS VIEW (RoomBoard) — لوحة الغرف مصنفة بالطوابق
// بطاقات ملونة حسب الحالة + Legend + نقر → RoomDialog
// ─────────────────────────────────────────────────────────────

import { useEffect, useMemo, useState } from 'react'
import { api } from '@/lib/api-client'
import { Skeleton } from '@/components/ui/skeleton'
import { Badge } from '@/components/ui/badge'
import { LayoutGrid, BedDouble, Users } from 'lucide-react'
import type { RoomItem } from './types'
import { roomStatusLabel, ROOM_CARD_STYLE, EmptyState, SectionTitle, } from './bits'
import RoomDialog from './room-dialog'
import { useReception } from './context'
import { formatDateAr } from '@/lib/format'
const LEGEND: { status: string; color: string }[] = [
  { status: 'AVAILABLE', color: 'bg-success' },
  { status: 'OCCUPIED', color: 'bg-destructive' },
  { status: 'CLEANING', color: 'bg-gold' },
  { status: 'DIRTY', color: 'bg-warning' },
  { status: 'OUT_OF_ORDER', color: 'bg-neutral-800' },
]

export default function RoomsView({ version }: { version: number }) {
  const [rooms, setRooms] = useState<RoomItem[] | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [selected, setSelected] = useState<RoomItem | null>(null)
  const { openStay, bump } = useReception()

  useEffect(() => {
    let cancelled = false
    ;(async () => {
      try {
        const res = await api<{ rooms: RoomItem[] }>('/api/reception/rooms')
        if (!cancelled) {
          setRooms(res.rooms)
          setError(null)
        }
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : 'تعذر تحميل الغرف')
      }
    })()
    return () => {
      cancelled = true
    }
  }, [version])

  const floors = useMemo(() => {
    if (!rooms) return []
    const map = new Map<number, RoomItem[]>()
    for (const r of rooms) {
      const list = map.get(r.floor) ?? []
      list.push(r)
      map.set(r.floor, list)
    }
    return Array.from(map.entries()).sort((a, b) => a[0] - b[0])
  }, [rooms])

  const counts = useMemo(() => {
    const c: Record<string, number> = {}
    for (const r of rooms ?? []) c[r.status] = (c[r.status] ?? 0) + 1
    return c
  }, [rooms])

  return (
    <div className="space-y-4">
      <SectionTitle icon={<LayoutGrid className="w-5 h-5 text-primary" />}>
        حالة الغرف {rooms ? `(${rooms.length})` : ''}
      </SectionTitle>

      {/* Legend */}
      <div className="flex flex-wrap gap-2 rounded-lg border bg-card p-2.5" aria-label="دليل الألوان">
        {LEGEND.map((l) => (
          <span key={l.status} className="flex items-center gap-1.5 text-xs font-bold text-muted-foreground">
            <span className={`w-3 h-3 rounded ${l.color}`} />
            {roomStatusLabel(l.status)}
            {counts[l.status] ? <Badge variant="outline" className="text-[10px]">{counts[l.status]}</Badge> : null}
          </span>
        ))}
      </div>

      {error ? <EmptyState title="تعذر التحميل" subtitle={error} /> : null}

      {!rooms && !error ? (
        <div className="space-y-4">
          {Array.from({ length: 2 }).map((_, i) => (
            <Skeleton key={i} className="h-32 rounded-xl" />
          ))}
        </div>
      ) : null}

      {floors.map(([floor, floorRooms]) => (
        <section key={floor} aria-label={`الطابق ${floor}`}>
          <h3 className="text-sm font-extrabold text-muted-foreground mb-2 flex items-center gap-1.5">
            <BedDouble className="w-4 h-4" /> الطابق {floor}
          </h3>
          <div className="grid grid-cols-3 sm:grid-cols-4 md:grid-cols-6 gap-2">
            {floorRooms.map((r) => (
              <RoomCard key={r.id} room={r} onClick={() => setSelected(r)} />
            ))}
          </div>
        </section>
      ))}

      {selected ? (
        <RoomDialog
          room={selected}
          onClose={() => setSelected(null)}
          onChanged={bump}
          onShowStay={(stayId) => {
            setSelected(null)
            openStay(stayId)
          }}
        />
      ) : null}
    </div>
  )
}

function RoomCard({ room, onClick }: { room: RoomItem; onClick: () => void }) {
  const style = ROOM_CARD_STYLE[room.status] ?? 'bg-muted border-border'
  return (
    <button
      onClick={onClick}
      className={`rounded-lg border-2 p-2 text-center transition-all hover:shadow-md hover:-translate-y-0.5 active:translate-y-0 min-h-[76px] flex flex-col items-center justify-center gap-0.5 ${style}`}
      aria-label={`غرفة ${room.number} — ${roomStatusLabel(room.status)}`}
    >
      <span className="text-lg font-black" dir="ltr">{room.number}</span>
      {room.status === 'OCCUPIED' && room.guestName ? (
        <>
          <span className="text-[10px] font-bold truncate w-full flex items-center justify-center gap-0.5">
            <Users className="w-2.5 h-2.5 shrink-0" />
            {room.guestName}
          </span>
          {room.expectedCheckOutAt ? <span className="text-[9px] opacity-75">خروج {formatDateAr(room.expectedCheckOutAt)}</span> : null}
        </>
      ) : (
        <span className="text-[10px] font-bold">{roomStatusLabel(room.status)}</span>
      )}
      {room.status === 'OUT_OF_ORDER' && room.notes ? (
        <span className="text-[9px] opacity-75 truncate w-full" title={room.notes}>{room.notes}</span>
      ) : null}
    </button>
  )
}
