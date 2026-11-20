
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Iniciar sesión con correo y contraseña
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception(
        'Ocurrió un error inesperado al iniciar sesión. Inténtalo nuevamente.',
      );
    }
  }

  // Registrar un nuevo usuario
  Future<UserCredential> register({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception(
        'Ocurrió un error inesperado al registrar el usuario.',
      );
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception(
        'No fue posible cerrar la sesión. Inténtalo nuevamente.',
      );
    }
  }

  // Obtener el usuario autenticado
  User? get currentUser => _firebaseAuth.currentUser;

  // Escuchar cambios en el estado de autenticación
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges();
  }

  // Traducir errores de Firebase a mensajes comprensibles
  String _getAuthErrorMessage(String code) {
    switch (code) {
      // Inicio de sesión
      case 'invalid-email':
        return 'El formato del correo electrónico no es válido.';

      case 'user-not-found':
        return 'No existe una cuenta registrada con este correo.';

      case 'wrong-password':
        return 'La contraseña ingresada es incorrecta.';

      case 'invalid-credential':
        return 'El correo electrónico o la contraseña son incorrectos.';

      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';

      case 'too-many-requests':
        return 'Has realizado demasiados intentos. Espera un momento e inténtalo nuevamente.';

      case 'network-request-failed':
        return 'No hay conexión a Internet. Verifica tu conexión e inténtalo nuevamente.';

      case 'operation-not-allowed':
        return 'Este método de autenticación no está habilitado.';

      // Registro
      case 'weak-password':
        return 'La contraseña es demasiado débil. Utiliza una contraseña más segura.';

      case 'email-already-in-use':
        return 'Este correo electrónico ya está registrado.';

      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con este correo utilizando otro método de acceso.';

      // Otros errores
      case 'requires-recent-login':
        return 'Por seguridad, debes volver a iniciar sesión para realizar esta acción.';

      case 'session-cookie-expired':
        return 'Tu sesión ha expirado. Inicia sesión nuevamente.';

      default:
        return 'No fue posible completar la operación. Inténtalo nuevamente.';
    }
  }
}
