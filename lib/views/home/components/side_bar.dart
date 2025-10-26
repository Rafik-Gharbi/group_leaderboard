import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:group_leaderboard/constants/colors.dart';
import 'package:group_leaderboard/controllers/main_controller.dart';
import 'package:group_leaderboard/helpers/helper.dart';
import 'package:group_leaderboard/services/theme/theme.dart';
import 'package:group_leaderboard/views/grades_matching/grades_matching_page.dart';
import 'package:group_leaderboard/views/home/leaderboard_controller.dart';
import 'package:group_leaderboard/views/profile/profile_page.dart';

class SidebarController extends GetxController {
  RxBool isExpanded = false.obs;

  SidebarController() {
    isExpanded.value = Helper.isMobile;
  }

  void toggle() => isExpanded.value = !isExpanded.value;
}

class SideBar extends StatelessWidget {
  const SideBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaderboardController>(
      builder: (leaderboardController) => GetBuilder<SidebarController>(
        init: SidebarController(),
        builder: (controller) => Obx(
          () => AnimatedContainer(
            padding: EdgeInsets.symmetric(horizontal: 5),
            duration: const Duration(milliseconds: 200),
            width: controller.isExpanded.value ? 165 : 60,
            decoration: BoxDecoration(
              color: kPrimaryColor,
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Header / Expand button
                Align(
                  alignment: controller.isExpanded.value
                      ? Alignment.centerRight
                      : Alignment.center,
                  child: IconButton(
                    icon: Icon(
                      controller.isExpanded.value
                          ? Icons.chevron_left_outlined
                          : Icons.chevron_right_outlined,
                      color: Colors.white,
                    ),
                    onPressed: controller.toggle,
                  ),
                ),
                const SizedBox(height: 10),

                // Profile
                _DrawerItem(
                  icon: Icons.person,
                  label: 'Profile',
                  expanded: controller.isExpanded.value,
                  onTap: () => Get.toNamed(ProfilePage.routeName),
                ),

                // Grades Matching (Admin)
                if (MainController.find.isAdmin)
                  _DrawerItem(
                    icon: Icons.score_outlined,
                    label: 'Grades Matching',
                    expanded: controller.isExpanded.value,
                    onTap: () => Get.toNamed(GradesMatchingPage.routeName),
                  ),

                // All groups overview
                _DrawerItem(
                  icon: Icons.leaderboard,
                  label: 'All Groups',
                  expanded: controller.isExpanded.value,
                  onTap: () => leaderboardController.selectedGroup = null,
                ),

                // Groups Leaderboard
                ...List.generate(MainController.find.groups.skip(1).length, (
                  index,
                ) {
                  final group = MainController.find.groups
                      .skip(1)
                      .toList()[index];
                  return _DrawerItem(
                    label: '$group Leaderboard',
                    expanded: controller.isExpanded.value,
                    onTap: () => leaderboardController.selectedGroup = group,
                  );
                }),

                // Logout
                const Spacer(),
                _DrawerItem(
                  icon: Icons.logout,
                  label: 'Logout',
                  expanded: controller.isExpanded.value,
                  onTap: MainController.find.logout,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool expanded;
  final VoidCallback onTap;

  const _DrawerItem({
    this.icon,
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          mainAxisAlignment: expanded
              ? MainAxisAlignment.start
              : MainAxisAlignment.center,
          children: [
            if (icon == null)
              Text(
                label.substring(0, 2),
                style: AppFonts.x16Bold.copyWith(color: Colors.white),
              )
            else
              Icon(icon, color: Colors.white),
            if (expanded) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
