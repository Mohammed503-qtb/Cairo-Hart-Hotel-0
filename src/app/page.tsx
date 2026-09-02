'use client'

import { useEffect, useSyncExternalStore } from 'react'
import { useAppStore } from '@/lib/store'
import WebsiteView from '@/components/website/website-view'
import GuestApp from '@/components/guest/guest-app'
import ReceptionApp from '@/components/reception/reception-app'
import AdminApp from '@/components/admin/admin-app'
import CodeLogin from '@/components/shared/code-login'
import { Smartphone } from 'lucide-react'

const emptySubscribe = () => () => {}

export default function Home() {
  const mode = useAppStore((s) => s.mode)
  const session = useAppStore((s) => s.session)
  const hydrated = useAppStore((s) => s.hydrated)
  const setMode = useAppStore((s) => s.setMode)

  // حل عقدة Hydration: أول رسم يطابق الخادم (false) ثم يصبح true بعد التركيب
  const mounted = useSyncExternalStore(emptySubscribe, () => true, () => false)

  // إنتهاء صلاحية الجلسة تلقائيًا
  useEffect(() => {
    if (!session) return
    const expires = new Date(session.expiresAt).getTime()
    if (Number.isNaN(expires) || expires < Date.now()) {
      useAppStore.getState().logout()
      return
    }
    const timer = setTimeout(
      () => useAppStore.getState().logout(),
      Math.max(1000, expires - Date.now())
    )
    return () => clearTimeout(timer)
  }, [session])

  // قبل التركيب: مطابقة الخادم (الوضع الافتراضي = الموقع)
  if (!mounted) return <WebsiteView />

  // بعد التركيب وقبل استرجاع الجلسة المخزنة: شاشة تحميل قصيرة
  if (!hydrated) return <BootScreen />

  if (mode === 'login') return <CodeLogin />

  if (mode === 'guest' && session?.role === 'GUEST') return <GuestApp />
  if (mode === 'reception' && session?.role === 'RECEPTION') return <ReceptionApp />
  if (mode === 'admin' && session?.role === 'ADMIN') return <AdminApp />

  // إذا وُجدت جلسة صالحة لكن الوضع موقع — نعود للموقع عاديًا
  return (
    <>
      <WebsiteView />
      {/* مُشغّل التطبيق العائم — متاح دائمًا من الموقع */}
      <button
        onClick={() => setMode('login')}
        className="fixed bottom-5 left-5 z-50 flex items-center gap-2 rounded-full bg-primary text-primary-foreground pl-4 pr-5 py-3 shadow-lg hover:shadow-xl hover:bg-primary/90 transition-all active:scale-95 no-print"
        aria-label="دخول تطبيق الفندق"
      >
        <Smartphone className="w-4.5 h-4.5" />
        <span className="text-sm font-bold">دخول التطبيق</span>
      </button>
    </>
  )
}

function BootScreen() {
  return (
    <div className="min-h-screen flex flex-col items-center justify-center gap-4 bg-background">
      <img src="/logo-hotel.svg" alt="شعار فندق قلب القاهرة" className="w-16 h-16 animate-pulse" />
      <p className="text-sm text-muted-foreground">جارٍ التحميل…</p>
    </div>
  )
}
