import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OverviewController extends GetxController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final groupSumScore = <String, double>{}.obs;
  final allStudents = [].obs;
  final totalXp = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOverview();
  }

  Future<void> fetchOverview() async {
    final snapshot = await _db.collection('scores').get();
    final data = snapshot.docs.map((e) => e.data()).toList();

    final Map<String, List<double>> groupScores = {};

    double total = 0;
    for (var d in data) {
      final group = d['group'];
      final score = (d['totalScore'] ?? 0).toDouble();
      groupScores.putIfAbsent(group, () => []).add(score);
      total += score;
    }

    // Compute averages
    final sumScores = {
      for (var entry in groupScores.entries)
        entry.key: entry.value.reduce((a, b) => a + b),
    };

    groupSumScore.assignAll(sumScores);
    totalXp.value = total;

    // Top 3 students
    data.sort((a, b) => (b['totalScore'] ?? 0).compareTo(a['totalScore'] ?? 0));
    allStudents.assignAll(data);
  }

  double roundUpToHundred(double number) {
    return ((number + 99) ~/ 100) * 100;
  }
}
