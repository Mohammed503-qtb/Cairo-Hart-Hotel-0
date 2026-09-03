// ─────────────────────────────────────────────────────────────
// CHAT — شاشة المحادثة مع الاستقبال (نقل chat-dialog.tsx)
// فقاعات RTL + فاصل أيام + إرسال (Enter) + تمرير تلقائي
// + Realtime عبر المخزن + استطلاع احتياطي كل 12 ثانية (كالويب)
// ─────────────────────────────────────────────────────────────
import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/format.dart';
import '../../models/guest.dart';
import '../../state/guest_store.dart';
import '../../ui/widgets.dart';

/// شاشة كاملة للمحادثة — نقطة الدخول الثابتة (يستخدمها GuestShell)
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.store});

  final GuestStore store;

  @override
  Widget build(BuildContext context) {
    return _ChatView(store: store);
  }
}

class _ChatView extends StatefulWidget {
  const _ChatView({required this.store});

  final GuestStore store;

  @override
  State<_ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<_ChatView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Timer? _pollTimer; // استطلاع احتياطي كل 12 ثانية (نفس الويب)
  bool _sending = false;
  bool _atBottom = true;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _lastCount = widget.store.messages.length;
    // الاستماع للمخزن: الرسائل الجديدة عبر Realtime تعيد التمرير للأسفل
    widget.store.addListener(_onStoreChanged);
    _scrollController.addListener(_onScroll);
    _pollTimer = Timer.periodic(
      const Duration(seconds: 12),
      (_) => _refreshSilently(),
    );
    _initialRefresh();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    widget.store.removeListener(_onStoreChanged);
    _textController.dispose();
    super.dispose();
  }

  /// عند الفتح: تحميل الرسائل ثم تمرير لآخر رسالة (كالويب)
  Future<void> _initialRefresh() async {
    try {
      await widget.store.refreshMessages();
    } on ApiError catch (e) {
      if (mounted) {
        showAppToast(context, e.message, error: true);
      }
    }
    if (mounted) {
      _scheduleScrollToBottom();
    }
  }

  /// الاستطلاع الدوري: أخطاؤه صامتة (نفس سلوك الويب)
  Future<void> _refreshSilently() async {
    try {
      await widget.store.refreshMessages();
    } on ApiError {
      // تجاهل — الويب يتجاهل أخطاء الاستطلاع أيضًا
    }
  }

  /// هل المستخدم قرب أسفل القائمة؟ (لقرارات التمرير التلقائي)
  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final position = _scrollController.position;
    _atBottom = position.pixels >= position.maxScrollExtent - 96;
  }

  /// رسائل جديدة (Realtime) — تمرير للأسفل إن كان المستخدم في الأسفل
  void _onStoreChanged() {
    final count = widget.store.messages.length;
    if (count == _lastCount) {
      return;
    }
    final grew = count > _lastCount;
    _lastCount = count;
    if (grew && _atBottom) {
      _scheduleScrollToBottom();
    }
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      final position = _scrollController.position;
      _scrollController.jumpTo(position.maxScrollExtent);
    });
  }

  Future<void> _send() async {
    final body = _textController.text.trim();
    if (body.isEmpty || _sending) {
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.store.sendMessage(body);
      _textController.clear();
      _scheduleScrollToBottom();
    } on ApiError catch (e) {
      if (mounted) {
        showAppToast(context, e.message, error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  /// مفتاح اليوم YYYY-MM-DD بالتوقيت المحلي (نفس dayKey في الويب)
  String? _dayKeyOf(String iso) {
    final d = tryParseDate(iso)?.toLocal();
    if (d == null) {
      return null;
    }
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }

  String _keyOf(DateTime d) {
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$month-$day';
  }

  /// تسمية فاصل اليوم: اليوم / أمس / تاريخ عربي (نفس dayLabel في الويب)
  String _dayLabel(String key) {
    final now = DateTime.now();
    if (key == _keyOf(now)) {
      return 'اليوم';
    }
    if (key == _keyOf(now.subtract(const Duration(days: 1)))) {
      return 'أمس';
    }
    return formatDateAr(key);
  }

  /// تجميع الرسائل بفواصل أيام (نفس بنية groups في الويب)
  List<_ChatEntry> _buildEntries(List<ChatMessage> messages) {
    final entries = <_ChatEntry>[];
    String? lastKey;
    for (final message in messages) {
      final key = _dayKeyOf(message.createdAt);
      if (key == null) {
        continue;
      }
      if (key != lastKey) {
        entries.add(_ChatEntry.day(_dayLabel(key)));
        lastKey = key;
      }
      entries.add(_ChatEntry.message(message));
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_rounded,
                size: 17,
                color: scheme.onPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'محادثة الاستقبال',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                  Text(
                    'ردود فورية خلال دقائق — نسعد بخدمتك',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: widget.store,
              builder: (context, _) {
                final store = widget.store;
                if (store.messagesLoading && store.messages.isEmpty) {
                  return const LoadingView();
                }
                if (store.messages.isEmpty) {
                  return const EmptyState(
                    icon: Icons.chat_bubble_outline,
                    title: 'لا رسائل بعد',
                    subtitle: 'ابدأ المحادثة — اكتب تحيتك وسيرد الاستقبال فورًا',
                  );
                }
                return Semantics(
                  label: 'رسائل المحادثة',
                  child: Container(
                    color: scheme.surfaceContainerHighest,
                    child: _messagesList(store.messages),
                  ),
                );
              },
            ),
          ),
          _inputBar(scheme),
        ],
      ),
    );
  }

  Widget _messagesList(List<ChatMessage> messages) {
    final entries = _buildEntries(messages);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final day = entry.dayLabel;
        if (day != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(child: _DayChip(label: day)),
          );
        }
        return _MessageBubble(message: entry.message!);
      },
    );
  }

  /// حقل الإرسال السفلي: نص + زر (Enter يرسل — فارغ = معطّل كما في الويب)
  Widget _inputBar(ColorScheme scheme) {
    final canSend = !_sending && _textController.text.trim().isNotEmpty;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                enabled: !_sending,
                maxLength: 1000,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                onChanged: (_) {
                  if (mounted) {
                    setState(() {});
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالتك…',
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              height: 48,
              child: Tooltip(
                message: 'إرسال الرسالة',
                child: FilledButton(
                  onPressed: canSend ? _send : null,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 48),
                  ),
                  child: _sending
                      ? _busySpinner
                      : Transform.flip(
                          flipX: true,
                          child: const Icon(Icons.send_rounded, size: 20),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// عنصر قائمة المحادثة: فاصل يوم أو رسالة
class _ChatEntry {
  const _ChatEntry.day(this.dayLabel) : message = null;

  const _ChatEntry.message(this.message) : dayLabel = null;

  final String? dayLabel;
  final ChatMessage? message;
}

/// شريحة فاصل اليوم (اليوم/أمس/تاريخ)
class _DayChip extends StatelessWidget {
  const _DayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// فقاعة رسالة: الضيف بلون primary في بداية القراءة (يمين RTL)
/// والاستقبال ببطاقة رمادية في نهاية القراءة — كما في الويب
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final own = message.fromGuest; // sender == 'GUEST'
    return Align(
      alignment: own
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.8,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 5),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: own ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadiusDirectional.only(
              // زاوية صغيرة أعلى جهة البداية/النهاية كما في الويب
              topStart: Radius.circular(own ? 6 : 16),
              topEnd: Radius.circular(own ? 16 : 6),
              bottomStart: const Radius.circular(16),
              bottomEnd: const Radius.circular(16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // اسم المرسل يظهر لرسائل الاستقبال فقط (كما في الويب)
              if (!own)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                ),
              Text(
                message.body,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: own ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
              const SizedBox(height: 3),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  formatTimeAr(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: own
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// مؤشر انشغال صغير لزر الإرسال (18×18)
const Widget _busySpinner = SizedBox(
  width: 18,
  height: 18,
  child: CircularProgressIndicator(strokeWidth: 2.2),
);
