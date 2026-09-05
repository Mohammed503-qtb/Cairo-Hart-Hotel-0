'use client'

// ─────────────────────────────────────────────────────────────
// PRIVACY DIALOG — سياسة الخصوصية (F8 — Task 24-f)
//
// واجهة الحوار للسياسة المعروضة على الموقع — النص مرآة موجزة
// للمصدر النصي الحقيقي docs/PRIVACY_POLICY.md v1.0 (2026-09-05).
// أي تعديل يجب أن يبدأ من الوثيقة ثم يُنعكس هنا.
// ─────────────────────────────────────────────────────────────
import { ShieldCheck } from 'lucide-react'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from '@/components/ui/dialog'

const SECTIONS: { title: string; items: string[] }[] = [
  {
    title: 'البيانات التي نجمعها',
    items: [
      'بيانات التعريف: اسم الضيف ورقم هاتفه عند الحجز — بلا إنشاء حساب ولا كلمة مرور ولا ربط بحسابات التواصل.',
      'كود الدخول: كود قصير (H للضيوف · R/A للطاقم) يُخزَّن بصمته المجزأة SHA-256 فقط — الكود الخام لا يُخزَّن أبدًا وينتهي بانتهاء الإقامة أو إبطاله.',
      'بيانات الإقامة والفوترة: الغرفة والليالي والضرائب والرسوم والمدفوعات — الدفع نقدي في الفندق، ولا نجمع بيانات بطاقات بنكية.',
      'الرسائل وطلبات الخدمة بينك وبين الاستقبال — لخدمة إقامتك الجارية حصرًا.',
      'سجل تدقيق تشغيلي (الوقت + الدور + نوع الفعل) — لا يتضمن محتوى جهازك.',
      'إعدادات الجهاز: لا شيء — لا معرّفات إعلانات، لا تتبُّع، لا موقع جغرافي، ولا أي جهة خارجية.',
    ],
  },
  {
    title: 'كيف نستخدمها',
    items: [
      'حصرًا لتشغيل حجزك وإقامتك: الوصول والبحث وإصدار الكود، الطلبات والمحادثة، الفوترة والتسوية، والعمليات الداخلية للفندق.',
      'لا استخدام تسويقيًا أو إعلانيًا إطلاقًا — لا رسائل ترويجية ولا ملفات تعريف ولا قرارات آلية.',
    ],
  },
  {
    title: 'المشاركة مع الأطراف',
    items: [
      'لا نشارك بياناتك مع أي طرف ثالث في النسخة الحالية — لا بيع ولا تأجير ولا خدمات سحابية خارجية.',
      'الاستثناء الوحيد: الجهات الرسمية عند طلب قانوني ملزِم صريح وفي حدوده فقط.',
    ],
  },
  {
    title: 'الاحتفاظ',
    items: [
      'بيانات الحجز والإقامة والفوترة: سنتان افتراضيًا وفق سياسة المحاسبة.',
      'سجلات التدقيق: 12 شهرًا ثم تُحذف.',
      'الجلسات: تنتهي بإبطال الكود أو انتهائه أو الخروج — وكود الضيف يموت حتمًا عند إتمام الخروج.',
    ],
  },
  {
    title: 'حقوقك',
    items: [
      'لك طلب نسخة من بياناتك أو تصحيحها أو حذفها (بما لا يخالف الالتزامات المحاسبية) عبر التواصل معنا هاتفيًا أو واتساب أو بريدًا — يكفي رقم الحجز/الهاتف لإثبات الملكية.',
    ],
  },
  {
    title: 'الأمان',
    items: [
      'اتصال كامل عبر HTTPS · أكواد مجزأة أحادية الاتجاه · خمس محاولات دخول فاشلة بالدقيقة ثم قفل مؤقت · صلاحيات حسب الدور (ضيف/استقبال/إدارة) مع تدقيق كل فعل حساس.',
      'وصول التطبيق إلى جهازك: إذن الإنترنت فقط — وروابط واتساب/الهاتف/البريد لا تُفتح إلا بضغطك أنت.',
    ],
  },
]

export function PrivacyDialog({ children }: { children: React.ReactNode }) {
  return (
    <Dialog>
      <DialogTrigger asChild>{children}</DialogTrigger>
      <DialogContent className="max-h-[85vh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-lg font-extrabold">
            <ShieldCheck className="size-5 text-primary dark:text-gold" />
            سياسة الخصوصية
          </DialogTitle>
          <DialogDescription>
            فندق قلب القاهرة — عدن · الإصدار 1.0 (2026-09-05) — النص الكامل في وثيقة سياسة
            الخصوصية بالفندق، وهذه مرآته الموجزة.
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-5 pt-2">
          {SECTIONS.map((s) => (
            <section key={s.title} aria-labelledby={`privacy-${s.title}`}>
              <h3 className="mb-2 text-sm font-extrabold text-foreground">{s.title}</h3>
              <ul className="space-y-1.5 text-sm leading-relaxed text-muted-foreground">
                {s.items.map((item, i) => (
                  <li key={i} className="flex gap-2">
                    <span aria-hidden className="mt-2 size-1.5 shrink-0 rounded-full bg-gold" />
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
            </section>
          ))}
          <p className="border-t pt-3 text-xs text-muted-foreground">
            أي تغيير على هذه السياسة يُعلَن بترقيم تاريخي. النسخة العربية هي المرجع المعتمد
            (The Arabic version is the authoritative text).
          </p>
        </div>
      </DialogContent>
    </Dialog>
  )
}
