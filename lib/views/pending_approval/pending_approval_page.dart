import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:group_leaderboard/controllers/main_controller.dart';
import 'package:group_leaderboard/services/theme/theme.dart';

class PendingApprovalPage extends StatelessWidget {
  static String routeName = '/pending-approbal';
  const PendingApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MainController>(
      builder: (controller) => Scaffold(
        body: Center(
          child: Obx(() {
            if (controller.isApproved) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => controller.navigateToLeaderboard(),
              );
            }
            return controller.isLoading.value
                ? CircularProgressIndicator()
                : Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.lock_clock,
                            size: 80,
                            color: Colors.orangeAccent,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Awaiting Approval",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Hello ${controller.currentUser?.name ?? ''}, your account is pending approval.\n"
                            "You'll be able to access your grades once your teacher links your account.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),
                            label: Text(
                              "Check Again",
                              style: AppFonts.x14Regular.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () async =>
                                await controller.checkUserApproval(),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "This process may take some time. Please check again later.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
          }),
        ),
      ),
    );
  }
}
