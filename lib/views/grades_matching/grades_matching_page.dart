import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:group_leaderboard/constants/colors.dart';
import 'package:group_leaderboard/controllers/main_controller.dart';
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(title, style: AppFonts.x14Bold),
              ),
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
              actions: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: IconButton(
                    onPressed: controller.toggleFilter,
                    icon: Icon(Icons.filter_alt_outlined),
                  ),
                ),
                Padding(padding: EdgeInsets.all(8), child: SyncButton()),
              ],
            ),
            body: Obx(() {
              final totalStudents = controller.filteredStudents.length;
              final totalLinked = controller.filteredStudents
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
                    AnimatedContainer(
                      duration: Durations.medium1,
                      height: controller.openFilter.value ? 82 : 0,
                      child: Opacity(
                        opacity: controller.openFilter.value ? 1 : 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller:
                                      controller.searchStudentController,
                                  decoration: InputDecoration(
                                    label: Text("Search Student"),
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) => Helper.onSearchDebounce(
                                    controller.filterStudents,
                                  ),
                                ),
                              ),
                              SizedBox(width: 20),
                              SizedBox(
                                width: 120,
                                child: DropdownButtonFormField(
                                  initialValue:
                                      controller.selectedGroup ?? 'All',
                                  items: MainController.find.groups
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) =>
                                      controller.selectedGroup = value!,
                                  dropdownColor: Colors.white,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: "Group",
                                  ),
                                ),
                              ),
                              SizedBox(width: 20),
                              IconButton(
                                onPressed: controller.clearFilter,
                                icon: Icon(Icons.clear_all_outlined),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
                      child: controller.filteredStudents.isEmpty
                          ? Center(child: Text('No signed up students yet!'))
                          : ListView.builder(
                              itemCount: controller.filteredStudents.length,
                              itemBuilder: (context, index) {
                                final student =
                                    controller.filteredStudents[index];
                                final match = controller.matches
                                    .cast()
                                    .firstWhere(
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
                                      Helper.getInitials(
                                        student['name'] ?? 'U',
                                      ),
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
                                    constraints: BoxConstraints(maxHeight: 400),
                                    borderRadius: BorderRadius.circular(6),
                                    iconSize: 32,
                                    onSelected: (selectedGrade) {
                                      controller.linkStudentToGrade(
                                        student,
                                        selectedGrade,
                                      );
                                    },
                                    itemBuilder: (_) => controller.grades
                                        .where(
                                          (g) =>
                                              !Helper.isNullOrEmpty(
                                                student['group'],
                                              ) &&
                                              student['group'] == g['group'],
                                        )
                                        .map((g) {
                                          final isSuggested =
                                              Helper.isNullOrEmpty(
                                                student['linkedGradesId'],
                                              )
                                              ? (suggested?.any(
                                                      (e) =>
                                                          e['target'] ==
                                                          g['studentName'],
                                                    ) ??
                                                    false)
                                              : g['id'] ==
                                                    student['linkedGradesId'];
                                          final rating =
                                              Helper.isNullOrEmpty(
                                                student['linkedGradesId'],
                                              )
                                              ? (suggested?.any(
                                                          (e) =>
                                                              e['target'] ==
                                                              g['studentName'],
                                                        ) ??
                                                        false)
                                                    ? suggested.singleWhere(
                                                        (e) =>
                                                            e['target'] ==
                                                            g['studentName'],
                                                      )['rating']
                                                    : null
                                              : null;
                                          return PopupMenuItem(
                                            value: g['id'].toString(),
                                            padding: EdgeInsets.zero,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: isSuggested
                                                    ? kPrimaryColor.withAlpha(
                                                        rating != null
                                                            ? (rating * 255)
                                                                  .toInt()
                                                            : 255,
                                                      )
                                                    : null,
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerLeft,
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
                                        })
                                        .toList(),
                                    child: Icon(
                                      Icons.link,
                                      color:
                                          Helper.isNullOrEmpty(
                                            student['linkedGradesId'],
                                          )
                                          ? Colors.black
                                          : Colors.grey,
                                    ),
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
