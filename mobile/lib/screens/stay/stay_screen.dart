// ─────────────────────────────────────────────────────────────
// STAY — تبويب «إقامتي» (نقل حرفي لـ guest-stay.tsx)
// بطاقة الغرفة بالصورة + الخط الزمني للإقامة + بيانات الحجز
// وجدول الليالي من لقطة الحجز + معلومات الفندق والسياسات
// + آخر الطلبات (3) — النصوص والقيم كما يعرضها الويب تمامًا
// ─────────────────────────────────────────────────────────────
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config.dart';
import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../models/guest.dart';
import '../../state/guest_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../requests/requests_screen.dart';
import '../shared/panels.dart';

/// تبويب «إقامتي» — نقطة الدخول الثابتة (يستهلكها GuestShell)
class StayScreen extends StatelessWidget {
  const StayScreen({super.key, required this.store});

  final GuestStore store;

  /// سحب للتحديث/إعادة المحاولة — رسالة ApiError تظهر توستًا حرفيًا
  Future<void> _refreshStay(BuildContext context) async {
    try {
      await store.refreshStay();
    } on ApiError catch (e) {
      if (context.mounted) {
        showAppToast(context, e.message, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        // الرحلة: تحميل أولي → خطأ/فراغ → المحتوى (كما في الويب)
        if (store.bootstrapLoading && store.stayDetail == null) {
          return const LoadingView();
        }
        final data = store.stayDetail;
        // الويب يعدّ غياب hotel ضمن حالة الخطأ (شرط !data.hotel)
        if (data == null || data.hotel == null) {
          return ErrorRetryView(
            message: 'تعذر تحميل تفاصيل الإقامة\nحدث خطأ في الاتصال — أعد المحاولة',
            onRetry: () => _refreshStay(context),
          );
        }
        return RefreshIndicator(
          onRefresh: () => _refreshStay(context),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Semantics(
                container: true,
                label: 'غرفة الإقامة',
                child: _RoomCardSection(data: data),
              ),
              const SizedBox(height: 20),
              Semantics(
                container: true,
                label: 'الخط الزمني للإقامة',
                child: _TimelineSection(data: data),
              ),
              const SizedBox(height: 20),
              Semantics(
                container: true,
                label: 'بيانات الحجز',
                child: _ReservationSection(data: data),
              ),
              const SizedBox(height: 20),
              Semantics(
                container: true,
                label: 'معلومات الفندق والسياسات',
                child: _HotelSection(data: data),
              ),
              const SizedBox(height: 20),
              Semantics(
                container: true,
                label: 'طلباتي الأخيرة',
                child: _LastRequestsSection(store: store),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────────────────── بطاقة الغرفة ──

/// بطاقة الغرفة: صورة h-44 بتدرج داكن + رقم الغرفة والطابق
/// + السرير والمساحة + مزايا الغرفة (نقل بطاقة «غرفتك»)
class _RoomCardSection extends StatelessWidget {
  const _RoomCardSection({required this.data});

  final StayDetail data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stay = data.stay;
    final roomType = stay.roomType;
    // صورة الغرفة الأولى — وبديل الويب الثابت عند غياب القائمة
    final imagePath = roomType.images.isEmpty
        ? '/images/room-deluxe.png'
        : roomType.images.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('غرفتك'),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الصورة (h-44 = 176px) مع التدرج الداكن وبيانات الغرفة
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: SizedBox(
                  height: 176,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Semantics(
                        image: true,
                        label: 'صورة ${roomType.name}',
                        child: Image.network(
                          '${AppConfig.baseUrl}$imagePath',
                          fit: BoxFit.cover,
                          // فشل التحميل → أيقونة بديلة (onerror في الويب)
                          errorBuilder: (_, __, ___) =>
                              _imageFallback(scheme, true),
                          // أثناء التحميل → رمادي صامت (كعرف التطبيق)
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                                  ? child
                                  : _imageFallback(scheme, false),
                        ),
                      ),
                      // تدرج أسود سفلي (from-black/70 via-black/10)
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Color(0xB3000000),
                              Color(0x1A000000),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 16,
                        left: 16,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    roomType.name,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xCCFFFFFF),
                                    ),
                                  ),
                                  // رقم الغرفة (dir=ltr في الويب)
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Text(
                                      stay.room.number,
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // شارة الطابق (bg-white/20 backdrop-blur)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: const BoxDecoration(
                                color: Color(0x33FFFFFF),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(999)),
                              ),
                              child: Text(
                                'الطابق ${stay.room.floor}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // محتوى البطاقة p-4: السرير/المساحة ثم المزايا
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _InfoPill(
                            icon: Icons.bed_rounded,
                            label: 'السرير',
                            value: roomType.bedConfig,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _InfoPill(
                            icon: Icons.straighten_rounded,
                            label: 'المساحة',
                            value: '${roomType.sizeSqm} م²',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'مزايا الغرفة',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final a in roomType.amenities) _AmenityChip(a),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// بديل الصورة: رمادي صامت أثناء التحميل وأيقونة معطلة عند الفشل
  Widget _imageFallback(ColorScheme scheme, bool broken) {
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: broken
          ? Icon(
              Icons.broken_image_outlined,
              size: 30,
              color: scheme.onSurfaceVariant,
            )
          : null,
    );
  }
}

/// شارة ميزة (نقل Badge secondary: pill بخلفية accent)
class _AmenityChip extends StatelessWidget {
  const _AmenityChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: scheme.onSurface,
        ),
      ),
    );
  }
}

/// حبة معلومة (نقل InfoPill: أيقونة + تسمية + قيمة داخل bg-muted/50)
class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    this.ltr = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final valueText = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ltr
              ? Directionality(
                  textDirection: TextDirection.ltr, child: valueText)
              : valueText,
        ],
      ),
    );
  }
}

