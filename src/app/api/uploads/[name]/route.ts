// ─────────────────────────────────────────────────────────────
// GET /api/uploads/[name] — تقديم صور المحتوى المرفوعة من القرص
// fallback يعمل مع rewrite في next.config (الملفات الثابتة تُقدَّم أولًا
// من public/uploads إن وجدت — هذا المسار شبكة أمان دائمة)
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { promises as fs } from 'fs'
import path from 'path'

export const dynamic = 'force-dynamic'

const UPLOAD_DIR = path.join(process.cwd(), 'public', 'uploads')

const MIME: Record<string, string> = {
  png: 'image/png',
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
  webp: 'image/webp',
  gif: 'image/gif',
  svg: 'image/svg+xml',
}

export async function GET(_req: NextRequest, ctx: { params: Promise<{ name: string }> }) {
  const { name } = await ctx.params

  // اسم ملف آمن فقط (بلا مسارات أو نقاط مزدوجة)
  if (!/^[A-Za-z0-9._-]+\.(png|jpe?g|webp|gif|svg)$/i.test(name) || name.includes('..')) {
    return new Response('Not found', { status: 404 })
  }

  try {
    const data = await fs.readFile(path.join(UPLOAD_DIR, name))
    const ext = name.split('.').pop()?.toLowerCase() ?? ''
    return new Response(new Uint8Array(data), {
      headers: {
        'content-type': MIME[ext] ?? 'application/octet-stream',
        'cache-control': 'public, max-age=3600',
      },
    })
  } catch {
    return new Response('Not found', { status: 404 })
  }
}
