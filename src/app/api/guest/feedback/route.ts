// ─────────────────────────────────────────────────────────────
// POST /api/guest/feedback — تقييم الإقامة (upsert على stayId)
// نجوم 1-5 + وسوم + تعليق + تدقيق
// ─────────────────────────────────────────────────────────────
import { NextRequest } from 'next/server'
import { db } from '@/lib/db'
import { ok, fail, readBody } from '@/lib/api'
import { requireGuest } from '../_lib'
import { audit } from '@/lib/audit'

export const dynamic = 'force-dynamic'

export async function POST(req: NextRequest) {
  const guard = await requireGuest(req)
  if ('error' in guard) return fail(guard.error, guard.status)
  const { stayId, guestName } = guard.auth

  const body = await readBody<{ rating?: number; tags?: unknown; comment?: string }>(req)
  const rating = Number(body?.rating)
  if (!Number.isInteger(rating) || rating < 1 || rating > 5) {
    return fail('التقييم يجب أن يكون من 1 إلى 5 نجوم')
  }

  const tags: string[] = Array.isArray(body?.tags)
    ? (body?.tags as unknown[])
        .filter((t): t is string => typeof t === 'string')
        .map((t) => t.trim().slice(0, 30))
        .filter(Boolean)
        .slice(0, 10)
    : []
  const comment = typeof body?.comment === 'string' ? body.comment.trim().slice(0, 500) : ''

  try {
    const stay = await db.stay.findUnique({ where: { id: stayId }, select: { id: true } })
    if (!stay) return fail('الإقامة غير موجودة', 404)

    const saved = await db.$transaction(async (tx) => {
      const feedback = await tx.feedback.upsert({
        where: { stayId },
        create: {
          stayId,
          rating,
          tags: JSON.stringify(tags),
          comment: comment || null,
        },
        update: {
          rating,
          tags: JSON.stringify(tags),
          comment: comment || null,
        },
      })

      await audit(tx, {
        action: 'FEEDBACK_SUBMITTED',
        entityType: 'Feedback',
        entityId: feedback.id,
        actor: guestName,
        actorRole: 'GUEST',
        details: { stayId, rating, tags, commentLength: comment.length },
      })

      return feedback
    })

    return ok({
      feedback: {
        rating: saved.rating,
        tags,
        comment: saved.comment,
        createdAt: saved.createdAt.toISOString(),
      },
    })
  } catch (e) {
    console.error('guest feedback failed', e)
    return fail('حدث خطأ أثناء حفظ التقييم — أعد المحاولة', 500)
  }
}
