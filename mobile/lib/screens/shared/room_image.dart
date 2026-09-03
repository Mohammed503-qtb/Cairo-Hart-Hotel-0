// ─────────────────────────────────────────────────────────────
// ROOM IMAGE — صورة غرفة من الخادم (مقابل <img src="/images/rooms/…">)
// Image.network فوق AppConfig.baseUrl: تحميل رمادي + بديل أيقونة عند الفشل
// النسبة الافتراضية 16:9 كما في الويب
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../config.dart';

/// صورة غرفة بنسبة عرض ثابتة (16:9) — تستقبل المسار كما يأتي في JSON
class RoomImage extends StatelessWidget {
  const RoomImage({
    super.key,
    required this.path,
    this.aspectRatio = 16 / 9,
    this.alt,
  });

  /// مسار الصورة مثل /images/rooms/deluxe-1.jpg (أو null للبديل)
  final String? path;

  /// نسبة العرض إلى الارتفاع (16:9 افتراضيًا)
  final double aspectRatio;

  /// نص بديل وصفي (alt في الويب)
  final String? alt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final p = path;
    final url = (p == null || p.isEmpty) ? null : '${AppConfig.baseUrl}$p';
    Widget image;
    if (url == null) {
      image = _placeholder(scheme, broken: true);
    } else {
      image = Image.network(
        url,
        fit: BoxFit.cover,
        // فشل التحميل → أيقونة بديلة (مقابل onerror في الويب)
        errorBuilder: (_, __, ___) => _placeholder(scheme, broken: true),
        // أثناء التحميل → رمادي صامت (بدون مؤشر دوّار كما في الويب)
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder(scheme),
      );
    }
    if (alt != null) {
      image = Semantics(label: alt, image: true, child: image);
    }
    return AspectRatio(aspectRatio: aspectRatio, child: image);
  }

  Widget _placeholder(ColorScheme scheme, {bool broken = false}) => Container(
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
