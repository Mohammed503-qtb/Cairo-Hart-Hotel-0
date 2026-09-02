// ─────────────────────────────────────────────────────────────
// REQUESTS LIST VIEW — أبنية عرض «طلباتي» المشتركة
// تستهلكها شاشة الخدمات (عرض طلباتي) وشاشة الطلبات المستقلة:
// هيئات تحميل → فراغ (مع زر تصفح الخدمات) → بطاقات الطلبات
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../models/guest.dart';
import '../../state/guest_store.dart';
import '../../ui/widgets.dart';
import '../shared/panels.dart';
import 'request_detail_screen.dart';

/// أبنية قائمة الطلبات (تحميل/فراغ/بطاقات) — تُدمج ضمن ListView
List<Widget> requestsViewChildren(
  GuestStore store, {
  VoidCallback? onBrowseServices,
}) {
  if (store.requestsLoading && store.requests.isEmpty) {
    // هيكل تحميل (مقابل Skeleton الثلاثة في الويب)
    return [
      for (var i = 0; i < 3; i++) ...[
        const SkeletonBox(height: 78),
        const SizedBox(height: 10),
      ],
    ];
  }
  if (store.requests.isEmpty) {
    return [
      EmptyState(
        icon: Icons.assignment_outlined,
        title: 'لا طلبات بعد',
        subtitle: 'اطلب أي خدمة من الكتالوج وستظهر هنا مع حالتها لحظة بلحظة',
      ),
      if (onBrowseServices != null) ...[
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.center,
          child: OutlinedButton(
            onPressed: onBrowseServices,
            child: const Text('تصفح الخدمات'),
          ),
        ),
      ],
    ];
  }
  return [
    for (final r in store.requests) ...[
      GuestRequestCard(store: store, request: r),
      const SizedBox(height: 10),
    ],
  ];
}

/// بطاقة طلب واحدة (نقل بطاقة motion-button في guest-services.tsx):
/// العنوان + عاجل + المرجع/الوقت + المسند إليه + الوصف + شارة الحالة
class GuestRequestCard extends StatelessWidget {
  const GuestRequestCard({
    super.key,
    required this.store,
    required this.request,
  });

  final GuestStore store;
  final ServiceRequestModel request;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = request;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openDetail(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              r.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (r.priority == 'URGENT') ...[
                            const SizedBox(width: 6),
                            StatusChip.priority(context, 'URGENT'),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      // المرجع بالاتجاه اللاتيني (dir=auto يلتقط LTR في الويب)
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          '${r.reference} — ${timeAgoAr(r.createdAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (r.assignedTo.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'المسند إلى: ${r.assignedTo}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusChip.requestStatus(context, r.status),
              ],
            ),
            if (r.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                r.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// فتح شاشة التفاصيل (مقابل setDetailRequest في الويب)
  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RequestDetailScreen(store: store, request: request),
      ),
    );
  }
}
