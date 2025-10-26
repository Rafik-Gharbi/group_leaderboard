import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:group_leaderboard/constants/colors.dart';
import 'package:group_leaderboard/helpers/helper.dart';
import 'package:group_leaderboard/services/theme/theme.dart';

import 'components/sync_button.dart';
import 'grades_matching_controller.dart';

class GradesMatchingPage extends StatelessWidget {
  static String routeName = '/grades-matching';
  const GradesMatchingPage({super.key});

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        color: kNeutralLightColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: AppFonts.x14Bold),
              const SizedBox(height: 6),
              Text(value, style: AppFonts.x18Bold.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<GradesMatchingController>(
      builder: (controller) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: Scaffold(
            appBar: AppBar(
              title: const Text("Grades Matching"),
              actions: const [
                Padding(padding: EdgeInsets.all(8), child: SyncButton()),
              ],
            ),
            body: Obx(() {
              final totalStudents = controller.students.length;
              final totalLinked = controller.students
                  .where(
                    (s) =>
                        s['linkedGradesId'] != null &&
                        s['linkedGradesId'].toString().isNotEmpty,
                  )
                  .length;
              final totalUnlinked = totalStudents - totalLinked;

              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatCard(
                            'Total Students',
                            totalStudents.toString(),
                            Colors.blue,
                          ),
                          _buildStatCard(
                            'Linked',
                            totalLinked.toString(),
                            Colors.green,
                          ),
                          _buildStatCard(
                            'Unlinked',
                            totalUnlinked.toString(),
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: controller.students.isEmpty
                          ? Center(child: Text('No signed up students yet!'))
                          : ListView.builder(
                              itemCount: controller.students.length,
                              itemBuilder: (context, index) {
                                final student = controller.students[index];
                                final match = controller.matches
                                    .cast()
                                    .singleWhere(
                                      (element) =>
                                          element['student']['name'] ==
                                          student['name'],
                                      orElse: () => null,
                                    );
                                final suggested = match?['suggestions'];
                                String rating(String target) =>
                                    ((suggested?.cast().singleWhere(
                                                  (element) =>
                                                      element['target'] ==
                                                      target,
                                                  orElse: () => null,
                                                )?['rating'] ??
                                                0) *
                                            100)
                                        .toStringAsFixed(1);

                                return ListTile(
                                  onTap: () => controller.openProfile(student),
                                  leading: CircleAvatar(
                                    child: Text(
                                      (student['name'] ?? 'U')[0].toUpperCase(),
                                    ),
                                  ),
                                  title: Text(
                                    student['name'],
                                    style: AppFonts.x16Bold,
                                  ),
                                  subtitle:
                                      Helper.isNullOrEmpty(
                                        student['linkedGradesId'],
                                      )
                                      ? suggested == null
                                            ? Text('No sugestions found')
                                            : Text(
                                                "Suggested: ${suggested.map((e) => '${e['target']} (${rating(e['target'])}%)').join(' - ')}",
                                              )
                                      : Text(
                                          'Linked to: ${student['linkedGradesId']}',
                                        ),
                                  trailing: PopupMenuButton<String>(
                                    color: Colors.grey.shade200,
                                    constraints: BoxConstraints(maxHeight: 400),
                                    borderRadius: BorderRadius.circular(6),
                                    iconSize: 32,
                                    onSelected: (selectedGrade) {
                                      controller.linkStudentToGrade(
                                        student,
                                        selectedGrade,
                                      );
                                    },
                                    itemBuilder: (_) => controller.grades.map((
                                      g,
                                    ) {
                                      final isSuggested =
                                          Helper.isNullOrEmpty(
                                            student['linkedGradesId'],
                                          )
                                          ? suggested.any(
                                              (e) =>
                                                  e['target'] ==
                                                  g['studentName'],
                                            )
                                          : g['id'] ==
                                                student['linkedGradesId'];
                                      return PopupMenuItem(
                                        value: g['id'].toString(),
                                        padding: EdgeInsets.zero,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: isSuggested
                                                ? kPrimaryColor
                                                : null,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(
                                                '${g['group']} - ${g['studentName']}',
                                                style: AppFonts.x14Regular
                                                    .copyWith(
                                                      color: isSuggested
                                                          ? Colors.white
                                                          : null,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    child: const Icon(Icons.link),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
