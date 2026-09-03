-- F6-minAppVersion: الحد الأدنى لإصدار تطبيق الضيف (x.y.z) — فارغ = لا فرض
ALTER TABLE "Hotel" ADD COLUMN "minAppVersion" TEXT NOT NULL DEFAULT '';
