// ─────────────────────────────────────────────────────────────
// REFERENCES — توليد المراجع المقروءة
// HTL-2026-000421 (حجز) | ST-2026-000883 (إقامة) | REQ-1042 (طلب)
// ─────────────────────────────────────────────────────────────
import { Prisma } from '@prisma/client'

type Tx = Prisma.TransactionClient | PrismaClientLike

interface PrismaClientLike {
  reservation: { count(args: unknown): Promise<number>; findUnique(args: unknown): Promise<unknown> }
  stay: { count(args: unknown): Promise<number>; findUnique(args: unknown): Promise<unknown> }
  serviceRequest: { count(args: unknown): Promise<number>; findUnique(args: unknown): Promise<unknown> }
}

export async function nextBookingReference(tx: Tx): Promise<string> {
  const year = new Date().getFullYear()
  const prefix = `HTL-${year}-`
  const count = await tx.reservation.count({ where: { bookingReference: { startsWith: prefix } } })
  let seq = count + 1
  for (let i = 0; i < 100; i++) {
    const ref = `${prefix}${String(seq).padStart(6, '0')}`
    const exists = await tx.reservation.findUnique({ where: { bookingReference: ref } })
    if (!exists) return ref
    seq++
  }
  throw new Error('failed to allocate booking reference')
}

export async function nextStayReference(tx: Tx): Promise<string> {
  const year = new Date().getFullYear()
  const prefix = `ST-${year}-`
  const count = await tx.stay.count({ where: { reference: { startsWith: prefix } } })
  let seq = count + 1
  for (let i = 0; i < 100; i++) {
    const ref = `${prefix}${String(seq).padStart(6, '0')}`
    const exists = await tx.stay.findUnique({ where: { reference: ref } })
    if (!exists) return ref
    seq++
  }
  throw new Error('failed to allocate stay reference')
}

export async function nextRequestReference(tx: Tx): Promise<string> {
  const count = await tx.serviceRequest.count({})
  let seq = count + 1000
  for (let i = 0; i < 200; i++) {
    const ref = `REQ-${seq}`
    const exists = await tx.serviceRequest.findUnique({ where: { reference: ref } })
    if (!exists) return ref
    seq++
  }
  throw new Error('failed to allocate request reference')
}
