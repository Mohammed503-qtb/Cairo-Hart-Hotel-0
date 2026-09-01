// ─────────────────────────────────────────────────────────────
// RATE LIMITING — حماية من التخمين والإساءة (in-memory)
// ─────────────────────────────────────────────────────────────

interface Bucket {
  count: number
  resetAt: number
}

const buckets = new Map<string, Bucket>()

export function rateLimit(
  key: string,
  max: number,
  windowMs: number
): { allowed: boolean; retryAfterSec: number } {
  const now = Date.now()
  const bucket = buckets.get(key)
  if (!bucket || bucket.resetAt <= now) {
    buckets.set(key, { count: 1, resetAt: now + windowMs })
    return { allowed: true, retryAfterSec: 0 }
  }
  bucket.count++
  if (bucket.count > max) {
    return { allowed: false, retryAfterSec: Math.ceil((bucket.resetAt - now) / 1000) }
  }
  return { allowed: true, retryAfterSec: 0 }
}

/** عدّاد محاولات فاشلة مع قفل مؤقت (lockout) */
const failures = new Map<string, { count: number; lockedUntil: number }>()

export function recordFailure(key: string, maxFails: number, lockMs: number): { locked: boolean; retryAfterSec: number } {
  const now = Date.now()
  const entry = failures.get(key)
  if (entry && entry.lockedUntil > now) {
    return { locked: true, retryAfterSec: Math.ceil((entry.lockedUntil - now) / 1000) }
  }
  const count = (entry?.count ?? 0) + 1
  if (count >= maxFails) {
    failures.set(key, { count: 0, lockedUntil: now + lockMs })
    return { locked: true, retryAfterSec: Math.ceil(lockMs / 1000) }
  }
  failures.set(key, { count, lockedUntil: 0 })
  return { locked: false, retryAfterSec: 0 }
}

export function clearFailures(key: string): void {
  failures.delete(key)
}

export function clientIp(req: Request): string {
  const fwd = req.headers.get('x-forwarded-for')
  if (fwd) return fwd.split(',')[0].trim()
  return req.headers.get('x-real-ip') ?? 'unknown'
}

// تنظيف دوري خفيف لمنع تضخم الذاكرة
if (typeof setInterval !== 'undefined') {
  const timer = setInterval(() => {
    const now = Date.now()
    for (const [k, b] of buckets) if (b.resetAt <= now) buckets.delete(k)
    for (const [k, f] of failures) if (f.lockedUntil && f.lockedUntil <= now) failures.delete(k)
  }, 60_000)
  if (typeof timer === 'object' && 'unref' in timer) (timer as { unref(): void }).unref()
}
