import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:group_leaderboard/views/home/leaderboard_controller.dart';

class BuildSummary extends StatelessWidget {
  const BuildSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LeaderboardController>(
      builder: (controller) => Obx(() {
        controller.isLoading.value;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Showing group: ${controller.selectedGroup ?? 'All'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (controller.groupSum != null)
                    Text(
                      'Group average: ${(controller.groupSum! / controller.totalStudents).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),

              ElevatedButton.icon(
                onPressed: controller.getFirestoreQuery,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Refresh',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
