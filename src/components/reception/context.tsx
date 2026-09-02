'use client'

// ─────────────────────────────────────────────────────────────
// RECEPTION CONTEXT — إجراءات مشتركة تُمرر لكل الواجهات
// ─────────────────────────────────────────────────────────────
import { createContext, useContext } from 'react'
import type { ViewKey } from './types'

export interface ReceptionActions {
  /** إعادة تحميل بيانات كل الواجهات */
  bump: () => void
  /** فتح تفاصيل إقامة (مع تبويب ابتدائي اختياري) */
  openStay: (stayId: string, initialTab?: 'guest' | 'bill' | 'requests' | 'messages' | 'actions') => void
  /** فتح إدارة طلب */
  openRequest: (requestId: string) => void
  /** فتح معالج تسجيل الوصول لحجز بتاريخ وصول محدد */
  openCheckIn: (reservationId: string, checkInISO: string) => void
  /** فتح معالج تسجيل الخروج */
  openCheckOut: (stayId: string) => void
  /** التنقل بين الواجهات */
  setView: (view: ViewKey) => void
}

export const ReceptionContext = createContext<ReceptionActions | null>(null)

export function useReception(): ReceptionActions {
  const ctx = useContext(ReceptionContext)
  if (!ctx) throw new Error('useReception must be used within ReceptionApp')
  return ctx
}
