'use client'

// ─────────────────────────────────────────────────────────────
// SITE HEADER — هيدر الموقع الثابت + تنقل + وضع ليلي
// ─────────────────────────────────────────────────────────────
import { useState, useSyncExternalStore } from 'react'
import { useTheme } from 'next-themes'
import { Moon, Sun, Menu, CalendarCheck, ClipboardList } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Sheet, SheetContent, SheetTitle, SheetTrigger } from '@/components/ui/sheet'

const NAV_LINKS = [
  { href: '#home', label: 'الرئيسية' },
  { href: '#rooms', label: 'الغرف' },
  { href: '#facilities', label: 'المرافق' },
  { href: '#gallery', label: 'المعرض' },
  { href: '#contact', label: 'الموقع والتواصل' },
]

export function SiteHeader({
  onBook,
  onManage,
}: {
  onBook: () => void
  onManage: () => void
}) {
  const { theme, setTheme } = useTheme()
  const [menuOpen, setMenuOpen] = useState(false)

  // هل اكتمل الترطيب؟ (بدون setState داخل تأثير)
  const mounted = useSyncExternalStore(
    () => () => {},
    () => true,
    () => false
  )

  const isDark = mounted && theme === 'dark'

  return (
    <header className="sticky top-0 z-40 border-b border-border/60 bg-background/85 backdrop-blur-md">
      <div className="mx-auto flex h-16 max-w-7xl items-center gap-3 px-4 sm:px-6">
        {/* الشعار */}
        <a href="#home" className="flex items-center gap-2.5" aria-label="العودة إلى الرئيسية">
          <img src="/logo-hotel.svg" alt="شعار فندق قلب القاهرة" className="h-9 w-9 shrink-0" />
          <div className="leading-tight">
            <div className="text-base font-extrabold text-foreground">فندق قلب القاهرة</div>
            <div className="hidden text-[11px] text-muted-foreground sm:block">ضيافة راقية في قلب عدن</div>
          </div>
        </a>

        {/* تنقل سطح المكتب */}
        <nav className="mx-auto hidden items-center gap-1 lg:flex" aria-label="التنقل الرئيسي">
          {NAV_LINKS.map((l) => (
            <a
              key={l.href}
              href={l.href}
              className="rounded-md px-3 py-2 text-sm font-semibold text-muted-foreground transition-colors hover:bg-accent hover:text-foreground"
            >
              {l.label}
            </a>
          ))}
        </nav>

        <div className="me-auto flex items-center gap-2 lg:me-0">
          {/* إدارة الحجز */}
          <Button
            variant="ghost"
            size="sm"
            onClick={onManage}
            className="hidden text-muted-foreground sm:inline-flex"
          >
            <ClipboardList className="size-4" />
            إدارة حجزك
          </Button>

          {/* الوضع الليلي */}
          <Button
            variant="outline"
            size="icon"
            onClick={() => setTheme(isDark ? 'light' : 'dark')}
            aria-label={isDark ? 'التبديل إلى الوضع النهاري' : 'التبديل إلى الوضع الليلي'}
            className="shrink-0"
          >
            {isDark ? <Sun className="size-4" /> : <Moon className="size-4" />}
          </Button>

          {/* احجز الآن */}
          <Button size="sm" onClick={onBook} className="hidden shrink-0 sm:inline-flex">
            <CalendarCheck className="size-4" />
            احجز الآن
          </Button>

          {/* قائمة الموبايل */}
          <Sheet open={menuOpen} onOpenChange={setMenuOpen}>
            <SheetTrigger asChild>
              <Button variant="outline" size="icon" className="lg:hidden" aria-label="فتح القائمة">
                <Menu className="size-5" />
              </Button>
            </SheetTrigger>
            <SheetContent side="right" className="w-72">
              <SheetTitle className="sr-only">قائمة التنقل</SheetTitle>
              <nav className="mt-2 flex flex-col gap-1" aria-label="قائمة الموبايل">
                {NAV_LINKS.map((l) => (
                  <a
                    key={l.href}
                    href={l.href}
                    onClick={() => setMenuOpen(false)}
                    className="rounded-md px-3 py-3 text-base font-semibold text-foreground transition-colors hover:bg-accent"
                  >
                    {l.label}
                  </a>
                ))}
                <div className="mt-4 flex flex-col gap-2 border-t pt-4">
                  <Button
                    onClick={() => {
                      setMenuOpen(false)
                      onBook()
                    }}
                  >
                    <CalendarCheck className="size-4" />
                    احجز الآن
                  </Button>
                  <Button
                    variant="outline"
                    onClick={() => {
                      setMenuOpen(false)
                      onManage()
                    }}
                  >
                    <ClipboardList className="size-4" />
                    إدارة حجزك
                  </Button>
                </div>
              </nav>
            </SheetContent>
          </Sheet>
        </div>
      </div>
    </header>
  )
}
