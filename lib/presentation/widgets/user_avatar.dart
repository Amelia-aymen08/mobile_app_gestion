import 'package:flutter/material.dart';
import '../../data/api_service.dart';
import '../theme/app_theme.dart';

/// Round profile picture with an initials fallback (no photo, or it failed to load).
class UserAvatar extends StatelessWidget {
  final String? photo; // "/uploads/avatars/x.jpg" or absolute URL
  final String name;
  final double size;
  final Color? ringColor;

  const UserAvatar({
    super.key,
    required this.photo,
    required this.name,
    this.size = 48,
    this.ringColor,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((p) => p.characters.first).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final url = ApiService().mediaUrl(photo);
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      color: brandAmber.withValues(alpha: 0.16),
      child: Text(_initials,
          style: TextStyle(
              color: brandAmber,
              fontWeight: FontWeight.w800,
              fontSize: size * 0.36)),
    );

    final avatar = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url == null
            ? fallback
            : Image.network(url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback),
      ),
    );

    if (ringColor == null) return avatar;
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(shape: BoxShape.circle, color: ringColor),
      child: avatar,
    );
  }
}
