// ─────────────────────────────────────────────────────────────
// API HELPERS — صيغة استجابة موحدة لكل الـ endpoints
// { ok: true, ...data } | { ok: false, error }
// ─────────────────────────────────────────────────────────────
import { NextResponse } from 'next/server'

export function ok(data: Record<string, unknown> = {}, status = 200) {
  return NextResponse.json({ ok: true, ...data }, { status })
}

export function fail(error: string, status = 400) {
  return NextResponse.json({ ok: false, error }, { status })
}

export async function readBody<T = Record<string, unknown>>(req: Request): Promise<T | null> {
  try {
    return (await req.json()) as T
  } catch {
    return null
  }
}
