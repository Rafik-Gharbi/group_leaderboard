import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:group_leaderboard/constants/colors.dart';
import 'package:group_leaderboard/controllers/main_controller.dart';
import 'package:group_leaderboard/services/theme/theme.dart';
import 'package:group_leaderboard/views/home/leaderboard_controller.dart';

class BuildLeaderboard extends StatelessWidget {
  const BuildLeaderboard({super.key});

  // void _showDetails(
  //   BuildContext context,
  //   String name,
  //   Map<String, dynamic> assignments,
  //   int total,
  // ) {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       final assignmentRows = assignments.entries
  //           .map((e) => '${e.key}: ${e.value}')
  //           .join('\n');
  //       return AlertDialog(
  //         title: Text(name),
  //         content: SingleChildScrollView(
  //           child: Text('Total: $total\n\nAssignments:\n$assignmentRows'),
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: const Text('Close'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

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
            // final assignments = Map<String, dynamic>.from(
            //   data['assignments'] ?? {},
            // );

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
              // onTap: () => _showDetails(context, name, assignments, total),
            );
          },
        );
      }),
    );
  }
}
