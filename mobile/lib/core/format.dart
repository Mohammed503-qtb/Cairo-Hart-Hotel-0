// ─────────────────────────────────────────────────────────────
// FORMAT — أدوات عرض عربية (منقولة حرفيًا من src/lib/format.ts)
// نفس المخرجات: $1,234.50 · 10 سبتمبر 2026 · 02:30 م · منذ 5 دقائق
// ─────────────────────────────────────────────────────────────

const List<String> arMonths = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

const List<String> arDays = [
  'الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت',
];

/// $1,234.50
String formatMoney(int cents, {String currency = 'USD'}) {
  final value = cents / 100.0;
  final fixed = value.toStringAsFixed(2);
  final dot = fixed.indexOf('.');
  final intPart = dot == -1 ? fixed : fixed.substring(0, dot);
  final fracPart = dot == -1 ? '00' : fixed.substring(dot + 1);
  final grouped = _groupThousands(intPart);
  final num = '$grouped.$fracPart';
  return currency == 'USD' ? '\$$num' : '$num $currency';
}

String _groupThousands(String digits) {
  final negative = digits.startsWith('-');
  var d = negative ? digits.substring(1) : digits;
  final out = StringBuffer();
  final len = d.length;
  for (var i = 0; i < len; i++) {
    final remaining = len - i;
    out.write(d[i]);
    if (remaining > 1 && (remaining - 1) % 3 == 0) {
      out.write(',');
    }
  }
  final s = out.toString();
  return negative ? '-$s' : s;
}

/// تحليل تاريخ ISO أو null بأمان — التوقيت المحلي (مطابق new Date في الويب)
DateTime? tryParseDate(String? iso) {
  if (iso == null || iso.isEmpty) return null;
  final d = DateTime.tryParse(iso);
  if (d == null) return null;
  return d.isUtc ? d.toLocal() : d;
}

/// 10 سبتمبر 2026
String formatDateAr(String? iso) {
  final d = tryParseDate(iso);
  if (d == null) return '—';
  return '${d.day} ${arMonths[d.month - 1]} ${d.year}';
}

/// الخميس، 10 سبتمبر 2026
String formatDateWithDayAr(String? iso) {
  final d = tryParseDate(iso);
  if (d == null) return '—';
  return '${arDays[d.weekday % 7]}، ${formatDateAr(iso)}';
}

/// 02:30 م
String formatTimeAr(String? iso) {
  final d = tryParseDate(iso);
  if (d == null) return '—';
  final h = d.hour;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  final period = h < 12 ? 'ص' : 'م';
  final mm = d.minute.toString().padLeft(2, '0');
  return '$h12:$mm $period';
}

/// 10 سبتمبر 2026 — 02:30 م
String formatDateTimeAr(String? iso) {
  final d = tryParseDate(iso);
  if (d == null) return '—';
  return '${formatDateAr(iso)} — ${formatTimeAr(iso)}';
}

/// الآن / منذ 5 دقائق / منذ 3 ساعات / منذ يومين …
String timeAgoAr(String? iso, {DateTime? now}) {
  final d = tryParseDate(iso);
  if (d == null) return '—';
  final ref = now ?? DateTime.now();
  final diff = ref.difference(d);
  final mins = diff.inMinutes;
  if (mins < 1) return 'الآن';
  if (mins < 60) return 'منذ $mins دقيقة';
  final hours = mins ~/ 60;
  if (hours < 24) return 'منذ $hours ساعة';
  final days = hours ~/ 24;
  if (days < 30) return 'منذ $days يوم';
  return formatDateAr(iso);
}

// ───────────── تسميات الحالات الموحدة (عربي) ─────────────

const Map<String, String> reservationStatusLabels = {
  'PENDING': 'قيد الانتظار',
  'CONFIRMED': 'مؤكد',
  'CANCELLED': 'ملغي',
  'CHECKED_IN': 'مسجّل دخول',
  'COMPLETED': 'مكتمل',
  'NO_SHOW': 'لم يحضر',
  'EXPIRED': 'منتهي',
};

const Map<String, String> paymentStatusLabels = {
  'UNPAID': 'غير مدفوع',
  'PARTIALLY_PAID': 'مدفوع جزئيًا',
  'PAID': 'مدفوع',
  'REFUNDED': 'مُسترد',
};

const Map<String, String> paymentMethodLabels = {
  'PAY_AT_HOTEL': 'الدفع في الفندق',
  'CARD': 'بطاقة',
  'CASH': 'نقدًا',
  'ONLINE': 'دفع إلكتروني',
  'TRANSFER': 'حوالة',
};

const Map<String, String> roomStatusLabels = {
  'AVAILABLE': 'متاحة',
  'OCCUPIED': 'مشغولة',
  'RESERVED': 'محجوزة',
  'CLEANING': 'قيد التنظيف',
  'DIRTY': 'تحتاج تنظيف',
  'OUT_OF_ORDER': 'خارج الخدمة',
};

const Map<String, String> requestStatusLabels = {
  'NEW': 'جديد',
  'ACKNOWLEDGED': 'قيد الاطلاع',
  'ASSIGNED': 'مُسند',
  'IN_PROGRESS': 'قيد التنفيذ',
  'WAITING': 'انتظار',
  'COMPLETED': 'مكتمل',
  'CANCELLED': 'ملغي',
  'REJECTED': 'مرفوض',
};

const Map<String, String> priorityLabels = {
  'NORMAL': 'عادي',
  'URGENT': 'عاجل',
};

const Map<String, String> stayStatusLabels = {
  'ACTIVE': 'نشطة',
  'CHECKOUT_REQUESTED': 'طُلب الخروج',
  'CLOSED': 'مغلقة',
};

const Map<String, String> sourceLabels = {
  'WEBSITE': 'الموقع',
  'WHATSAPP': 'واتساب',
  'PHONE': 'هاتف',
  'WALK_IN': 'حضور مباشر',
  'RECEPTION': 'الاستقبال',
};

const Map<String, String> chargeCategoryLabels = {
  'SERVICE': 'خدمة',
  'EXTRA': 'إضافي',
  'PENALTY': 'غرامة',
  'ROOM_EXTENSION': 'تمديد إقامة',
};

const Map<String, String> extensionStatusLabels = {
  'PENDING': 'قيد المراجعة',
  'APPROVED': 'مقبول',
  'REJECTED': 'مرفوض',
};

String label(Map<String, String> map, String? key, {String fallback = '—'}) {
  return map[key] ?? fallback;
}

/// تاريخ اليوم بصيغة YYYY-MM-DD (لحقل التاريخ في طلب التمديد)
String todayInputValue() => _inputValue(DateTime.now());

String _inputValue(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

String addDaysInput(String value, int days) {
  final d = DateTime.tryParse('${value}T00:00:00');
  if (d == null) return value;
  return _inputValue(d.add(Duration(days: days)));
}

int nightsBetween(String a, String b) {
  final d1 = DateTime.tryParse('${a}T00:00:00');
  final d2 = DateTime.tryParse('${b}T00:00:00');
  if (d1 == null || d2 == null) return 0;
  return d2.difference(d1).inDays;
}
