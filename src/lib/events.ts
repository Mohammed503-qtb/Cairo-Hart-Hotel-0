// ─────────────────────────────────────────────────────────────
// EVENTS — بث الأحداث الفورية لخدمة Realtime (socket.io)
// الفشل هنا لا يُفشل العملية الأصلية أبدًا (best-effort)
// ─────────────────────────────────────────────────────────────

export const REALTIME_PORT = 3002
const EMIT_PORT = 3004

export const wsRooms = {
  reception: 'reception',
  admin: 'admin',
  stay: (stayId: string) => `stay:${stayId}`,
}

export async function emitEvent(room: string, event: string, data: unknown = null): Promise<void> {
  try {
    await fetch(`http://127.0.0.1:${EMIT_PORT}/emit`, {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ room, event, data }),
      signal: AbortSignal.timeout(2500),
    })
  } catch {
    // الإشعار الفوري طبقة معزولة — تجاهل الفشل
  }
}

// أحداث النظام الموحدة
export const WS_EVENTS = {
  CHAT_MESSAGE: 'chat:message',
  REQUEST_NEW: 'request:new',
  REQUEST_UPDATED: 'request:updated',
  NOTIFICATION_NEW: 'notification:new',
  RESERVATION_NEW: 'reservation:new',
  STAY_UPDATED: 'stay:updated',
  ROOM_STATUS: 'room:status',
} as const
