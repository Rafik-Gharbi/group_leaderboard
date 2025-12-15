import 'package:flutter/material.dart';
import 'package:group_leaderboard/helpers/helper.dart';

import '../../../constants/colors.dart';
import '../../../services/theme/theme.dart';

class BuildGradesWidget extends StatelessWidget {
  final Map<String, dynamic> grades;
  const BuildGradesWidget({super.key, required this.grades});

  @override
  Widget build(BuildContext context) {
    final assignments = (grades['assignments'] as List?) ?? [];
    final totalScore = grades['totalScore'] ?? 0;
    final practiceXP = grades['practiceXP'] ?? 0;
    final extraXP = grades['extraXP'] ?? 0;

    final assignmentsScrollController = ScrollController();
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎯 Total Score Summary
          Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: kPrimaryColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Score",
                    style: AppFonts.x18Regular.copyWith(color: Colors.white),
                  ),
                  Text(
                    "$totalScore",
                    style: AppFonts.x24Bold.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 🧾 Assignments Table
          Text("Assignments History", style: AppFonts.x16Bold),
          const SizedBox(height: 8),

          Card(
            elevation: Helper.isMobile ? 0 : 2,
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: assignments.isEmpty
                ? const Center(child: Text("No assignments available"))
                : Helper.isMobile
                ? buildGradeList(assignments)
                : buildGradeTable(assignmentsScrollController, assignments),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: kNeutralColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Practice XP",
                          style: AppFonts.x16Regular.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "$practiceXP",
                          style: AppFonts.x18Bold.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: kNeutralColor,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Extra XP",
                          style: AppFonts.x16Regular.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "$extraXP",
                          style: AppFonts.x18Bold.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildGradeTable(
    ScrollController assignmentsScrollController,
    List<dynamic> assignments,
  ) => PrimaryScrollController(
    controller: assignmentsScrollController,
    child: Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: assignmentsScrollController,
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.only(bottom: 12),
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) {
              assignmentsScrollController.jumpTo(
                assignmentsScrollController.offset - details.delta.dx,
              );
            },
            child: Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              defaultColumnWidth: const IntrinsicColumnWidth(),
              children: [
                // 🧩 Header Row (Assignments)
                TableRow(
                  decoration: BoxDecoration(color: Colors.grey.shade200),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 24,
                      ),
                      child: Text(
                        "Assignments",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    for (var assignmentName in assignments.map(
                      (e) => e['name'],
                    ))
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 24,
                        ),
                        child: Text(
                          assignmentName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                  ],
                ),
                // 🧮 Grades Row
                TableRow(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 24,
                      ),
                      child: Text(
                        "Grades",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    for (var assignmentGrade in assignments.map(
                      (e) => e['grade'],
                    ))
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16.0,
                          horizontal: 24,
                        ),
                        child: Text(
                          (assignmentGrade ?? '-').toString(),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget buildGradeList(List assignments) => ListView.builder(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    itemCount: assignments.length,
    itemBuilder: (context, index) => ListTile(
      shape: UnderlineInputBorder(
        borderSide: BorderSide(color: kNeutralLightColor),
      ),
      title: Text(assignments[index]['name']),
      trailing: Text(
        (assignments[index]['grade'] ?? '-').toString(),
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
