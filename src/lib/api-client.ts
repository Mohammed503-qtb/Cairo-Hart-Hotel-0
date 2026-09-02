// ─────────────────────────────────────────────────────────────
// API CLIENT — عميل موحد لكل نداءات الـ API من الواجهة
// ─────────────────────────────────────────────────────────────
'use client'

import { useAppStore } from '@/lib/store'

export class ApiError extends Error {
  status: number
  constructor(message: string, status: number) {
    super(message)
    this.status = status
  }
}

export async function api<T = Record<string, unknown>>(
  path: string,
  options: { method?: string; body?: unknown } = {}
): Promise<T> {
  const token = useAppStore.getState().session?.token
  let res: Response
  try {
    res = await fetch(path, {
      method: options.method ?? 'GET',
      headers: {
        'content-type': 'application/json',
        ...(token ? { authorization: `Bearer ${token}` } : {}),
      },
      body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
    })
  } catch {
    throw new ApiError('تعذر الاتصال بالخادم — تحقق من اتصالك وأعد المحاولة', 0)
  }

  let json: Record<string, unknown> = {}
  try {
    json = (await res.json()) as Record<string, unknown>
  } catch {
    json = {}
  }

  if (!res.ok || json.ok === false) {
    const message = typeof json.error === 'string' ? json.error : 'حدث خطأ غير متوقع'
    if (res.status === 401) {
      // جلسة منتهية — إعادة للموقع
      useAppStore.getState().logout()
    }
    throw new ApiError(message, res.status)
  }

  return json as T
}
