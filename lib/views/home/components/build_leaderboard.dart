import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:group_leaderboard/constants/colors.dart';
import 'package:group_leaderboard/controllers/main_controller.dart';
import 'package:group_leaderboard/helpers/helper.dart';
import 'package:group_leaderboard/services/theme/theme.dart';
import 'package:group_leaderboard/views/home/leaderboard_controller.dart';

import 'build_grades_overlay.dart';

class BuildLeaderboard extends StatelessWidget {
  const BuildLeaderboard({super.key});

  void _showDetails(String studentName, Map<String, dynamic> grades) {
    if (Helper.isMobile) {
      Get.bottomSheet(
        BuildGradesOverlay(studentName: studentName, grades: grades),
        isScrollControlled: true,
      );
    } else {
      Get.dialog(BuildGradesOverlay(studentName: studentName, grades: grades));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaderboardController>(
      builder: (controller) => Obx(() {
        if (controller.isLoading.value) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 50),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (controller.docs.isEmpty) {
          return const Center(child: Text('No students found.'));
        }

        return ListView.separated(
          itemCount: controller.docs.length,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final doc = controller.docs[index];
            final data = doc.data();
            final name = data['studentName'] ?? 'Unknown';
            final total = data['totalScore'] ?? 0;
            final group = data['group'] ?? '';
            final isCurrentUser =
                MainController.find.currentUser?.linkedGradeId == doc.id;

            return ListTile(
              tileColor: isCurrentUser ? kPrimaryColor : null,
              leading: CircleAvatar(
                backgroundColor: isCurrentUser ? Colors.white : kPrimaryColor,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isCurrentUser ? kPrimaryColor : Colors.white,
                    fontSize: 16,
                    fontWeight: isCurrentUser ? FontWeight.bold : null,
                  ),
                ),
              ),
              title: Text(
                name,
                style: AppFonts.x16Bold.copyWith(
                  color: isCurrentUser ? Colors.white : null,
                ),
              ),
              subtitle: Text(
                'Group: $group',
                style: AppFonts.x14Regular.copyWith(
                  color: isCurrentUser
                      ? Colors.grey.shade200
                      : Colors.grey.shade700,
                ),
              ),
              trailing: SizedBox(
                width: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$total',
                      style: AppFonts.x24Bold.copyWith(
                        color: isCurrentUser ? Colors.white : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'XP',
                      style: AppFonts.x14Bold.copyWith(
                        color: isCurrentUser ? Colors.white : null,
                      ),
                    ),
                  ],
                ),
              ),
              onTap: isCurrentUser || MainController.find.currentUser!.isAdmin
                  ? () => _showDetails(data['studentName'], data)
                  : null,
            );
          },
        );
      }),
    );
  }
}
