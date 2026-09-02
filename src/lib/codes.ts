// ─────────────────────────────────────────────────────────────
// ACCESS CODES — توليد وتحقق (H/R/A + 6 أرقام + حرفا تحقق)
// الكود الخام لا يُخزَّن أبدًا — يُخزَّن SHA-256 فقط
// ─────────────────────────────────────────────────────────────
import crypto from 'crypto'

export type CodeType = 'GUEST' | 'RECEPTION' | 'ADMIN'

const PREFIX: Record<CodeType, string> = { GUEST: 'H', RECEPTION: 'R', ADMIN: 'A' }

/** حرفا تحقق حتميان من الأرقام + بادئة النوع (يمنع أخطاء الكتابة الشائعة) */
function checksumChars(type: CodeType, digits: string): string {
  let sum = digits.split('').reduce((a, c) => a + Number(c), 0) + PREFIX[type].charCodeAt(0)
  const c1 = (sum % 36).toString(36).toUpperCase()
  const c2 = ((sum * 7 + 13) % 36).toString(36).toUpperCase()
  return c1 + c2
}

/** توليد كود عشوائي آمن: H834729X7 / R492671M3 / A371849L9 */
export function generateCode(type: CodeType): string {
  const digits = Array.from({ length: 6 }, () => crypto.randomInt(0, 10)).join('')
  return `${PREFIX[type]}${digits}${checksumChars(type, digits)}`
}

export function isValidCodeFormat(code: string): boolean {
  return /^[HRA]\d{6}[A-Z0-9]{2}$/.test(code.trim().toUpperCase())
}

export function normalizeCode(code: string): string {
  return code.trim().toUpperCase().replace(/\s+/g, '')
}

export function hashCode(code: string): string {
  return crypto.createHash('sha256').update(normalizeCode(code)).digest('hex')
}

export function maskCode(code: string): string {
  const c = normalizeCode(code)
  if (c.length < 6) return '••••••••'
  return `${c.slice(0, 2)}••••${c.slice(-2)}`
}
