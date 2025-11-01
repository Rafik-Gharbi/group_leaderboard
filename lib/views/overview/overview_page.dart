import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:group_leaderboard/constants/colors.dart';
import 'package:group_leaderboard/helpers/helper.dart';
import 'package:group_leaderboard/services/theme/theme.dart';
import 'overview_controller.dart';

class OverviewPage extends StatelessWidget {
  static String routeName = '/overview';
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OverviewController>(
      init: OverviewController(),
      builder: (controller) => Obx(() {
        if (controller.groupAvgScore.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final sortedGroups = controller.groupAvgScore.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  "🏆 Group Performance Overview",
                  style: AppFonts.x24Bold,
                ),
              ),
              const SizedBox(height: 50),

              // Bar Chart
              SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    maxY: controller.roundUpToHundred(sortedGroups.first.value),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                            BarTooltipItem(
                              '${rod.toY.toStringAsFixed(0)} AVG',
                              AppFonts.x14Regular.copyWith(color: Colors.white),
                            ),
                      ),
                    ),
                    barGroups: sortedGroups
                        .map(
                          (e) => BarChartGroupData(
                            x: sortedGroups.indexOf(e),
                            barRods: [
                              BarChartRodData(
                                color: kPrimaryColor,
                                toY: e.value,
                                width: 20,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) =>
                              Text(sortedGroups[val.toInt()].key),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Top 3 Students
              const Text(
                "👑 Top 3 Students",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Row(
                children: controller.allStudents.take(3).map((student) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Card(
                        color: kNeutralLightColor,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.blueGrey,
                                backgroundImage:
                                    Helper.isNullOrEmpty(student['pictureUrl'])
                                    ? null
                                    : NetworkImage(student['pictureUrl']),
                                child:
                                    Helper.isNullOrEmpty(student['pictureUrl'])
                                    ? Text(
                                        Helper.getInitials(
                                          student['studentName'],
                                        ),
                                        style: AppFonts.x18Regular.copyWith(
                                          color: Colors.white,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                student['studentName'],
                                textAlign: TextAlign.center,
                                style: AppFonts.x16Bold,
                              ),
                              Text(
                                "Group ${student['group']}",
                                style: AppFonts.x14Regular.copyWith(
                                  color: Colors.blueGrey.shade700,
                                ),
                              ),
                              Text(
                                "${student['totalScore']} XP",
                                style: AppFonts.x16Regular.copyWith(
                                  color: kAccentColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 30),

              // Stats summary
              Row(
                children: [
                  Spacer(),
                  _StatCard(
                    "💪 Total XP",
                    controller.totalXp.value.toStringAsFixed(0),
                  ),
                  _StatCard(
                    "🏅 Groups",
                    controller.groupAvgScore.length.toString(),
                  ),
                  _StatCard(
                    "👨‍🎓 Students",
                    controller.allStudents.length.toString(),
                  ),
                  Spacer(),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Card(
          elevation: 3,
          color: kNeutralLightColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blueGrey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
