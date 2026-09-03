// ─────────────────────────────────────────────────────────────
// SERVICES — تبويب الخدمات (نقل guest-services.tsx)
// مبدّل (الكتالوج | طلباتي) + كتالوج الخدمات بالأقسام + طلباتي
// + صفيحة إنشاء الطلب (طلب خاص / من خدمة محددة) + تفاصيل الطلب
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../models/guest.dart';
import '../../state/guest_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import '../requests/new_request_sheet.dart';
import '../requests/requests_list_view.dart';
import '../shared/panels.dart';

/// تبويب الخدمات — نقطة الدخول الثابتة (يستخدمها GuestShell)
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key, required this.store});

  final GuestStore store;

  @override
  Widget build(BuildContext context) {
    return _ServicesView(store: store);
  }
}

class _ServicesView extends StatefulWidget {
  const _ServicesView({required this.store});

  final GuestStore store;

  @override
  State<_ServicesView> createState() => _ServicesViewState();
}

class _ServicesViewState extends State<_ServicesView> {
  int _view = 0; // 0 = الكتالوج · 1 = طلباتي (servicesView في الويب)

  Future<void> _refresh() async {
    try {
      await widget.store.refreshServices();
      await widget.store.refreshRequests();
    } on ApiError catch (e) {
      if (mounted) {
        showAppToast(context, e.message, error: true);
      }
    }
  }

  /// فتح صفيحة إنشاء طلب — [service] محددة من الكتالوج أو null لطلب خاص.
  /// بعد الإغلاق: إن نُشئ طلب جديد ننتقل لعرض «طلباتي» — نفس onCreated
  /// في الويب (refreshRequests يجري داخل المخزن + setServicesView('requests'))
  Future<void> _openRequestSheet({ServiceItem? service}) async {
    final before = widget.store.requests.length;
    await showNewRequestSheet(context, widget.store, presetService: service);
    if (!mounted) {
      return;
    }
    if (widget.store.requests.length > before) {
      setState(() => _view = 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              _viewToggle(context),
              const SizedBox(height: 16),
              if (_view == 0)
                ..._catalogChildren()
              else
                ...requestsViewChildren(
                  widget.store,
                  // زر «تصفح الخدمات» يعود للكتالوج (نفس الويب)
                  onBrowseServices: () => setState(() => _view = 0),
                ),
            ],
          ),
        );
      },
    );
  }

  /// مبدّل العرضين (نقل TabsList: الكتالوج / طلباتي بعدّاد)
  Widget _viewToggle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = widget.store.requests.length;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _toggleItem(
              context,
              selected: _view == 0,
              icon: Icons.room_service_rounded,
              label: 'الكتالوج',
              onTap: () => setState(() => _view = 0),
            ),
          ),
          Expanded(
            child: _toggleItem(
              context,
              selected: _view == 1,
              icon: Icons.assignment_outlined,
              label: 'طلباتي',
              badge: count > 0 ? count : null,
              onTap: () => setState(() => _view = 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleItem(
    BuildContext context, {
    required bool selected,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    int? badge,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.surface : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
                ),
              ),
              // عدّاد الطلبات (شارة primary كما في الويب)
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$badge',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: scheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// أبنية عرض الكتالوج (زر طلب خاص + الأقسام أو التحميل/الفراغ)
  List<Widget> _catalogChildren() {
    final store = widget.store;
    final categories = store.serviceCategories;
    return [
      // طلب خاص (خارج الكتالوج) — نفس preset الويب: OTHER بعنوان فارغ
      SizedBox(
        width: double.infinity,
        height: 44,
        child: OutlinedButton.icon(
          onPressed: () => _openRequestSheet(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('طلب خاص (خارج الكتالوج)'),
        ),
      ),
      const SizedBox(height: 20),
      if (store.servicesLoading && categories.isEmpty) ..._catalogSkeleton()
      else if (categories.isEmpty)
        const EmptyState(
          icon: Icons.auto_awesome,
          title: 'لا خدمات متاحة حاليًا',
          subtitle: 'يمكنك دائمًا استخدام «طلب خاص» أو مراسلة الاستقبال',
        )
      else ...[
        for (final cat in categories) ...[
          _categoryTitle(cat),
          const SizedBox(height: 12),
          for (var i = 0; i < cat.services.length; i++) ...[
            _ServiceCard(
              onRequest: () => _openRequestSheet(service: cat.services[i]),
              service: cat.services[i],
            ),
            if (i < cat.services.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
        ],
      ],
    ];
  }

  /// عنوان قسم بذهبية (نقل SectionTitle+CategoryIcon: sparkles/wrench/
  /// concierge-bell بذهبية text-gold — الاحتياط ConciergeBell كالويب)
  Widget _categoryTitle(ServiceCategory cat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(_categoryIcon(cat.icon), size: 16, color: AppColors.gold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cat.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  /// خريطة أيقونات الأقسام (أسماء lucide من قاعدة البيانات كما في bits.tsx)
  IconData _categoryIcon(String name) => switch (name) {
        'sparkles' => Icons.auto_awesome,
        'wrench' => Icons.build_rounded,
        _ => Icons.room_service_rounded,
      };

  /// هيكل تحميل الكتالوج (3 أقسام × عنوان + بطاقتان — كما في الويب)
  List<Widget> _catalogSkeleton() {
    return [
      for (var i = 0; i < 3; i++) ...[
        const SkeletonBox(height: 20, width: 130),
        const SizedBox(height: 8),
        const SkeletonBox(height: 64),
        const SizedBox(height: 8),
        const SkeletonBox(height: 64),
        const SizedBox(height: 20),
      ],
    ];
  }
}

/// بطاقة خدمة واحدة: الاسم + السعر (أو مجانًا) + زر طلب
class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onRequest});

  final ServiceItem service;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                if (service.priceCents > 0)
                  // السعر لاتيني — LTR كما في الويب (dir="ltr")
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      formatMoney(service.priceCents),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                  )
                else
                  Text(
                    'مجانًا ضمن الإقامة',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onRequest,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.add_rounded, size: 14),
            label: const Text('طلب'),
          ),
        ],
      ),
    );
  }
}
