// ─────────────────────────────────────────────────────────────
// LOGIN — شاشة دخول كود الوصول (نقل code-login.tsx)
// + إعداد عنوان الخادم (عند غياب العنوان المخبوز)
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../config.dart';
import '../core/api_client.dart';
import '../state/session.dart';
import '../ui/widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _codeController = TextEditingController();
  final _serverController = TextEditingController();
  bool _showServerSettings = false;
  bool _showDemo = false;

  static const _demoGuestCode = 'H834729X7';

  @override
  void initState() {
    super.initState();
    if (AppConfig.canEditBaseUrl && AppConfig.baseUrl.isNotEmpty) {
      _serverController.text = AppConfig.baseUrl;
    }
    if (AppConfig.canEditBaseUrl && AppConfig.baseUrl.isEmpty) {
      // لا عنوان بعد — افتح الإعدادات مباشرة
      _showServerSettings = true;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  String _normalizeCode(String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  Future<void> _submit([String? preset]) async {
    var code = _normalizeCode(preset ?? _codeController.text);
    if (code.length > 9) {
      code = code.substring(0, 9);
    }
    if (code.isEmpty) {
      showAppToast(context, 'أدخل كود الدخول', error: true);
      return;
    }
    if (AppConfig.canEditBaseUrl && AppConfig.baseUrl.isEmpty) {
      final server = AppConfig.normalizeBaseUrl(_serverController.text);
      if (server.isEmpty) {
        showAppToast(context, 'أدخل عنوان الخادم أولًا', error: true);
        setState(() => _showServerSettings = true);
        return;
      }
      await AppConfig.setBaseUrl(_serverController.text);
    }
    try {
      final session = await widget.session.login(code);
      if (mounted) {
        showAppToast(context, 'أهلًا ${session.name} 👋');
      }
    } on ApiError catch (err) {
      if (mounted) {
        showAppToast(context, err.message, error: true);
        if (err.isNetwork) {
          setState(() => _showServerSettings = AppConfig.canEditBaseUrl);
        }
      }
    } catch (_) {
      if (mounted) {
        showAppToast(context, 'حدث خطأ غير متوقع', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final busy = widget.session.status == AppStatus.loggingIn;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Image.asset(
                    'assets/images/logo.png',
                    width: 96,
                    height: 96,
                    fit: BoxFit.contain,
                    semanticLabel: 'شعار فندق قلب القاهرة',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'فندق قلب القاهرة',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'تطبيق الضيف — إقامتك في راحة يدك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 28),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.key_rounded,
                                size: 20, color: scheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'أدخل كود الدخول',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _codeController,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.center,
                          maxLength: 9,
                          autofocus: true,
                          enabled: !busy,
                          keyboardType: TextInputType.visiblePassword,
                          autofillHints: const [AutofillHints.password],
                          onChanged: (v) => setState(() {}),
                          onSubmitted: (_) => _submit(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 6,
                          ),
                          decoration: const InputDecoration(
                            counterText: '',
                            hintText: 'H834729X7',
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed:
                              busy || _codeController.text.trim().isEmpty
                                  ? null
                                  : () => _submit(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('دخول'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'كود الضيف يصلك من الاستقبال عند تسجيل الوصول.\nالكود صالح حتى نهاية إقامتك فقط.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.7,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),

                        // ── إعدادات الخادم ──
                        if (AppConfig.canEditBaseUrl) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => setState(
                                () => _showServerSettings = !_showServerSettings),
                            icon: Icon(
                              _showServerSettings
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 18,
                            ),
                            label: const Text(
                              'إعدادات الخادم',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          if (_showServerSettings)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _serverController,
                                    textDirection: TextDirection.ltr,
                                    enabled: !busy,
                                    keyboardType: TextInputType.url,
                                    decoration: const InputDecoration(
                                      labelText: 'عنوان الخادم',
                                      hintText: 'https://hotel.example.com',
                                      prefixIcon: Icon(Icons.dns_rounded),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton.icon(
                                    onPressed: busy
                                        ? null
                                        : () async {
                                            await AppConfig.setBaseUrl(
                                                _serverController.text);
                                            if (context.mounted) {
                                              showAppToast(
                                                  context, 'تم حفظ عنوان الخادم');
                                            }
                                          },
                                    icon: const Icon(Icons.save_rounded,
                                        size: 18),
                                    label: const Text('حفظ العنوان'),
                                  ),
                                ],
                              ),
                            ),
                        ],

                        // ── أكواد تجريبية (لبيئة العرض فقط) ──
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () =>
                              setState(() => _showDemo = !_showDemo),
                          icon: Icon(
                            _showDemo
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 18,
                          ),
                          label: const Text(
                            'أكواد تجريبية للاختبار',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        if (_showDemo)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: busy
                                  ? null
                                  : () => _submit(_demoGuestCode),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                child: Row(
                                  children: [
                                    Text(
                                      _demoGuestCode,
                                      textDirection: TextDirection.ltr,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'monospace',
                                        color: scheme.primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'ضيف — خالد يوسف، غرفة 201',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: scheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_rounded,
                          size: 14, color: scheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'تحقق آمن من الخادم',
                        style: TextStyle(
                            fontSize: 11, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
