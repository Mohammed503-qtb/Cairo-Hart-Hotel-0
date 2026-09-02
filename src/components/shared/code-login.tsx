'use client'

// ─────────────────────────────────────────────────────────────
// CODE LOGIN — شاشة دخول التطبيق بكود الوصول
// كود واحد يحدد الهوية: ضيف H… / استقبال R… / إدارة A…
// ─────────────────────────────────────────────────────────────

import { useState } from 'react'
import { motion } from 'framer-motion'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Card, CardContent } from '@/components/ui/card'
import { useToast } from '@/hooks/use-toast'
import { useAppStore } from '@/lib/store'
import { api } from '@/lib/api-client'
import { ArrowRight, KeyRound, Loader2, ChevronDown, Hotel, ShieldCheck } from 'lucide-react'
import type { AppSession } from '@/types'

const DEMO_CODES = [
  { code: 'H834729X7', label: 'ضيف — خالد يوسف، غرفة 201' },
  { code: 'R492671M3', label: 'استقبال — أحمد' },
  { code: 'A371849L9', label: 'إدارة — سالم' },
]

export default function CodeLogin() {
  const [code, setCode] = useState('')
  const [loading, setLoading] = useState(false)
  const [showDemo, setShowDemo] = useState(false)
  const { toast } = useToast()
  const setSession = useAppStore((s) => s.setSession)
  const setMode = useAppStore((s) => s.setMode)

  const submit = async (rawCode?: string) => {
    const finalCode = (rawCode ?? code).trim()
    if (!finalCode) {
      toast({ title: 'أدخل كود الدخول', variant: 'destructive' })
      return
    }
    setLoading(true)
    try {
      const res = await api<{ token: string; role: AppSession['role']; name: string; expiresAt: string }>(
        '/api/auth/validate',
        { method: 'POST', body: { code: finalCode } }
      )
      setSession({ token: res.token, role: res.role, name: res.name, expiresAt: res.expiresAt })
      setMode(res.role.toLowerCase() as 'guest' | 'reception' | 'admin')
      toast({ title: `أهلًا ${res.name} 👋` })
    } catch (err) {
      toast({
        title: 'تعذر الدخول',
        description: err instanceof Error ? err.message : 'حدث خطأ غير متوقع',
        variant: 'destructive',
      })
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen flex flex-col bg-background pattern-arabic">
      <main className="flex-1 flex items-center justify-center p-4">
        <motion.div
          initial={{ opacity: 0, y: 16 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.4 }}
          className="w-full max-w-md"
        >
          <div className="text-center mb-8">
            <img src="/logo-hotel.svg" alt="شعار فندق قلب القاهرة" className="w-20 h-20 mx-auto mb-4" />
            <h1 className="text-2xl font-extrabold text-primary">فندق قلب القاهرة</h1>
            <p className="text-sm text-muted-foreground mt-1">تطبيق الإقامة والاستقبال والإدارة</p>
          </div>

          <Card className="border-border/60 shadow-lg">
            <CardContent className="p-6 space-y-4">
              <div className="flex items-center gap-2 text-primary font-bold">
                <KeyRound className="w-5 h-5" />
                <span>أدخل كود الدخول</span>
              </div>

              <Input
                dir="ltr"
                value={code}
                onChange={(e) => setCode(e.target.value.toUpperCase().replace(/[^A-Z0-9]/g, '').slice(0, 9))}
                onKeyDown={(e) => e.key === 'Enter' && submit()}
                placeholder="H834729X7"
                className="text-center text-xl font-bold tracking-[0.3em] h-14 border-2 focus:border-primary"
                autoComplete="off"
                spellCheck={false}
              />

              <Button
                onClick={() => submit()}
                disabled={loading || !code}
                className="w-full h-12 text-base font-bold"
                size="lg"
              >
                {loading ? <Loader2 className="w-5 h-5 animate-spin" /> : 'دخول'}
              </Button>

              <p className="text-xs text-muted-foreground text-center leading-relaxed">
                كود الضيف يصلك من الاستقبال عند تسجيل الوصول.
                <br />
                الكود صالح حتى نهاية إقامتك فقط.
              </p>

              <button
                onClick={() => setShowDemo(!showDemo)}
                className="w-full flex items-center justify-center gap-1 text-xs text-muted-foreground hover:text-foreground transition-colors"
              >
                <ChevronDown className={`w-3.5 h-3.5 transition-transform ${showDemo ? 'rotate-180' : ''}`} />
                أكواد تجريبية للاختبار
              </button>

              {showDemo && (
                <div className="rounded-lg bg-muted/60 border border-border/60 p-3 space-y-2">
                  {DEMO_CODES.map((d) => (
                    <button
                      key={d.code}
                      onClick={() => {
                        setCode(d.code)
                        submit(d.code)
                      }}
                      className="w-full flex items-center justify-between gap-3 text-xs rounded-md px-3 py-2 hover:bg-accent transition-colors text-start"
                    >
                      <span className="font-mono font-bold text-primary" dir="ltr">{d.code}</span>
                      <span className="text-muted-foreground">{d.label}</span>
                    </button>
                  ))}
                </div>
              )}
            </CardContent>
          </Card>

          <div className="flex items-center justify-center gap-4 mt-6 text-xs text-muted-foreground">
            <span className="flex items-center gap-1">
              <ShieldCheck className="w-3.5 h-3.5 text-success" />
              تحقق آمن من الخادم
            </span>
            <button
              onClick={() => setMode('website')}
              className="flex items-center gap-1 hover:text-primary transition-colors font-medium"
            >
              <ArrowRight className="w-3.5 h-3.5" />
              العودة إلى موقع الفندق
            </button>
          </div>
        </motion.div>
      </main>

      <footer className="py-4 text-center text-xs text-muted-foreground">
        <span className="inline-flex items-center gap-1.5">
          <Hotel className="w-3.5 h-3.5" />
          فندق قلب القاهرة — عدن
        </span>
      </footer>
    </div>
  )
}
