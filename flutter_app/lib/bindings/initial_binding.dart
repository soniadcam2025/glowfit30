import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';
import '../services/auth_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthService(), permanent: true);
    Get.lazyPut(() => OnboardingController(), fenix: true);
  }
}
