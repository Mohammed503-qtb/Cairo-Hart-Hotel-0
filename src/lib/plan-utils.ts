import type { PlanSection } from './plan-types';

/**
 * توليد slug مستقر من نص عربي/لاتيني (يُستخدم في الـ API وفي مراسي العناوين بالواجهة).
 */
export function slugify(text: string): string {
  return text
    .trim()
    .toLowerCase()
    // إزالة علامات الاتجاه والفواصل غير المرئية
    .replace(/[\u200e\u200f\u200c\u200d]/g, '')
    // كل ما ليس حرفًا أو رقمًا (بأي لغة) يتحول إلى شرطة
    .replace(/[^\p{L}\p{N}]+/gu, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 80);
}

/**
 * تطبيع نص عربي للبحث (تجاهل التشكيل والتاء المربوطة والألف المقصورة والألف بأشكالها).
 */
export function normalizeSearch(text: string): string {
  return text
    .toLowerCase()
    .replace(/[\u0640\u064B-\u065F\u0670]/g, '')
    .replace(/[أإآ]/g, 'ا')
    .replace(/ة/g, 'ه')
    .replace(/ى/g, 'ي')
    .replace(/[^\p{L}\p{N}]+/gu, ' ')
    .trim();
}

export interface PhaseInfo {
  sectionId: string;
  subsectionId: string;
  number: number;
  title: string;
}

/**
 * استخراج مراحل التنفيذ (PHASE 0..13) من الأقسام الفرعية التي تبدأ بـ PHASE أو المرحلة.
 */
export function extractPhases(sections: PlanSection[]): PhaseInfo[] {
  const phases: PhaseInfo[] = [];
  for (const section of sections) {
    for (const sub of section.subsections) {
      const match = /^(?:PHASE|المرحلة)\s*(\d+)\s*[—–:.\-]?\s*(.*)$/iu.exec(sub.title.trim());
      if (match) {
        phases.push({
          sectionId: section.id,
          subsectionId: sub.id,
          number: Number(match[1]),
          title: match[2].trim() || sub.title.trim(),
        });
      }
    }
  }
  return phases.sort((a, b) => a.number - b.number);
}

/**
 * فصل وسم PART عن بقية العنوان (لعرض بطاقات الأقسام).
 */
export function splitSectionLabel(title: string): { label: string; rest: string } {
  const match = /^(PART\s+[IVXLCDM]+|\d+(?:\.\d+)?)[\s—–:-]*(.*)$/iu.exec(title.trim());
  if (match) {
    return { label: match[1].toUpperCase(), rest: match[2].trim() || title.trim() };
  }
  const firstWord = title.trim().split(/\s+/)[0] ?? title;
  return { label: firstWord, rest: title.trim().slice(firstWord.length).trim() || title.trim() };
}

/**
 * تنسيق تاريخ التوليد بالعربية مع أرقام لاتينية.
 */
export function formatDateTimeAr(iso: string): string {
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '';
  try {
    return new Intl.DateTimeFormat('ar', {
      dateStyle: 'medium',
      timeStyle: 'short',
      numberingSystem: 'latn',
    } as Intl.DateTimeFormatOptions).format(date);
  } catch {
    return date.toISOString().slice(0, 16).replace('T', ' ');
  }
}
