import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // LOGIN USER (EMAIL & PASSWORD)
  // ============================================================
  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "success";
    } on FirebaseAuthException catch (e) {
      return _handleLoginError(e);
    } catch (e) {
      return "Terjadi kesalahan: $e";
    }
  }

  // ============================================================
  // LOGIN WITH GOOGLE (Return email)
  // ============================================================
  Future<String?> continueWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      // Pilih akun
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return null; // user cancel
      }
      // Ambil token auth
      final GoogleSignInAuthentication gAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      // Login ke Firebase
      await _auth.signInWithCredential(credential);
      // Return email
      return googleUser.email;
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // REGISTER USER
  // ============================================================
  Future<String> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await userCred.user!.updateDisplayName(username);

      return "success";
    } on FirebaseAuthException catch (e) {
      return _handleRegisterError(e);
    } catch (e) {
      return "Terjadi kesalahan: $e";
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> logout() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Jika login lewat Google → logout Google juga
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }

      // Logout Firebase
      await _auth.signOut();
    } catch (e) {
      print("Error logout: $e");
    }
  }

  // ============================================================
  // ERROR HANDLER LOGIN
  // ============================================================
  String _handleLoginError(FirebaseAuthException e) {
    switch (e.code) {
      case "invalid-email":
      case "wrong-password":
      case "user-not-found":
      case "invalid-credential":
        return "Email atau password salah";

      case "user-disabled":
        return "Akun ini telah dinonaktifkan";

      case "too-many-requests":
        return "Terlalu banyak percobaan login, coba lagi nanti";

      case "network-request-failed":
        return "Periksa koneksi internet Anda";

      default:
        return e.message ?? "Terjadi kesalahan saat login";
    }
  }

  // ============================================================
  // ERROR HANDLER REGISTER
  // ============================================================
  String _handleRegisterError(FirebaseAuthException e) {
    switch (e.code) {
      case "email-already-in-use":
        return "Email sudah digunakan";

      case "invalid-email":
        return "Format email tidak valid";

      case "weak-password":
        return "Password terlalu lemah (minimal 6 karakter)";

      case "operation-not-allowed":
        return "Pendaftaran tidak diizinkan";

      case "network-request-failed":
        return "Periksa koneksi internet Anda";

      default:
        return e.message ?? "Terjadi kesalahan saat membuat akun";
    }
  }
}
