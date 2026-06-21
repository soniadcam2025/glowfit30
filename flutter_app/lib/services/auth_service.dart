import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/storage/preferences.dart';
import 'api_service.dart';
import 'notification_service.dart';

const _webClientId =
    '479431264975-nrhnp9h40qek38hbfko9kcbu4q804oo3.apps.googleusercontent.com';

class AuthService extends GetxService {
  final _auth = FirebaseAuth.instance;
  final _preferences = Get.find<Preferences>();

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  @override
  void onInit() {
    super.onInit();
    GoogleSignIn.instance.initialize(serverClientId: _webClientId);
  }

  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Exchange Firebase ID token for our own JWT
        final firebaseIdToken = await firebaseUser.getIdToken();
        final api = Get.find<ApiService>();
        final result = await api.firebaseAuth(firebaseIdToken!);

        if (result != null && result['token'] != null) {
          await _preferences.setAccessToken(result['token'] as String);
          Get.find<NotificationService>().registerToken();
        } else {
          // Backend auth failed — sign out Firebase to prevent splash redirect loop
          await _auth.signOut();
          await GoogleSignIn.instance.signOut();
          Get.snackbar(
            'Sign-in Failed',
            'Could not authenticate with server. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
          );
          return null;
        }
      }

      return firebaseUser;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      Get.snackbar('Sign-in Failed', 'Could not sign in with Google.',
          snackPosition: SnackPosition.BOTTOM);
      return null;
    } catch (_) {
      Get.snackbar('Sign-in Failed', 'Something went wrong.',
          snackPosition: SnackPosition.BOTTOM);
      return null;
    }
  }

  Future<void> signOut() async {
    await _preferences.clearAuthTokens();
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}
