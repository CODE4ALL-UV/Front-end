import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/services/api_service.dart';

class AvatarWidget extends StatelessWidget {
  final String? photoUrl;
  final String? name;
  final double size;
  final double radius;

  const AvatarWidget({
    Key? key,
    this.photoUrl,
    this.name,
    this.size = 40,
    this.radius = 20,
  }) : super(key: key);

  bool _looksLikePlaceholder(String s) {
    final blacklist = [
      'null',
      'none',
      'default',
      'placeholder',
      'noimage',
      'no_image',
      'no-avatar',
      'noavatar',
      'avatar.png',
      'user.png',
      'avatar_default',
      'placeholder.png',
    ];
    for (final token in blacklist) {
      if (s.contains(token)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = name?.trim().isNotEmpty == true ? name! : 'Usuario';
    final initials = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'U';
    final resolved = ApiService().resolveMediaUrl(photoUrl);
    final raw = (photoUrl ?? '').toString().trim().toLowerCase();

    final hasValidPhoto =
        resolved.isNotEmpty &&
        !_looksLikePlaceholder(raw) &&
        !raw.endsWith('/');

    final avatar = hasValidPhoto
        ? CircleAvatar(
            radius: radius,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: ClipOval(
              child: Image.network(
                resolved,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    initials,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          )
        : CircleAvatar(
            radius: radius,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              initials,
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          );

    return Semantics(
      label: 'Foto de perfil de $displayName',
      image: true,
      child: avatar,
    );
  }
}