// ───────────────────────────── الخط الزمني للإقامة ──

/// الخط الزمني: الوصول (منجز) → إقامتك الآن (حالي) → الخروج المتوقع
class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.data});

  final StayDetail data;

  @override
  Widget build(BuildContext context) {
    final stay = data.stay;
    final hotel = data.hotel!;
    final remaining = data.remainingNights;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('خط زمني الإقامة'),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _TimelineNode(
                icon: Icons.meeting_room_rounded,
                label: 'الوصول',
                date: formatDateWithDayAr(stay.checkInAt),
                done: true,
              ),
              _TimelineNode(
                icon: Icons.nightlight_round,
                label: 'إقامتك الآن',
                date:
                    'الخروج المتوقع: ${formatDateAr(stay.expectedCheckOutAt)} — حتى ${hotel.checkOutTime}',
                current: true,
              ),
              _TimelineNode(
                icon: Icons.swap_horiz_rounded,
                label: 'الخروج المتوقع',
                date:
                    '${formatDateWithDayAr(stay.expectedCheckOutAt)} — $remaining ${remaining == 1 ? 'ليلة متبقية' : 'ليالٍ متبقية'}',
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// عقدة الخط الزمني: دائرة (منجزة/حالية/عادية) + خط وصل + عنوان وتاريخ
class _TimelineNode extends StatelessWidget {
  const _TimelineNode({
    required this.icon,
    required this.label,
    required this.date,
    this.done = false,
    this.current = false,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String date;
  final bool done;
  final bool current;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // عمود العلامة: الدائرة + خط الوصل حتى العقدة التالية
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done
                        ? AppColors.successContainer
                        : current
                            ? scheme.primary
                            : scheme.surfaceContainerHighest,
                    // shadow-md للعقدة الحالية فقط (كما في الويب)
                    boxShadow: current
                        ? [
                            BoxShadow(
                              color: Colors.black.withAlpha(60),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: done
                      ? const Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: AppColors.success,
                        )
                      : Icon(
                          icon,
                          size: 13,
                          color: current
                              ? scheme.onPrimary
                              : scheme.onSurfaceVariant,
                        ),
                ),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        color: scheme.outlineVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      // شارة «الآن» للعقدة الحالية (bg-accent)
                      if (current) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(999)),
                          ),
                          child: Text(
                            'الآن',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── بيانات الحجز ──

/// بيانات الحجز: 4 حبات (مرجع/ضيوف/ليالٍ/إجمالي) + طلبات خاصة
/// + جدول الليالي من لقطة الحجز (إن وُجدت — شرط الويب)
class _ReservationSection extends StatelessWidget {
  const _ReservationSection({required this.data});

  final StayDetail data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stay = data.stay;
    final reservation = stay.reservation;
    final snapshot = data.snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('بيانات الحجز'),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _InfoPill(
                      icon: Icons.hotel_rounded,
                      label: 'مرجع الحجز',
                      value: reservation.bookingReference,
                      ltr: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoPill(
                      icon: Icons.group_rounded,
                      label: 'الضيوف',
                      value:
                          '${reservation.adults} بالغ${reservation.children > 0 ? ' + ${reservation.children} طفل' : ''}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoPill(
                      icon: Icons.nightlight_round,
                      label: 'الليالي',
                      value: '${data.nights} ${data.nights == 1 ? 'ليلة' : 'ليالٍ'}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoPill(
                      icon: Icons.open_in_full_rounded,
                      label: 'إجمالي الغرفة',
                      value: formatMoney(
                        reservation.grandTotalCents,
                        currency: reservation.currency,
                      ),
                      ltr: true,
                    ),
                  ),
                ],
              ),
              // طلبات خاصة عند الحجز (تظهر فقط عند وجود نص — شرط الويب)
              if ((reservation.specialRequests ?? '').isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withAlpha(153),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'طلبات خاصة عند الحجز: ',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        TextSpan(
                          text: reservation.specialRequests,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              // جدول الليالي من لقطة الحجز (snapshot قد يكون null — كالويب)
              if (snapshot != null && snapshot.nightly.isNotEmpty) ...[
                const SizedBox(height: 14),
                _NightsTable(snapshot: snapshot),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// جدول تفصيل الليالي (الليلة/السعر/السعر المعتمد + المجموع والضريبة)
class _NightsTable extends StatelessWidget {
  const _NightsTable({required this.snapshot});

  final StaySnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final head = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'تفصيل الليالي (لقطة الحجز)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // رأس الجدول (bg-muted/60)
              Container(
                color: scheme.surfaceContainerHighest.withAlpha(153),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(child: Text('الليلة', style: head)),
                    Expanded(child: Text('السعر', style: head)),
                    Expanded(child: Text('السعر المعتمد', style: head)),
                  ],
                ),
              ),
              // صفوف الليالي (تاريخ + سعر + اسم التعرفة)
              for (final n in snapshot.nightly)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: scheme.outlineVariant),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatDateAr(n.date),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            formatMoney(
                              n.priceCents,
                              currency: snapshot.currency,
                            ),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          n.rateName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // التذييل: المجموع قبل الضريبة + نسبة الضريبة (bg-muted/40)
              Container(
                color: scheme.surfaceContainerHighest.withAlpha(102),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'المجموع قبل الضريبة',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          formatMoney(
                            snapshot.subtotalCents,
                            currency: snapshot.currency,
                          ),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '+ ضريبة ${snapshot.taxPercent}%',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────── معلومات الفندق ──

/// معلومات الفندق: الاسم/المدينة/العنوان + الهاتف وأوقات الدخول/الخروج
/// + سياسات الفندق داخل Accordion (بند لا يظهر إلا بجسم غير فارغ)
class _HotelSection extends StatelessWidget {
  const _HotelSection({required this.data});

  final StayDetail data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hotel = data.hotel!;
    final city = hotel.city ?? '';
    final muted = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: scheme.onSurfaceVariant,
    );
    // السياسات الخمس — البند الفارغ يُحذف (Policy ترجع null في الويب)
    final policies = <(String, String)>[
      ('الإلغاء', hotel.cancellationPolicy ?? ''),
      ('الدفع', hotel.paymentPolicy ?? ''),
      ('الأطفال', hotel.childrenPolicy ?? ''),
      ('الحيوانات الأليفة', hotel.petsPolicy ?? ''),
      ('التدخين', hotel.smokingPolicy ?? ''),
    ].where((p) => p.$2.isNotEmpty).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('معلومات الفندق'),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                city.isEmpty ? hotel.name : '${hotel.name} — $city',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if ((hotel.address ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  hotel.address!,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 10),
              // صف الهاتف وأوقات الدخول/الخروج (gap-x-4 gap-y-1)
              Wrap(
                spacing: 16,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if ((hotel.phone ?? '').isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 12,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 4),
                        // الهاتف لاتيني باتجاه LTR (tel: في الويب)
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            hotel.phone!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.meeting_room_rounded,
                        size: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text('الدخول ${hotel.checkInTime}', style: muted),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // أيقونة موسعة مائلة 45° (Maximize rotate-45 في الويب)
                      Transform.rotate(
                        angle: math.pi / 4,
                        child: Icon(
                          Icons.open_in_full_rounded,
                          size: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('الخروج ${hotel.checkOutTime}', style: muted),
                    ],
                  ),
                ],
              ),
              // سياسات الفندق (Accordion في الويب)
              if (policies.isNotEmpty)
                Theme(
                  // إزالة الحدود الافتراضية للـ Accordion
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 4),
                    title: const Text(
                      'سياسات الفندق',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    children: [
                      for (var i = 0; i < policies.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              policies[i].$1,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              policies[i].$2,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                height: 1.7,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────── طلباتي (آخر 3) ──

/// طلباتي: آخر 3 طلبات — بطاقات مختصرة تنقل إلى شاشة الطلبات
/// (goRequests في الويب = تبويب الخدمات → طلباتي)
class _LastRequestsSection extends StatelessWidget {
  const _LastRequestsSection({required this.store});

  final GuestStore store;

  void _openRequests(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RequestsScreen(store: store),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requests = store.requests;
    final lastRequests = requests.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'طلباتي',
          // زر «كل الطلبات» يظهر فقط عند وجود طلبات (شرط الويب)
          action: requests.isEmpty
              ? null
              : TextButton(
                  onPressed: () => _openRequests(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(44, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'كل الطلبات',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
        ),
        if (store.requestsLoading && requests.isEmpty) ...[
          // هيكلا تحميل (Skeleton h-16 × 2 في الويب)
          const SkeletonBox(height: 64, radius: 16),
          const SizedBox(height: 8),
          const SkeletonBox(height: 64, radius: 16),
        ] else if (lastRequests.isEmpty)
          const DashedNote('لا طلبات بعد — اطلب أي خدمة من تبويب الخدمات')
        else
          Column(
            children: [
              for (var i = 0; i < lastRequests.length; i++) ...[
                _CompactRequestCard(
                  request: lastRequests[i],
                  onTap: () => _openRequests(context),
                ),
                if (i < lastRequests.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
      ],
    );
  }
}

/// بطاقة طلب مختصرة: العنوان + عاجل + المرجع/الوقت + شارة الحالة
class _CompactRequestCard extends StatelessWidget {
  const _CompactRequestCard({required this.request, required this.onTap});

  final ServiceRequestModel request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        // الضغط ينقل لشاشة الطلبات (goRequests في الويب)
        onTap: onTap,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          request.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      // شارة العاجل (UrgentMark في الويب)
                      if (request.priority == 'URGENT') ...[
                        const SizedBox(width: 6),
                        StatusChip.priority(context, 'URGENT'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${request.reference} — ${timeAgoAr(request.createdAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            StatusChip.requestStatus(context, request.status),
          ],
        ),
      ),
    );
  }
}
