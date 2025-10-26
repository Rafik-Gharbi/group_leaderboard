import 'package:get/get.dart';
import 'package:group_leaderboard/controllers/main_controller.dart';
import 'package:group_leaderboard/views/login/login_page.dart';

import '../../models/user.dart';

class ProfileController extends GetxController {
  final fullName = ''.obs;
  final email = ''.obs;
  final group = ''.obs;
  final pictureUrl = ''.obs;
  final grades = <String, dynamic>{}.obs;
  final isLoading = true.obs;

  Future<void> loadUserData({String? uid}) async {
    isLoading.value = true;
    final mainController = MainController.find;
    User? fetchedUser;
    if (uid != null) {
      fetchedUser = await mainController.fetchProfile(studentUID: uid);
    } else if (mainController.currentUser != null) {
      fetchedUser = mainController.currentUser;
    }
    if (fetchedUser == null && uid == null) {
      Get.offAllNamed(LoginPage.routeName);
    }
    fullName.value = fetchedUser!.name ?? '';
    email.value = fetchedUser.email ?? '';
    group.value = fetchedUser.group ?? '';
    pictureUrl.value = fetchedUser.photo ?? '';
    grades.value = fetchedUser.grades ?? {};
    isLoading.value = false;
  }

  void clearScreenData() {
    fullName.value = '';
    email.value = '';
    group.value = '';
    pictureUrl.value = '';
    grades.value = {};
    isLoading.value = true;
  }
}
