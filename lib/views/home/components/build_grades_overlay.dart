import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:group_leaderboard/constants/colors.dart';
import 'package:group_leaderboard/helpers/helper.dart';

import '../../profile/components/build_grades_widget.dart';

class BuildGradesOverlay extends StatelessWidget {
  final String studentName;
  final Map<String, dynamic> grades;
  const BuildGradesOverlay({
    super.key,
    required this.studentName,
    required this.grades,
  });

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      width: Helper.isMobile
          ? Get.width
          : Get.width > 800
          ? 800
          : Get.width * 0.9,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Grades',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (grades.isEmpty)
            const Text('No grades linked yet.')
          else
            BuildGradesWidget(grades: grades),
        ],
      ),
    );
    return Helper.isMobile
        ? SizedBox(
            height: Get.height * 0.8,
            child: Material(
              color: kNeutralColor100,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Column(
                spacing: 10,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(width: 50),
                        Text(
                          studentName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: Get.back,
                          icon: Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: content,
                    ),
                  ),
                ],
              ),
            ),
          )
        : AlertDialog(
            backgroundColor: Colors.white,
            title: Center(child: Text(studentName)),
            content: content,
            actions: [TextButton(onPressed: Get.back, child: Text('OK'))],
          );
  }
}
