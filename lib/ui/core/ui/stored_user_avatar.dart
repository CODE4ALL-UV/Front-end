import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/ui/core/ui/avatar_widget.dart';

class StoredUserAvatar extends StatelessWidget {
  final double size;
  final double radius;
  final bool showName;

  const StoredUserAvatar({
    Key? key,
    this.size = 28,
    this.radius = 14,
    this.showName = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final auth = AuthStorage();

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([auth.getName(), auth.getPhotoUrl()]),
      builder: (context, snapshot) {
        String displayName = 'Usuario';
        String? photoUrl;

        if (snapshot.hasData) {
          final data = snapshot.data!;
          final name = data[0] as String?;
          final photo = data[1] as String?;
          if (name != null && name.trim().isNotEmpty) displayName = name.trim();
          photoUrl = photo;
        }

        final textColor =
            Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;

        return Semantics(
          label: 'Perfil de $displayName',
          child: Row(
            children: [
              AvatarWidget(
                photoUrl: photoUrl,
                name: displayName,
                size: size,
                radius: radius,
              ),
              if (showName) ...[
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    displayName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textColor, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
