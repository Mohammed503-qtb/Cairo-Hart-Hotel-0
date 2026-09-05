// ─────────────────────────────────────────────────────────────
// POST/GET /api/admin/upload — مكتبة صور محتوى الموقع
// POST: multipart/form-data { file } → public/uploads/<id>.<ext>
//       المسموح: PNG / JPG / WebP / GIF / SVG — حتى 5MB (SVG يرفض إن حمل سكربت)
// GET:  قائمة الملفات المرفوعة (الأحدث أولًا) — لمكتبة الاختيار
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { promises as fs } from 'fs'
import path from 'path'
import { randomUUID } from 'crypto'
import { db } from '@/lib/db'
import { ok, fail } from '@/lib/api'
import { requireRole, type AuthContext } from '@/lib/auth'
import { audit } from '@/lib/audit'

export const dynamic = 'force-dynamic'

const UPLOAD_DIR = path.join(process.cwd(), 'public', 'uploads')
const MAX_BYTES = 5 * 1024 * 1024 // 5MB

const ALLOWED_TYPES: Record<string, string> = {
  'image/png': 'png',
  'image/jpeg': 'jpg',
  'image/webp': 'webp',
  'image/gif': 'gif',
  'image/svg+xml': 'svg',
}

export async function POST(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)
  const { staffName } = guard.auth as Extract<AuthContext, { role: 'ADMIN' }>

  let form: FormData
  try {
    form = await req.formData()
  } catch {
    return fail('طلب الرفع غير صالح')
  }

  const file = form.get('file')
  if (!(file instanceof File)) return fail('لم يتم إرسال ملف الصورة')
  if (file.size === 0) return fail('الملف فارغ')

  const ext = ALLOWED_TYPES[file.type]
  if (!ext) return fail('نوع الملف غير مدعوم — المسموح: PNG، JPG، WebP، GIF، SVG')
  if (file.size > MAX_BYTES) return fail('حجم الصورة يجب أن يكون أقل من 5 ميغابايت')

  const buffer = Buffer.from(await file.arrayBuffer())

  // SVG نصي: رفض أي سكربت مضمّن (XSS)
  if (ext === 'svg') {
    const text = buffer.toString('utf8').toLowerCase()
    if (text.includes('<script') || text.includes('onload=') || text.includes('onerror=')) {
      return fail('ملف SVG يحتوي سكربتًا — غير مسموح لأسباب أمنية')
    }
  }

  const name = `${Date.now().toString(36)}-${randomUUID().slice(0, 8)}.${ext}`
  await fs.mkdir(UPLOAD_DIR, { recursive: true })
  await fs.writeFile(path.join(UPLOAD_DIR, name), buffer)

  const url = `/uploads/${name}`

  await audit(db, {
    action: 'CONTENT_IMAGE_UPLOADED',
    entityType: 'Upload',
    entityId: url,
    actor: staffName,
    actorRole: 'ADMIN',
    details: { file: name, bytes: file.size, type: file.type },
  })

  return ok({ url, size: file.size, type: file.type })
}

export async function GET(req: NextRequest) {
  const guard = await requireRole(req, 'ADMIN')
  if ('error' in guard) return fail(guard.error, guard.status)

  try {
    await fs.mkdir(UPLOAD_DIR, { recursive: true })
    const entries = await fs.readdir(UPLOAD_DIR, { withFileTypes: true })
    const files = await Promise.all(
      entries
        .filter((e) => e.isFile() && /\.(png|jpe?g|webp|gif|svg)$/i.test(e.name))
        .map(async (e) => {
          const st = await fs.stat(path.join(UPLOAD_DIR, e.name))
          return { url: `/uploads/${e.name}`, bytes: st.size, modifiedAt: st.mtimeMs }
        })
    )
    files.sort((a, b) => b.modifiedAt - a.modifiedAt)
    return ok({ files: files.slice(0, 120) })
  } catch {
    return fail('تعذر قراءة مكتبة الصور', 500)
  }
}
