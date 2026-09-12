import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/session_controller.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class UserProfileMenu extends StatefulWidget {
  final String? userName;
  final String? userPhotoUrl;
  final String? userEmail;
  final String? userRole;
  final VoidCallback? onLogout;
  final bool showName;

  const UserProfileMenu({
    super.key,
    this.userName,
    this.userPhotoUrl,
    this.userEmail,
    this.userRole,
    this.onLogout,
    this.showName = true,
  });

  @override
  State<UserProfileMenu> createState() => _UserProfileMenuState();
}

class _UserProfileMenuState extends State<UserProfileMenu> {
  final AuthStorage _authStorage = AuthStorage();
  final ApiService _apiService = ApiService();
  String _userName = '';
  String? _userPhotoUrl;
  String? _userEmail;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _userName = widget.userName?.trim().isNotEmpty == true
        ? widget.userName!
        : '';
    _userPhotoUrl = widget.userPhotoUrl;
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant UserProfileMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userName != oldWidget.userName ||
        widget.userPhotoUrl != oldWidget.userPhotoUrl) {
      setState(() {
        _userName = widget.userName?.trim().isNotEmpty == true
            ? widget.userName!
            : '';
        _userPhotoUrl = widget.userPhotoUrl;
      });
    }
  }

  Future<void> _loadProfile() async {
    final storedName = await _authStorage.getName();
    final storedEmail = await _authStorage.getEmail();
    final storedPhotoUrl = await _authStorage.getPhotoUrl();
    final storedRole = await _authStorage.getRole();

    if (!mounted) return;

    setState(() {
      _userName = (storedName?.trim().isNotEmpty ?? false)
          ? storedName!
          : (widget.userName?.trim().isNotEmpty ?? false
                ? widget.userName!
                : '');
      _userPhotoUrl = storedPhotoUrl?.trim().isNotEmpty == true
          ? storedPhotoUrl
          : widget.userPhotoUrl;
      _userEmail = storedEmail;
      _userRole = storedRole;
    });
  }

  void _handleLogout() {
    // El borrado se lanza, pero **no se espera**. El almacenamiento seguro no
    // siempre responde —en algunos navegadores se queda colgado sin error— y
    // esperandolo el boton no hacia nada por mucho que se pulsara: la persona
    // quedaba atrapada dentro de la sesion.
    //
    // Salir es lo importante y no depende del disco. Se lanza antes de
    // navegar para que el borrado ya este en marcha si alguien entra
    // inmediatamente despues con otra cuenta.
    unawaited(_authStorage.clear());

    if (!mounted) return;

    setState(() {
      _userName = '';
      _userPhotoUrl = null;
      _userEmail = null;
      _userRole = null;
    });

    if (widget.onLogout != null) {
      widget.onLogout!.call();
      return;
    }

    // Sin funcion propia se recurre a la que registro la aplicacion. Es lo
    // que permite poner este menu dentro de una lectura o de un editor, donde
    // nadie puede pasarle como volver al login.
    if (SessionController.instance.logout()) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked == null) return;

    final userId = await _authStorage.getUserId();
    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró el usuario para subir la foto.'),
        ),
      );
      return;
    }

    late final http.MultipartFile multipartFile;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: picked.name.isNotEmpty ? picked.name : 'avatar.jpg',
      );
    } else {
      final file = io.File(picked.path);
      multipartFile = await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'avatar.jpg',
      );
    }

    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse(_apiService.buildUrl('/api/user/upload-photo')),
          )
          ..fields['user_id'] = userId.toString()
          ..files.add(multipartFile);

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        throw Exception(response.body);
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final photoUrl = decoded['photo_url']?.toString() ?? '';
      await _authStorage.savePhotoUrl(photoUrl);
      if (!mounted) return;
      setState(() {
        _userPhotoUrl = photoUrl;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto actualizada correctamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo subir la foto: $e')));
    }
  }

  void _showProfileDialog() {
    final displayName = _userName.trim().isNotEmpty ? _userName : 'Usuario';
    final displayRole = (_userRole ?? 'estudiante').toString().toUpperCase();

    showDialog<void>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Row(
            children: [
              _buildAvatar(size: 42, radius: 21),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      displayRole,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Text(
            _userEmail?.isNotEmpty == true
                ? 'Correo: $_userEmail'
                : 'Tu perfil está listo para mostrar tus datos de usuario.',
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();
                await _pickAndUploadPhoto();
              },
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Subir foto'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAvatar({required double size, required double radius}) {
    final theme = Theme.of(context);
    final displayName = _userName.trim().isNotEmpty ? _userName : 'U';
    final initials = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'U';
    final resolvedPhotoUrl = _apiService.resolveMediaUrl(_userPhotoUrl);

    // Treat some placeholder values ('null', 'default') and common placeholders as empty
    final raw = (_userPhotoUrl ?? '').toString().trim().toLowerCase();
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

    bool looksLikePlaceholder(String s) {
      for (final token in blacklist) {
        if (s.contains(token)) return true;
      }
      return false;
    }

    final hasValidPhoto =
        resolvedPhotoUrl.isNotEmpty &&
        !looksLikePlaceholder(raw) &&
        !raw.endsWith('/');

    if (hasValidPhoto) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.network(
            resolvedPhotoUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // El circulo va en blanco y la inicial en color, no al reves: este avatar
    // se dibuja sobre la barra superior, que es roja o casi negra segun el
    // tema. Usando el color principal de fondo se confundia con la barra y
    // parecia una letra suelta flotando.
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: Text(
        initials,
        style: TextStyle(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasProfileData =
        _userName.trim().isNotEmpty ||
        (_userPhotoUrl?.trim().isNotEmpty ?? false) ||
        (_userEmail?.trim().isNotEmpty ?? false) ||
        (_userRole?.trim().isNotEmpty ?? false);

    if (!hasProfileData) {
      return const SizedBox.shrink();
    }

    final displayName = _userName.trim().isNotEmpty ? _userName : '';

    return PopupMenuButton<String>(
      tooltip: 'Opciones de perfil',
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == 'profile') {
          _showProfileDialog();
        } else if (value == 'logout') {
          _handleLogout();
        }
      },
      // El color va explicito. Sin el, los iconos heredan el blanco de la
      // barra de arriba y desaparecen sobre el fondo claro del menu: se veia
      // el texto pero no el icono.
      itemBuilder: (context) {
        final onMenu = theme.colorScheme.onSurface;

        return [
          PopupMenuItem<String>(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.person_outline, color: onMenu),
                const SizedBox(width: 8),
                Text('Mi perfil', style: TextStyle(color: onMenu)),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout, color: onMenu),
                const SizedBox(width: 8),
                Text('Cerrar sesión', style: TextStyle(color: onMenu)),
              ],
            ),
          ),
        ];
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAvatar(size: 34, radius: 17),
            if (widget.showName) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: Text(
                  displayName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
