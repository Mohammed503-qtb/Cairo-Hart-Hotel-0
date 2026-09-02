// ─────────────────────────────────────────────────────────────
// AUDIT — سجل التدقيق المركزي
// ─────────────────────────────────────────────────────────────
import { Prisma, PrismaClient } from '@prisma/client'

type Tx = Prisma.TransactionClient | PrismaClient

export type AuditAction =
  | 'RESERVATION_CREATED'
  | 'RESERVATION_CONFIRMED'
  | 'RESERVATION_CANCELLED'
  | 'RESERVATION_LOOKED_UP'
  | 'PAYMENT_RECORDED'
  | 'PAYMENT_REFUNDED'
  | 'CHECK_IN'
  | 'CHECK_OUT'
  | 'ROOM_ASSIGNED'
  | 'ROOM_TRANSFERRED'
  | 'CODE_GENERATED'
  | 'CODE_REVOKED'
  | 'CODE_LOGIN'
  | 'CODE_LOGIN_FAILED'
  | 'REQUEST_CREATED'
  | 'REQUEST_UPDATED'
  | 'EXTENSION_REQUESTED'
  | 'EXTENSION_APPROVED'
  | 'EXTENSION_REJECTED'
  | 'ROOM_CHANGE_REQUESTED'
  | 'ROOM_CHANGE_APPROVED'
  | 'ROOM_CHANGE_REJECTED'
  | 'SETTINGS_UPDATED'
  | 'RATE_CHANGED'
  | 'ROOM_TYPE_CHANGED'
  | 'ROOM_CHANGED'
  | 'SERVICE_CATALOG_CHANGED'
  | 'STAFF_CHANGED'
  | 'CHAT_MESSAGE'
  | 'CHECKOUT_REQUESTED'

export async function audit(
  tx: Tx,
  params: {
    action: AuditAction | string
    entityType: string
    entityId: string
    actor: string
    actorRole: 'GUEST' | 'RECEPTION' | 'ADMIN' | 'SYSTEM' | 'WEBSITE'
    details?: Record<string, unknown>
  }
): Promise<void> {
  try {
    await tx.auditLog.create({
      data: {
        action: params.action,
        entityType: params.entityType,
        entityId: params.entityId,
        actor: params.actor,
        actorRole: params.actorRole,
        details: JSON.stringify(params.details ?? {}),
      },
    })
  } catch {
    // التدقيق لا يُفشل العملية الأصلية أبدًا
  }
}
