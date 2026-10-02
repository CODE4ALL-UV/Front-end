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
import 'package:flutter_code4all/ui/core/ui/user_manual.dart';
import 'package:flutter_code4all/data/services/facebook_auth_service.dart';
import 'package:flutter_code4all/data/services/google_auth_service.dart';
import 'package:flutter_code4all/data/services/launch_link.dart';
import 'package:flutter_code4all/data/services/voice_dictation_service.dart';
import 'package:flutter_code4all/ui/users_management/widgets/forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onRegister;
  final void Function(String role)? onSuccess;

  const LoginScreen({
    super.key,
    this.onRegister,
    this.onSuccess,
    this.dictation,
    this.facebookAuth,
  });

  /// Para las pruebas.
  final FacebookAuthService? facebookAuth;

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
  late final FacebookAuthService _facebookAuth =
      widget.facebookAuth ?? FacebookAuthService();
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

    // Volviendo de Facebook: mientras el servidor confirma, el login se
    // muestra ocupado en vez de pedir otra vez los datos.
    if (LaunchLink.hasFacebookReturn) {
      _isLoading = true;
      unawaited(_finishFacebookReturn());
    }
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

  /// Va a Facebook. La página vuelve a abrirse a la vuelta y entonces sigue
  /// [_finishFacebookReturn].
  ///
  /// Si la app se compiló sin FACEBOOK_APP_ID, el botón se queda a la vista
  /// pero lo dice. Antes tenía el callback vacío: se pulsaba y no ocurría
  /// nada, y quien usa lector de pantalla no tenía forma de saber si el toque
  /// se registró.
  void _handleFacebookSignIn() {
    if (!_facebookAuth.isAvailable) {
      _showMessage(
        'El inicio de sesión con Facebook todavía no está disponible. '
        'Entra con Google o con tu correo y contraseña.',
      );
      return;
    }
    setState(() => _isLoading = true);
    _showMessage('Abriendo Facebook…');
    _facebookAuth.start();
  }

  /// Se vuelve de Facebook: termina de entrar.
  Future<void> _finishFacebookReturn() async {
    try {
      final response = await _facebookAuth.finishIfReturning();
      if (response != null) await _completeSignIn(response);
    } on FacebookAuthCanceledException {
      if (!mounted) return;
      _showMessage('Inicio de sesión con Facebook cancelado');
    } on FacebookAuthException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } on ApiException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ForgotPasswordScreen(initialEmail: _emailController.text.trim()),
      ),
    );
  }

  /// Abre el manual en las guías de primeros pasos. Va directo desde el
  /// toque: el navegador solo deja abrir pestañas en respuesta a un gesto.
  Future<void> _openManual() async {
    final opened = await openUserManual();
    if (!opened && mounted) {
      _showMessage(
        'No se pudo abrir el manual. Está en '
        'code4all-web.onrender.com/manual.html',
      );
    }
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
                child: LayoutBuilder(
                  builder: (context, constraints) => constraints.maxWidth >= 900
                      ? _twoColumns(context, constraints)
                      : _oneColumn(context, constraints),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// El logo. Su alto lo decide quien lo coloca, según el sitio que haya.
  Widget _logo(double height) => Image.asset(
    'assets/images/logo-flutter.png',
    height: height,
    fit: BoxFit.contain,
  );

  Widget _brailleHint(BuildContext context) => Text(
    LoginScreen.brailleHint,
    key: const ValueKey('braille-login-hint'),
    textAlign: TextAlign.center,
    style: Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
  );

  /// Correo, contraseña y todas las formas de entrar o registrarse.
  Widget _form() => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: 'Correo electrónico',
          suffixIcon: _micButton(_emailController, DictationKind.email),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _passwordController,
        obscureText: true,
        decoration: InputDecoration(
          labelText: 'Contraseña',
          suffixIcon: _micButton(_passwordController, DictationKind.password),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: TextButton(
          key: const ValueKey('forgot-password'),
          onPressed: _openForgotPassword,
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          child: const Text('¿Olvidaste tu contraseña?'),
        ),
      ),
      const SizedBox(height: 4),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            // 1E88E5 con letra blanca: 3,7:1. Este, 5,8:1.
            backgroundColor: const Color(0xFF1565C0),
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
                // El amarillo sobre 1E88E5 se quedaba en
                // 2,6:1. Sobre estos azules pasa de 5,3.
                Color(0xFF1152A8),
                Color(0xFF0D47A1),
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
      const SizedBox(height: 8),
      // Antes de tener cuenta: abre las guías para entrar y registrarse. Ya
      // dentro, el manual está en el menú de perfil, en la parte de cada rol.
      TextButton.icon(
        key: const ValueKey('user-manual'),
        onPressed: _openManual,
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
        icon: const Icon(Icons.menu_book_outlined),
        label: const Text('¿Cómo se usa Code4All? Ver el manual'),
      ),
    ],
  );

  /// Celular y tablet en vertical: todo en una columna.
  ///
  /// El logo se ajusta al alto que haya. Fijo en 220 px, en un celular bajo
  /// empujaba «Iniciar sesión» fuera de la vista nada más abrir la app.
  Widget _oneColumn(BuildContext context, BoxConstraints constraints) {
    final padding = constraints.maxWidth < 480 ? 20.0 : 32.0;
    final logoHeight = (constraints.maxHeight * 0.2).clamp(80.0, 160.0);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          // Abajo, sitio para el botón del teclado Braille: con la letra
          // grande tapaba «Iniciar sesión».
          padding: EdgeInsets.fromLTRB(padding, 16, padding, 96),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _logo(logoHeight),
              const SizedBox(height: 8),
              _brailleHint(context),
              const SizedBox(height: 12),
              _form(),
            ],
          ),
        ),
      ),
    );
  }

  /// Portátil y tablet en horizontal: el logo y el aviso a la izquierda, el
  /// formulario a la derecha.
  ///
  /// En una sola columna, con el logo de 250 px, el login medía unos 800 px de
  /// alto. En un portátil quedan unos 600 bajo la barra del navegador:
  /// «Registrarse» salía cortado y había que desplazarse para encontrarlo.
  Widget _twoColumns(BuildContext context, BoxConstraints constraints) {
    final logoHeight = (constraints.maxHeight * 0.3).clamp(100.0, 200.0);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _logo(logoHeight),
                    const SizedBox(height: 16),
                    _brailleHint(context),
                  ],
                ),
              ),
              const SizedBox(width: 56),
              Expanded(child: _form()),
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
      await _completeSignIn(response);
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

  /// Guarda la sesión que abrió Google o Facebook y entra.
  Future<void> _completeSignIn(LoginResponse response) async {
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

    if (!mounted) return;
    _showMessage(_buildWelcomeMessage(response));
    widget.onSuccess?.call(response.rol);
  }
}
