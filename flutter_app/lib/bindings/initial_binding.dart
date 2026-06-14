import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';
import '../core/network/api_client.dart';
import '../core/storage/preferences.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Order matters: Preferences → ApiClient → ApiService → AuthService
    Get.put(Preferences(), permanent: true);
    Get.put(ApiClient(), permanent: true);
    Get.put(ApiService(), permanent: true);
    Get.put(AuthService(), permanent: true);
    Get.lazyPut(() => OnboardingController(), fenix: true);
  }
}
