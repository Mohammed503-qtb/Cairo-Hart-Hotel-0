// ─────────────────────────────────────────────────────────────
// REQUEST DETAIL — تفاصيل الطلب (نقل request-detail-dialog.tsx — G-06)
// بطاقة الطلب (المرجع/الحالة/الأولوية/الوصف/الغرفة/الوقت) +
// سجل التحديثات (الخط الزمني) + زر إلغاء للحالتين NEW/ACKNOWLEDGED فقط
// الإلغاء مباشر بلا حوار تأكيد — الويب يلغي فورًا عند الضغط
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../models/guest.dart';
import '../../state/guest_store.dart';
import '../../ui/theme.dart';
import '../../ui/widgets.dart';
import 'new_request_sheet.dart' show requestCategoryLabels;

/// شاشة تفاصيل الطلب — تُفتح من بطاقات «طلباتي»
class RequestDetailScreen extends StatelessWidget {
  const RequestDetailScreen({
    super.key,
    required this.store,
    required this.request,
  });

  final GuestStore store;

  /// لقطة الطلب عند الفتح (تُنعش حيًّا من المخزن إن وُجدت نسخة أحدث)
  final ServiceRequestModel request;

  @override
  Widget build(BuildContext context) {
    return _RequestDetailView(store: store, request: request);
  }
}

class _RequestDetailView extends StatefulWidget {
  const _RequestDetailView({required this.store, required this.request});

  final GuestStore store;
  final ServiceRequestModel request;

  @override
  State<_RequestDetailView> createState() => _RequestDetailViewState();
}

class _RequestDetailViewState extends State<_RequestDetailView> {
  bool _cancelling = false;

  /// النسخة الحية من قائمة المخزن إن وُجدت — تُنعش الشاشة عبر Realtime
  ServiceRequestModel _currentRequest() {
    for (final r in widget.store.requests) {
      if (r.id == widget.request.id) {
        return r;
      }
    }
    return widget.request;
  }

  /// G-06: إلغاء الطلب — مثل الويب: بلا تأكيد، الزر ينفذ مباشرة
  Future<void> _cancel(ServiceRequestModel req) async {
    if (_cancelling) {
      return;
    }
    setState(() => _cancelling = true);
    try {
      // المخزن يحدّث قائمة الطلبات داخليًا (onChanged في الويب)
      await widget.store.cancelRequest(req.id);
      if (!mounted) {
        return;
      }
      // نص النجاح في الويب: العنوان + المرجع وصفًا
      showAppToast(context, 'تم إلغاء الطلب\n${req.reference}');
      Navigator.of(context).pop();
    } on ApiError catch (e) {
      if (!mounted) {
        return;
      }
      // رسالة الخادم الحرفية (منهج 13-b المتبع في كل الحوارات)
      showAppToast(context, e.message, error: true);
    } finally {
      if (mounted) {
        setState(() => _cancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final req = _currentRequest();
        // الإلغاء مسموح فقط لـ NEW/ACKNOWLEDGED (قائمة CANCELLABLE بالويب)
        final cancellable =
            req.status == 'NEW' || req.status == 'ACKNOWLEDGED';
        return Scaffold(
          appBar: AppBar(
            title: Text(
              req.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _requestCard(context, req),
                const Divider(height: 32),
                _updatesSection(context, req),
              ],
            ),
          ),
          bottomNavigationBar: cancellable ? _cancelBar(req) : null,
        );
      },
    );
  }

  /// بطاقة الطلب: المرجع/الغرفة/القسم + الحالة والأولوية والوقت +
  /// الوصف + المسند إليه (ترتيب عناصر الحوار في الويب)
  Widget _requestCard(BuildContext context, ServiceRequestModel req) {
    final scheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // سطر الوصف في الويب: المرجع · الغرفة · القسم
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  req.reference,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                'الغرفة ${req.roomNumber}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                label(requestCategoryLabels, req.category,
                    fallback: req.category),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // الحالة + (عاجل عند URGENT فقط — مثل UrgentMark) + وقت الإنشاء
          Row(
            children: [
              StatusChip.requestStatus(context, req.status),
              if (req.priority == 'URGENT') ...[
                const SizedBox(width: 8),
                StatusChip.priority(context, 'URGENT'),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'أُنشئ ${timeAgoAr(req.createdAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (req.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                req.description,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.7,
                ),
              ),
            ),
          ],
          if (req.assignedTo.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  'المسند إلى: ',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Flexible(
                  child: Text(
                    req.assignedTo,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// قسم سجل الطلب: العنوان بأيقونة + الخط الزمني للتحديثات
  Widget _updatesSection(BuildContext context, ServiceRequestModel req) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.assignment_outlined, size: 16, color: scheme.primary),
            const SizedBox(width: 8),
            const Text(
              'سجل الطلب',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _updatesTimeline(context, req.updates),
      ],
    );
  }

  /// الخط الزمني للتحديثات (تصاعديًا كما يرسلها الخادم) —
  /// آخر تحديث بعلامة تم الخضراء والبقية نقاط على خط متصل
  Widget _updatesTimeline(BuildContext context, List<RequestUpdate> updates) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < updates.length; i++)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // عمود العلامات (يمين RTL مثل border-r-2 في الويب):
                // دائرة + خط متصل نحو العنصر التالي
                SizedBox(
                  width: 26,
                  child: Column(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == updates.length - 1
                              ? AppColors.successContainer
                              : scheme.surfaceContainerHighest,
                        ),
                        child: i == updates.length - 1
                            ? const Icon(
                                Icons.check_circle_rounded,
                                size: 13,
                                color: AppColors.success,
                              )
                            : Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                      ),
                      if (i < updates.length - 1)
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
                    padding: EdgeInsets.only(
                      bottom: i == updates.length - 1 ? 0 : 18,
                    ),
                    child: _updateItem(context, updates[i]),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _updateItem(BuildContext context, RequestUpdate u) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (u.status.isNotEmpty)
              Text(
                label(requestStatusLabels, u.status, fallback: u.status),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            Text(
              formatDateTimeAr(u.createdAt),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (u.note.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            u.note,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.6,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 2),
        Text(
          'بواسطة ${u.byName}${u.byRole == 'GUEST' ? ' (أنت)' : ''}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// شريط الإلغاء الثابت (destructive كما في الويب — «جارٍ الإلغاء…» عند busy)
  Widget _cancelBar(ServiceRequestModel req) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: _cancelling ? null : () => _cancel(req),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            icon: _cancelling
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.block_rounded, size: 18),
            label: Text(_cancelling ? 'جارٍ الإلغاء…' : 'إلغاء الطلب'),
          ),
        ),
      ),
    );
  }
}
