// ─────────────────────────────────────────────────────────────
// REQUESTS SCREEN — شاشة «طلباتي» المستقلة
// وجه Flutter لـ goRequests في الويب (تبويب الخدمات + عرض الطلبات):
// تُدفع من الرئيسية (متابعة طلباتي) ومن شاشة الإقامة (كل الطلبات)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../state/guest_store.dart';
import '../../ui/widgets.dart';
import '../services/services_screen.dart';
import '../shared/tab_route.dart';
import 'requests_list_view.dart';

/// شاشة قائمة الطلبات كاملة (نفس هيئات عرض طلباتي في تبويب الخدمات)
class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key, required this.store});

  final GuestStore store;

  Future<void> _refresh(BuildContext context) async {
    try {
      await store.refreshRequests();
    } on ApiError catch (e) {
      if (context.mounted) {
        showAppToast(context, e.message, error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلباتي')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: requestsViewChildren(
                store,
                // زر الفراغ في الويب يبدّل لعرض الكتالوج — هنا يستبدل الشاشة به
                onBrowseServices: () {
                  pushTabScreenReplacement(
                    context,
                    'الخدمات',
                    ServicesScreen(store: store),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
