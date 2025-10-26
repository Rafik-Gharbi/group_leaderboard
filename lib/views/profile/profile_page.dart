import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:group_leaderboard/helpers/helper.dart';
import 'components/build_grades_widget.dart';
import 'profile_controller.dart';

class ProfilePage extends StatelessWidget {
  static String routeName = '/profile';
  final String? studentUID;

  const ProfilePage({super.key, this.studentUID});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      init: ProfileController(),
      tag: studentUID,
      initState: (state) => Helper.waitAndExecute(
        () => state.controller != null,
        () => state.controller!.loadUserData(uid: studentUID),
      ),
      builder: (controller) => studentUID == null
          ? Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 800),
                child: Scaffold(
                  appBar: AppBar(title: const Text('My Profile')),
                  body: buildProfileContent(controller),
                ),
              ),
            )
          : buildProfileContent(controller),
    );
  }

  Widget buildProfileContent(ProfileController controller) => Obx(() {
    if (controller.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile picture
          CircleAvatar(
            radius: 60,
            backgroundImage: controller.pictureUrl.isNotEmpty
                ? NetworkImage(controller.pictureUrl.value)
                : null,
            child: controller.pictureUrl.isEmpty
                ? const Icon(Icons.person, size: 60)
                : null,
          ),
          const SizedBox(height: 16),

          // Basic info
          Text(
            controller.fullName.value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(controller.email.value),
          const SizedBox(height: 8),
          Text('Group: ${controller.group.value}'),

          const Divider(height: 32),

          // Grades / Leaderboard section
          Text(
            'Grades',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (controller.grades.isEmpty)
            const Text('No grades linked yet.')
          else
            BuildGradesWidget(grades: controller.grades),
        ],
      ),
    );
  });
}
