/**
 * الأنواع المشتركة بين /api/plan والواجهة — عارض وثيقة MASTER_PLAN
 */

export interface PlanSubsection {
  id: string;
  title: string;
}

export interface PlanSection {
  id: string;
  order: number;
  title: string;
  content: string;
  subsections: PlanSubsection[];
}

export interface PlanMeta {
  title: string;
  subtitle: string;
  version: string;
  generatedAt: string;
}

export interface PlanStats {
  totalLines: number;
  sectionCount: number;
  subsectionCount: number;
  mustCount: number;
  mustNotCount: number;
  shouldCount: number;
}

export interface PlanResponse {
  meta: PlanMeta;
  stats: PlanStats;
  sections: PlanSection[];
}
