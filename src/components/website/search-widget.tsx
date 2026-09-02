'use client'

// ─────────────────────────────────────────────────────────────
// SEARCH WIDGET — ودجت البحث (بطاقة زجاجية ملاصقة أسفل الهيرو)
// ─────────────────────────────────────────────────────────────
import { AlertCircle } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { addDaysInput, todayInputValue } from '@/lib/format'
import type { SearchParams } from './helpers'

export function defaultSearch(): SearchParams {
  const today = todayInputValue()
  return { checkIn: today, checkOut: addDaysInput(today, 1), adults: 2, children: 0, roomsCount: 1 }
}

interface SearchWidgetProps {
  value: SearchParams
  onChange: (v: SearchParams) => void
  onSubmit: () => void
  error?: string | null
}

export function SearchWidget({ value, onChange, onSubmit, error }: SearchWidgetProps) {
  const minCheckOut = addDaysInput(value.checkIn, 1)

  const set = (patch: Partial<SearchParams>) => {
    const next = { ...value, ...patch }
    // إصلاح فوري: المغادرة دائمًا بعد الوصول
    if (next.checkOut <= next.checkIn) next.checkOut = addDaysInput(next.checkIn, 1)
    onChange(next)
  }

  return (
    <div className="rounded-2xl border border-border/70 bg-background/85 p-4 shadow-xl backdrop-blur-md sm:p-5">
      <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-6">
        <div className="col-span-1 space-y-1.5">
          <Label htmlFor="sw-checkin" className="text-xs font-bold text-muted-foreground">
            تاريخ الوصول
          </Label>
          <Input
            id="sw-checkin"
            type="date"
            dir="ltr"
            value={value.checkIn}
            min={todayInputValue()}
            onChange={(e) => set({ checkIn: e.target.value })}
            className="bg-background"
          />
        </div>

        <div className="col-span-1 space-y-1.5">
          <Label htmlFor="sw-checkout" className="text-xs font-bold text-muted-foreground">
            تاريخ المغادرة
          </Label>
          <Input
            id="sw-checkout"
            type="date"
            dir="ltr"
            value={value.checkOut}
            min={minCheckOut}
            onChange={(e) => set({ checkOut: e.target.value })}
            className="bg-background"
          />
        </div>

        <div className="col-span-1 space-y-1.5">
          <Label className="text-xs font-bold text-muted-foreground">البالغون</Label>
          <Select value={String(value.adults)} onValueChange={(v) => set({ adults: Number(v) })}>
            <SelectTrigger dir="rtl" className="bg-background" aria-label="عدد البالغين">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {[1, 2, 3, 4, 5, 6].map((n) => (
                <SelectItem key={n} value={String(n)}>
                  {n === 1 ? 'بالغ واحد' : n === 2 ? 'بالغان' : `${n} بالغين`}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <div className="col-span-1 space-y-1.5">
          <Label className="text-xs font-bold text-muted-foreground">الأطفال</Label>
          <Select value={String(value.children)} onValueChange={(v) => set({ children: Number(v) })}>
            <SelectTrigger dir="rtl" className="bg-background" aria-label="عدد الأطفال">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {[0, 1, 2, 3, 4].map((n) => (
                <SelectItem key={n} value={String(n)}>
                  {n === 0 ? 'بدون أطفال' : n === 1 ? 'طفل واحد' : n === 2 ? 'طفلان' : `${n} أطفال`}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <div className="col-span-1 space-y-1.5">
          <Label className="text-xs font-bold text-muted-foreground">الغرف</Label>
          <Select value={String(value.roomsCount)} onValueChange={(v) => set({ roomsCount: Number(v) })}>
            <SelectTrigger dir="rtl" className="bg-background" aria-label="عدد الغرف">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {[1, 2, 3].map((n) => (
                <SelectItem key={n} value={String(n)}>
                  {n === 1 ? 'غرفة واحدة' : n === 2 ? 'غرفتان' : `${n} غرف`}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <div className="col-span-2 flex items-end md:col-span-3 xl:col-span-1">
          <Button onClick={onSubmit} size="lg" className="w-full">
            ابحث عن الغرف المتاحة
          </Button>
        </div>
      </div>

      {error ? (
        <p className="mt-3 flex items-center gap-1.5 text-sm font-semibold text-destructive" role="alert">
          <AlertCircle className="size-4 shrink-0" />
          {error}
        </p>
      ) : null}
    </div>
  )
}
