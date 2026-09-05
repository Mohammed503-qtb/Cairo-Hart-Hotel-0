# دليل الإعداد من الصفر — بيئة الإنتاج (P1)

> **فندق قلب القاهرة — عدن** · الحزمة: Task 24-c
> الهدف: من VPS جديد فارغ إلى موقع يعمل على `https://$DOMAIN` بنسخ احتياطي ومراقبة.
> كل الأوامر هنا حرفية قابلة للنسخ. لا يُستخدم أي أداة غير مثبتة — **systemd + caddy + bun فقط** (لا PM2 ولا Docker).

---

## 0) نظرة عامة على المعمارية

| المكوّن | ماذا يعمل | منفذ | ملاحظات |
|---|---|---|---|
| **cairo-hart-web** | تطبيق الويب (Next.js standalone عبر bun) | 3000 (محلي) | يُبنى بـ `bun run build` ويُدار بـ systemd |
| **cairo-hart-realtime** | خدمة الأحداث الفورية (socket.io) | 3002 للعملاء · 3004 بث داخلي | 3004 يستمع على `127.0.0.1` فقط — تطبيق الويب يبث إليه |
| **caddy** | البوابة العكسية + TLS تلقائي (Let's Encrypt) | 80/443 | يحوّل `/?XTransformPort=3002` إلى 3002، والباقي إلى 3000 |
| **SQLite** | قاعدة البيانات | ملف | `/opt/cairo-hart/db/custom.db` (WAL) |

المسارات الثابتة في كل الوثائق: `/opt/cairo-hart` (التطبيق) · `/etc/cairo-hart/env` (الأسرار) · `/var/backups/cairo-hart` (النسخ) · `/opt/cairo-hart/logs` (سجلات السكربتات).

**المتطلبات:** VPS بأي توزيعة Debian/Ubuntu حديثة (2 vCPU / 2GB RAM كافيان بسخاء) · نطاق مملوك مع سجل DNS من نوع `A` يشير إلى عنوان الخادم · وصول SSH بصلاحية root أولًا.

---

## 1) تحديث النظام والحزم الأساسية

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git sqlite3 ufw ca-certificates gnupg
```

## 2) تثبيت bun و caddy

**bun** (وقّته كجذر ثم انسخ الثنائي إلى مسار عام — وحدات systemd تعتمد على ذلك):

```bash
curl -fsSL https://bun.sh/install | bash
sudo install -m 0755 /root/.bun/bin/bun /usr/local/bin/bun
bun --version        # للتحقق
```

**caddy** (المستودع الرسمي):

```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install -y caddy
caddy version        # للتحقق
```

## 3) إنشاء مستخدم deploy

```bash
sudo adduser --disabled-password --gecos "" deploy
sudo mkdir -p /home/deploy/.ssh
sudo cp /root/.ssh/id_ed25519.pub /home/deploy/.ssh/authorized_keys   # أو مفتاحك أنت
sudo chown -R deploy:deploy /home/deploy/.ssh
sudo chmod 700 /home/deploy/.ssh && sudo chmod 600 /home/deploy/.ssh/authorized_keys
```

> من الآن فصاعدًا: ادخل SSH بمفتاح مستخدم `deploy`، واستخدم `sudo` للخطوات الإدارية فقط.

## 4) استنساخ المستودع إلى /opt/cairo-hart

```bash
sudo mkdir -p /opt/cairo-hart
sudo chown deploy:deploy /opt/cairo-hart
sudo -u deploy git clone <REPO_URL> /opt/cairo-hart
# مثال: sudo -u deploy git clone https://github.com/<OWNER>/cairo-hart.git /opt/cairo-hart
```

> ⚠️ مجلد `db/` **غير متتبَّع في git** (القاعدة مولّدة محليًا) — أنشئه يدويًا في الخطوة 6 وإلا فشلت الهجرات.

## 5) ملف البيئة + قاعدة sudoers

**ملف البيئة** (المصدر الوحيد للأسرار — لا يدخل المستودع أبدًا):

```bash
sudo mkdir -p /etc/cairo-hart
sudo cp /opt/cairo-hart/deploy/env.production.example /etc/cairo-hart/env
sudo nano /etc/cairo-hart/env     # عدّل DOMAIN إلى نطاقك الفعلي
sudo chown root:deploy /etc/cairo-hart/env
sudo chmod 600 /etc/cairo-hart/env
```

**قاعدة sudoers محدودة** (deploy.sh يحتاجها لإعادة تشغيل الخدمتين فقط — لا شيء آخر):

```bash
sudo tee /etc/sudoers.d/cairo-hart-deploy > /dev/null <<'EOF'
deploy ALL=(root) NOPASSWD: /usr/bin/systemctl restart cairo-hart-*, /usr/bin/systemctl start cairo-hart-*, /usr/bin/systemctl stop cairo-hart-*, /usr/bin/systemctl status cairo-hart-*, /usr/bin/systemctl kill cairo-hart-*
EOF
sudo chmod 440 /etc/sudoers.d/cairo-hart-deploy
sudo visudo -cf /etc/sudoers.d/cairo-hart-deploy   # يجب أن تطبع: parsed OK
```

> نطاق wildcard `cairo-hart-*` مقصود عمدًا: كل أوامر RUNBOOK وdeploy.sh توقف/تشغّل الوحدتين معًا في سطر واحد، والقاعدة تظل محصورة بوحدتينا (deploy لا يستطيع إنشاء وحدات systemd جديدة — ذلك يتطلب root).

## 6) الاعتماديات + الهجرات + البناء الأول (كمستخدم deploy)

```bash
sudo -iu deploy
cd /opt/cairo-hart
mkdir -p db logs

# الاعتماديات (الجذر + خدمة realtime)
bun install --frozen-lockfile
( cd mini-services/realtime && bun install --frozen-lockfile )

# توليد عميل Prisma ثم تطبيق الهجرات على قاعدة فارغة
bunx prisma generate
set -a; source /etc/cairo-hart/env; set +a
bunx prisma migrate deploy          # يجب أن يطبع: Database schema is up to date!

# البناء
bun run build
exit   # عودة من جلسة deploy إن كنت داخلها
```

## 7) تثبيت وحدتي systemd وتمكينهما

```bash
sudo cp /opt/cairo-hart/deploy/systemd/cairo-hart-web.service /etc/systemd/system/
sudo cp /opt/cairo-hart/deploy/systemd/cairo-hart-realtime.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now cairo-hart-realtime.service
sudo systemctl enable --now cairo-hart-web.service
systemctl status cairo-hart-web.service --no-pager -l
systemctl status cairo-hart-realtime.service --no-pager -l
```

> الترتيب مضمون بـ systemd: `cairo-hart-realtime` تشترط `Before=cairo-hart-web.service` — البث من الويب (127.0.0.1:3004) يجد الخدمة جاهزة.

## 8) تركيب Caddyfile الإنتاجي (مع export DOMAIN)

```bash
sudo cp /opt/cairo-hart/deploy/Caddyfile.prod /etc/caddy/Caddyfile
sudo systemctl edit caddy    # في المحرر أضف:
```

محتوى الـ drop-in:

```ini
[Service]
Environment=DOMAIN=hotel.example.com
```

ثم التحقق والإقلاع:

```bash
sudo caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
sudo systemctl restart caddy
sudo journalctl -u caddy -n 30 --no-pager    # ابحث عن سطور "certificate obtained" — شهادة Let's Encrypt
```

> **شرط الشهادة:** سجل DNS `A` للنطاق يشير إلى هذا الخادم + المنفذان 80/443 مفتوحان (الخطوة التالية).
> آلية `/?XTransformPort=3002` منقولة حرفيًا من بوابة البيئة الرملية — سلوك عملاء الويب والتطبيق لا يتغير.

## 9) الجدار الناري — 80/443 فقط

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
sudo ufw status verbose
```

> المنافذ 3000/3002/3004 تبقى محلية لا يصلها أحد من الخارج (البوابة هي الواجهة الوحيدة).

## 10) أول migrate + seed تشغيلي — مع تحذير AD-10

```bash
sudo -iu deploy
cd /opt/cairo-hart
set -a; source /etc/cairo-hart/env; set +a
bunx prisma migrate status          # 2 هجرات مطبقة: baseline + add_min_app_version
bun prisma/seed.ts                  # بيانات الفندق والغرف + طاقم وضيوف تجريبيون
exit
```

> ### ⚠️ تحذير AD-10 — بيانات العرض التجريبية
> بيانات seed الحالية **عرضية** (طاقم بأكواد تجريبية مثل `A371849L9`، ضيوف وحجوزات وإقامات تجريبية). **يجب مسحها قبل وصول أول ضيف حقيقي** — لا يُسمح بقيام أي كود تجريبي دائم في الإنتاج (MASTER_PLAN §3 AD-10).
>
> المسار المعتمد في الخطة: `scripts/purge-demo.ts`.
> **واقع الحزمة 24-c: هذا السكربت غير موجود في المستودع بعد.** حتى يُضاف (مهمة كود تابعة)، الطريق الموثق مؤقتًا:
> 1. من **الإدارة → الطاقم والأكواد**: إبطال **كل** أكواد الطاقم التجريبية (الإبطال يقتل الكود وجلساته فورًا)، ثم توليد أكواد حقيقية للطاقم الفعلي.
> 2. مراجعة الحجوزات/الإقامات التجريبية من **الإدارة → الحجوزات** وإلغاؤها/إغلاقها قبل الافتتاح.
> 3. أو المسار النظيف الكامل: `bunx prisma migrate reset --force && bun prisma/seed.ts` ثم إدخال البيانات التشغيلية الحقيقية قبل فتح الأبواب (يمسح كل شيء ويعيد التهيئة — بديل مقبول قبل أول ضيف فقط).
>
> التفصيل الكامل وقائمة إقلاع يوم الإطلاق: `docs/LAUNCH_PLAN.md`.

## 11) النسخ الاحتياطي والمراقبة (cron)

**السكربتات موجودة في المستودع** (Task 24-d/24-e) — تصل مع `git pull` ولا تحتاج إنشاءً يدويًا:

- `scripts/backup.sh` + `scripts/restore.sh` + `scripts/sqlite-tool.ts`: النسخ/الاستعادة فوق `bun:sqlite` (بلا اعتماد sqlite3) — السياسة في **docs/BACKUP_POLICY.md**
- `scripts/health-check.sh`: فحص كل 5 دقائق + تنبيه تغيّر الحالة — التفصيل في **docs/MONITORING.md**
- `scripts/purge-demo.ts` (AD-10) + `scripts/smoke.ts` (الفحص اليومي) — راجع **docs/DOGFOOD_PLAN.md**

```bash
sudo -iu deploy
cd /opt/cairo-hart && git pull
chmod 750 /opt/cairo-hart/scripts/*.sh
crontab -e
```

أسطر cron (لمستخدم deploy):

```cron
# نسخة احتياطية ليلية 02:00
0 2 * * * /opt/cairo-hart/scripts/backup.sh >> /opt/cairo-hart/logs/backup.log 2>&1
# فحص جاهزية كل 5 دقائق
*/5 * * * * /opt/cairo-hart/scripts/health-check.sh >> /opt/cairo-hart/logs/health.log 2>&1
```

```bash
sudo mkdir -p /var/backups/cairo-hart
sudo chown deploy:deploy /var/backups/cairo-hart
# أول نسخة يدوية فورًا (لا تنتظر الليل):
sudo -u deploy /opt/cairo-hart/scripts/backup.sh
```

## 12) التحقق النهائي

```bash
# الخدمات
systemctl is-active cairo-hart-web cairo-hart-realtime caddy   # الثلاثة: active

# الويب عبر البوابة (بعد استبدال النطاق أو تصديره)
export DOMAIN=hotel.example.com
curl -fsS https://$DOMAIN/api/public/hotel | head -c 200; echo
curl -fsS -o /dev/null -w '%{http_code}\n' https://$DOMAIN/

# خدمة الأحداث عبر البوابة (نفس مسار العملاء /?XTransformPort=3002)
curl -fsS "https://$DOMAIN/?XTransformPort=3002&EIO=4&transport=polling" | head -c 60; echo

# البث الداخلي (من الخادم فقط)
curl -fsS http://127.0.0.1:3004/health

# القاعدة
sudo -u deploy sqlite3 /opt/cairo-hart/db/custom.db "SELECT COUNT(*) FROM Hotel;"   # جدول الفندق بلا @@map — اسمه Hotel كما في schema.prisma
```

> **ملاحظة /api/health:** نقطة `/api/health` غير موجودة في الكود عند إعداد هذه الحزمة (24-c). حتى تُضاف (مهمة كود تابعة موصى بها)، فحص الصحة يستخدم `/api/public/hotel`، و`deploy.sh` يحمل الملاحظة نفسها في أعلى السكربت (`HEALTH_PATH`).

---

## النشر اليومي بعد الإقلاع الأول

كل تحديث لاحق يتم بسكربت واحد (بوابة نجاح/فشل + سجل rollback):

```bash
sudo -iu deploy
cd /opt/cairo-hart && bash deploy/deploy.sh
```

انظر تفصيل النشر والاسترجاع في `docs/RUNBOOK.md` (بطاقة IC-6).

---

## مشاكل شائعة

| العرَض | السبب الأرجح | الحل |
|---|---|---|
| `502 Bad Gateway` من المتصفح | خدمة الويب متوقفة أو منتهية قبل البوابة | `systemctl status cairo-hart-web.service` ثم `journalctl -u cairo-hart-web.service -n 50 --no-pager` — أصلح ثم `sudo systemctl restart cairo-hart-web.service` |
| caddy لا يحصل على شهادة (`certificate obtained` غائب) | سجل DNS لا يشير للخادم، أو 80/443 مقفلان | `dig +short $DOMAIN` يجب أن يعيد عنوان الخادم · `sudo ufw status` ثم `sudo systemctl restart caddy` ومراجعة `journalctl -u caddy -n 50` |
| الخدمة تفشل بـ `bun: command not found` | bun ليس في مسار systemd العام | `sudo install -m 0755 /root/.bun/bin/bun /usr/local/bin/bun` ثم `systemctl restart` |
| `deploy.sh` يفشل دائمًا عند فحص الصحة | `/api/health` غير موجودة في الكود بعد | افتح `deploy/deploy.sh` واضبط `HEALTH_PATH="/api/public/hotel"` (ملاحظة أعلى السكربت) |
| الموقع يعمل لكن التحديثات الفورية لا تصل | خدمة realtime متوقفة أو تحويل البوابة مكسور | بطاقة IC-4 في `docs/RUNBOOK.md` — `journalctl -u cairo-hart-realtime.service -n 50` واختبار `/?XTransformPort=3002` |
| `Error: SQLite database error` / فشل الهجرات في كتابة القاعدة | مجلد `db/` غير موجود أو لا يملكه deploy | `sudo mkdir -p /opt/cairo-hart/db && sudo chown deploy:deploy /opt/cairo-hart/db` |
| الخدمة تبدأ ثم تنهار فورًا مع `Read-only file system` | مسارات الكتابة خارج ReadWritePaths في وحدة systemd | تأكد أن البناء تم (`bun run build`) وأن الوحدة المثبتة من `deploy/systemd/` (ReadWritePaths تشمل `.next` و`db`) |
| `git pull --ff-only` مرفوض أثناء النشر | الشجرة غير نظيفة (تعديلات محلية على الخادم) | `git status` — الخادم تشغيلي لا تطويري: `git checkout -- .` أو استشر المطور إن كانت التغييرات مقصودة |
| رسائل Prisma: `DATABASE_URL` غير مضبطة | ملف env غير مقروء للمستخدم الحالي | `sudo chown root:deploy /etc/cairo-hart/env && sudo chmod 600 /etc/cairo-hart/env` (deploy يقرأه بصفته في المجموعة) |
| لا تنبيهات عند الأعطال | `ALERT_WEBHOOK` فارغ في env | أضف الـ webhook في `/etc/cairo-hart/env` (docs/MONITORING.md §التنبيه) |

---

## خريطة حزمة الإنتاج (Task 24-c)

| الملف | الغرض |
|---|---|
| `deploy/Caddyfile.prod` | بوابة الإنتاج (TLS تلقائي + آلية XTransformPort) |
| `deploy/systemd/cairo-hart-web.service` | وحدة systemd للويب |
| `deploy/systemd/cairo-hart-realtime.service` | وحدة systemd للأحداث الفورية |
| `deploy/deploy.sh` | النشر اليومي مع بوابة صحة وrollback |
| `deploy/env.production.example` | نموذج متغيرات الإنتاج |
| `deploy/README.md` | هذا الدليل |
| `docs/BACKUP_POLICY.md` | P2 — النسخ الاحتياطي والاستعادة |
| `docs/RESTORE_DRILL.md` | P2 — تدريب الاستعادة (بوابة الإطلاق 8.8) |
| `docs/MONITORING.md` | P3 — المراقبة والتنبيه |
| `docs/RUNBOOK.md` | P4 — دليل التشغيل وبطاقات الحوادث |
| `docs/SECURITY_CHECKLIST.md` | P6 — قائمة تحقق الأمن |
| `docs/PAYMENT_GATEWAY_DECISION.md` | P5 — وثيقة قرار بوابة الدفع (مفتوحة) |
| `docs/LAUNCH_PLAN.md` | P7 — خطة الإطلاق المرحلي |
