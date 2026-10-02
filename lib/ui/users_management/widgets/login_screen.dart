import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code4all/data/models/auth_models.dart';
import 'package:flutter_code4all/data/services/api_service.dart';
import 'package:flutter_code4all/data/services/auth_storage.dart';
import 'package:flutter_code4all/ui/core/ui/appbar_widget.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_reading_state_widget.dart';
import 'package:flutter_code4all/ui/core/ui/accessibility_toolbar_widget.dart';
import 'package:flutter_code4all/ui/core/ui/braille_keyboard_screen.dart';
import 'package:flutter_code4all/ui/core/ui/social_auth_block.dart';
import 'package:flutter_code4all/data/services/google_auth_service.dart';
import 'package:flutter_code4all/data/services/voice_dictation_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onRegister;
  final void Function(String role)? onSuccess;

  const LoginScreen({
    super.key,
    this.onRegister,
    this.onSuccess,
    this.dictation,
  });

  /// Para las pruebas. Sin él se dicta con el micrófono de verdad.
  final VoiceDictation? dictation;

  /// Lo que se ve encima del correo y lo que dice la voz al abrir el login.
  static const String brailleHint =
      '¿No ves la pantalla? Toca dos veces en cualquier parte para escribir '
      'en Braille con asistente de voz.';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final _authStorage = AuthStorage();
  final _googleAuthService = GoogleAuthService();
  bool _isLoading = false;

  /// Si se entró con el teclado Braille. Entonces los avisos —contraseña
  /// corta, credenciales malas, bienvenida— además de verse se dicen en voz
  /// alta: quien lo usa normalmente no ve el mensaje de abajo.
  bool _voiceMode = false;
  bool _brailleOpen = false;

  late final VoiceDictation _dictation =
      widget.dictation ?? SpeechToTextDictation();

  /// Qué campo está escuchando el micrófono ahora mismo, si alguno.
  TextEditingController? _listeningTo;

  /// Escribe en [controller] lo que se diga por el micrófono.
  ///
  /// Es el botón del micrófono de cada campo, para quien ve pero no puede o
  /// no quiere teclear. Lo dicho se limpia según el campo: en el correo
  /// «arroba» pasa a ser @ y se quitan los espacios.
  Future<void> _dictateInto(
    TextEditingController controller,
    DictationKind kind,
  ) async {
    if (_listeningTo != null) {
      await _dictation.stop();
      return;
    }

    setState(() => _listeningTo = controller);
    await accessibilityReadingState.stop();
    await _dictation.cue(start: true);
    await Future<void>.delayed(const Duration(milliseconds: 250));

    String? heard;
    try {
      heard = await _dictation.listen();
    } on DictationUnavailableException catch (e) {
      if (mounted) _showMessage(e.message);
    }
    if (!mounted) return;

    setState(() => _listeningTo = null);
    await _dictation.cue(start: false);
    if (!mounted || heard == null) return;

    final text = VoiceDictation.normalize(heard, kind);
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Widget _micButton(TextEditingController controller, DictationKind kind) {
    final listening = _listeningTo == controller;
    return IconButton(
      tooltip: listening ? 'Dejar de escuchar' : 'Dictar con el micrófono',
      icon: Icon(listening ? Icons.mic : Icons.mic_none),
      color: listening ? Theme.of(context).colorScheme.error : null,
      onPressed: () => _dictateInto(controller, kind),
    );
  }

  // Doble toque en cualquier parte de la pantalla. Se detecta a mano, sin
  // GestureDetector, para no meterse en la competición de gestos: con un
  // detector de doble toque encima, cada botón del login tardaría en
  // responder a un toque normal mientras espera a ver si llega el segundo.
  //
  // Los plazos se miden con temporizadores y no con la hora de cada toque:
  // así se comportan igual en la app y en las pruebas.
  static const Duration _doubleTapWindow = Duration(milliseconds: 400);
  static const double _tapSlop = 24;
  Offset? _downAt;
  bool _pressIsShort = false;
  Timer? _pressTimer;
  Offset? _lastTapAt;
  Timer? _doubleTapTimer;

  /// En web, si ya se repitió el aviso tras el primer toque o tecla.
  bool _hintRepeated = false;

  @override
  void initState() {
    super.initState();
    // El aviso se dice en voz alta nada más abrir el login: quien no ve no
    // puede leer el texto, y sin oírlo no sabría que existe el atajo.
    WidgetsBinding.instance.addPostFrameCallback((_) => _speakHint());
    HardwareKeyboard.instance.addHandler(_onAnyKey);
  }

  void _speakHint() {
    if (!mounted || _brailleOpen) return;
    unawaited(accessibilityReadingState.read(LoginScreen.brailleHint, context));
  }

  /// Los navegadores no dejan hablar a una página hasta que la persona la
  /// toca o pulsa una tecla, así que en web el aviso de al abrir puede no
  /// sonar. Se repite con la primera interacción para que nadie se lo pierda.
  void _onFirstInteraction() {
    if (!kIsWeb || _hintRepeated) return;
    _hintRepeated = true;
    _speakHint();
  }

  bool _onAnyKey(KeyEvent event) {
    if (event is KeyDownEvent) _onFirstInteraction();
    return false;
  }

  void _onPointerDown(PointerDownEvent event) {
    _onFirstInteraction();
    _downAt = event.position;
    _pressIsShort = true;
    _pressTimer?.cancel();
    // Mantener el dedo apoyado no es un toque.
    _pressTimer = Timer(_doubleTapWindow, () => _pressIsShort = false);
  }

  void _onPointerUp(PointerUpEvent event) {
    final downAt = _downAt;
    _downAt = null;
    _pressTimer?.cancel();
    if (downAt == null) return;

    final isTap =
        _pressIsShort && (event.position - downAt).distance <= _tapSlop;
    if (!isTap) {
      _doubleTapTimer?.cancel();
      return;
    }

    final lastAt = _lastTapAt;
    if ((_doubleTapTimer?.isActive ?? false) &&
        lastAt != null &&
        (event.position - lastAt).distance <= kDoubleTapSlop) {
      _doubleTapTimer?.cancel();
      _openBrailleKeyboard();
      return;
    }

    _lastTapAt = event.position;
    _doubleTapTimer?.cancel();
    _doubleTapTimer = Timer(_doubleTapWindow, () {});
  }

  /// Abre el teclado Braille para escribir el correo y la contraseña.
  ///
  /// Al abrirse, el asistente de voz explica cómo se usa. Lo que se escribe
  /// va apareciendo en los dos campos y, al terminar la contraseña, se inicia
  /// sesión sin tener que encontrar el botón.
  Future<void> _openBrailleKeyboard() async {
    if (_brailleOpen || _isLoading) return;
    _brailleOpen = true;
    _voiceMode = true;

    final submit = await BrailleKeyboardScreen.fillFields(context, [
      BrailleField(
        label: 'Correo electrónico',
        controller: _emailController,
        email: true,
      ),
      BrailleField(
        label: 'Contraseña',
        controller: _passwordController,
        obscure: true,
      ),
    ]);

    _brailleOpen = false;
    if (submit && mounted) await _handleLogin();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Ingresa un correo electrónico válido');
      return;
    }

    if (password.length < 6) {
      _showMessage('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      await _authStorage.saveToken(response.accessToken);
      await _authStorage.saveRole(response.rol);
      await _authStorage.saveName(response.nombre);
      await _authStorage.saveEmail(response.email);
      await _authStorage.saveUserId(response.userId);
      final existingPhotoUrl = await _authStorage.getPhotoUrl();
      final nextPhotoUrl = (response.photoUrl?.trim().isNotEmpty ?? false)
          ? response.photoUrl!
          : (existingPhotoUrl ?? '');
      await _authStorage.savePhotoUrl(nextPhotoUrl);

      _showMessage(_buildWelcomeMessage(response));
      widget.onSuccess?.call(response.rol);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } catch (_) {
      if (!mounted) return;
      _showMessage('Ocurrió un error inesperado');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _buildWelcomeMessage(LoginResponse response) {
    final roleLabel = response.rol.toLowerCase();
    if (roleLabel == 'docente') {
      return 'Bienvenido ${response.nombre}. Tu rol es docente. Estamos construyendo las vistas necesarias próximamente.';
    }
    if (roleLabel == 'director') {
      return 'Bienvenido ${response.nombre}. Tu rol es director. Estamos construyendo las vistas necesarias próximamente.';
    }
    return 'Bienvenido ${response.nombre}. Tu rol es estudiante y puedes acceder a aprendizaje.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    if (_voiceMode) {
      unawaited(accessibilityReadingState.read(message, context));
    }
  }

  /// El inicio con Facebook todavía no existe: ni hay SDK, ni ruta en el
  /// servidor.
  ///
  /// El botón se queda a la vista, pero diciéndolo. Antes tenía el callback
  /// vacío: se pulsaba y no ocurría nada, sin explicación. Para quien usa
  /// lector de pantalla eso es peor todavía, porque no hay forma de saber si
  /// el toque se registró.
  void _handleFacebookSignIn() {
    _showMessage(
      'El inicio de sesión con Facebook todavía no está disponible. '
      'Entra con Google o con tu correo y contraseña.',
    );
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onAnyKey);
    if (_listeningTo != null) unawaited(_dictation.stop());
    _pressTimer?.cancel();
    _doubleTapTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWide = screenWidth >= 800;
    final logoSize = screenWidth < 360 ? 180.0 : (isWide ? 250.0 : 220.0);
    final horizontalPadding = screenWidth < 480 ? 20.0 : 32.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: GlobalAppBarWidget(
        title: 'CODE4ALL v0.1.',
        showUserIcon: false,
        userName: 'Usuario',
        onLogout: () => widget.onSuccess?.call('logout'),
      ),
      // El atajo al teclado Braille ocupa el sitio del botón de colores, abajo
      // a la izquierda, que en el login ya no se muestra.
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: Semantics(
        button: true,
        label: 'Teclado Braille',
        hint:
            'Escribe el correo y la contraseña en Braille con asistente '
            'de voz. También se abre tocando dos veces la pantalla.',
        excludeSemantics: true,
        // Pequeño y sólo con el icono, para no tapar «Registrarse». El área
        // que responde al toque sigue siendo de 48 px, la mínima accesible, y
        // quien no ve no depende de encontrarlo: le basta el doble toque.
        child: FloatingActionButton.small(
          heroTag: 'braille-shortcut',
          tooltip: 'Teclado Braille',
          backgroundColor: Colors.black,
          shape: const CircleBorder(
            side: BorderSide(color: Color(0xFFFFD600), width: 2),
          ),
          onPressed: _openBrailleKeyboard,
          child: const BrailleCellIcon(
            dots: {1, 2, 4},
            size: 20,
            color: Color(0xFFFFD600),
          ),
        ),
      ),
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        child: SafeArea(
          child: Column(
            children: [
              // Va arriba y fija. Es la primera pantalla de la aplicación: quien
              // necesita la letra más grande o que le lean los campos tiene que
              // encontrarlo antes de escribir nada, no después de desplazarse.
              const AccessibilityToolbar(),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: SingleChildScrollView(
                      // Abajo, sitio para el botón del teclado Braille: con la
                      // letra grande tapaba «Iniciar sesión».
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        24,
                        horizontalPadding,
                        96,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/logo-flutter.png',
                            height: logoSize,
                            width: logoSize,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            LoginScreen.brailleHint,
                            key: const ValueKey('braille-login-hint'),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Correo electrónico',
                              suffixIcon: _micButton(
                                _emailController,
                                DictationKind.email,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              suffixIcon: _micButton(
                                _passwordController,
                                DictationKind.password,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E88E5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('INICIAR SESIÓN'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SocialAuthBlock(
                            onGoogleTap: () {
                              _handleGoogleSignIn();
                            },
                            onFacebookTap: _handleFacebookSignIn,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1E88E5),
                                    Color(0xFF1565C0),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: ElevatedButton(
                                onPressed: widget.onRegister ?? () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'REGISTRARSE',
                                  style: TextStyle(
                                    color: Color(0xFFFFD600),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final response = await _googleAuthService.signIn(context: context);

      await _authStorage.saveToken(response.accessToken);
      await _authStorage.saveRole(response.rol);
      await _authStorage.saveName(response.nombre);
      await _authStorage.saveEmail(response.email);
      await _authStorage.saveUserId(response.userId);
      final existingPhotoUrl = await _authStorage.getPhotoUrl();
      final nextPhotoUrl = (response.photoUrl?.trim().isNotEmpty ?? false)
          ? response.photoUrl!
          : (existingPhotoUrl ?? '');
      await _authStorage.savePhotoUrl(nextPhotoUrl);

      _showMessage(_buildWelcomeMessage(response));
      widget.onSuccess?.call(response.rol);
    } on GoogleAuthCanceledException {
      if (!mounted) return;
      _showMessage('Inicio de sesión cancelado');
    } on GoogleAuthException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } on ApiException catch (e) {
      debugPrint('Google SignIn ApiException: ${e.toString()}');
      if (!mounted) return;
      _showMessage(e.message);
    } catch (e, st) {
      debugPrint('Google SignIn exception: $e');
      debugPrint(st.toString());
      if (!mounted) return;
      _showMessage('Error en autenticación con Google: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
