-- CMS — محتوى الموقع القابل للإدارة من لوحة الإدارة
-- قيمة JSON لكل قسم: header | hero | rooms | facilities | gallery | contact | footer
-- العقود والتنقية: src/lib/site-content.ts — القراءة تدمج فوق DEFAULT_CONTENT

-- CreateTable
CREATE TABLE "site_content" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "key" TEXT NOT NULL,
    "value" TEXT NOT NULL DEFAULT '{}',
    "updatedAt" DATETIME NOT NULL,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateIndex
CREATE UNIQUE INDEX "site_content_key_key" ON "site_content"("key");
