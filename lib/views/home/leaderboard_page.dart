import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:group_leaderboard/controllers/main_controller.dart';
import 'package:group_leaderboard/helpers/helper.dart';
import 'package:group_leaderboard/services/theme/theme.dart';
import 'package:group_leaderboard/views/home/components/build_leaderboard.dart';
import 'package:group_leaderboard/views/home/components/build_summary.dart';
import 'package:group_leaderboard/views/home/leaderboard_controller.dart';
import 'package:group_leaderboard/views/overview/overview_page.dart';
import 'package:group_leaderboard/views/widgets/main_layout.dart';

class LeaderboardPage extends StatelessWidget {
  static String routeName = '/leaderboard';
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, _) => GetBuilder<LeaderboardController>(
        builder: (controller) => GetBuilder<MainController>(
          builder: (mainController) {
            final groupId = Get.parameters['groupID'];
            if (groupId != null &&
                MainController.find.groups.any(
                  (element) => element == groupId.toUpperCase(),
                )) {
              WidgetsBinding.instance.addPostFrameCallback(
                (timeStamp) => controller.selectedGroup = groupId.toUpperCase(),
              );
            }
            return MainLayout(
              title: controller.selectedGroup == null
                  ? "🏆 Group Performance Overview"
                  : "Group Leaderboard",
              child: controller.selectedGroup == null
                  ? OverviewPage()
                  : buildLeaderboardWidget(),
            );
          },
        ),
      ),
    );
  }

  Widget buildLeaderboardWidget() => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 800),
      child: Column(
        children: [
          const SizedBox(height: 16),
          if (!Helper.isMobile) ...[
            Center(child: Text("Group Leaderboard", style: AppFonts.x18Bold)),
            const SizedBox(height: 16),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BuildSummary(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: BuildLeaderboard(),
            ),
          ),
        ],
      ),
    ),
  );
}
