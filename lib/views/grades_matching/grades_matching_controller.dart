import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:group_leaderboard/helpers/helper.dart';
import 'package:group_leaderboard/views/profile/profile_page.dart';
import 'package:string_similarity/string_similarity.dart';

class GradesMatchingController extends GetxController {
  final students = <Map<String, dynamic>>[].obs;
  final grades = <Map<String, dynamic>>[].obs;
  final matches = <Map<String, dynamic>>[].obs;
  final firestore = FirebaseFirestore.instance;
  RxBool isLoading = true.obs;

  bool get hasStudentsWithoutGrades =>
      students.isNotEmpty &&
      students.any(
        (element) => Helper.isNullOrEmpty(element['linkedGradesId']),
      );

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  void linkStudentToGrade(Map<String, dynamic> student, String gradeId) async {
    Helper.openConfirmationDialog(
      content: "Assign grade $gradeId to ${student['name']}!",
      onConfirm: () async {
        try {
          await firestore.collection("students").doc(student['uid']).update({
            'linkedGradesId': gradeId,
          });

          final index = students.indexWhere((s) => s['uid'] == student['uid']);
          if (index != -1) {
            students[index]['linkedGradesId'] = gradeId;
            students.refresh();
          }

          _sortLinkedStudent();
          students.refresh();

          Helper.snackBar(message: "Linked successfully ✅");
        } catch (e) {
          Helper.snackBar(message: "Error linking student: $e");
        }
      },
    );
  }

  Future<void> _init() async {
    await _fetchStudents();
    await _fetchGrades();
    _suggestMatches();
    isLoading.value = false;
  }

  void _suggestMatches() {
    if (grades.isEmpty) return;
    matches.clear();
    for (var student in students) {
      final studentName = student['name'] ?? '';
      final allMatches =
          grades
              .where((grp) => grp['group'] == student['group'])
              .map(
                (g) => {
                  'target': g['studentName'],
                  'rating': _nameSimilarity(studentName, g['studentName']),
                },
              )
              .where((m) => (m['rating'] as double) > 0.2)
              .toList()
            ..sort(
              (a, b) =>
                  (b['rating'] as double).compareTo(a['rating'] as double),
            );

      if (allMatches.isNotEmpty) {
        matches.add({
          'student': student,
          'suggestions': allMatches, // list of suggestions with ratings
        });
      }
    }
    update();
  }

  Future<void> _fetchStudents() async {
    final snapshot = await firestore.collection('students').get();
    students.assignAll(snapshot.docs.map((e) => e.data()).toList());
    _sortLinkedStudent();
  }

  void _sortLinkedStudent() {
    students.sort((a, b) {
      final aLinked = !Helper.isNullOrEmpty(a['linkedGradesId']);
      final bLinked = !Helper.isNullOrEmpty(b['linkedGradesId']);

      if (aLinked == bLinked) return 0;
      return aLinked ? 1 : -1;
    });
  }

  Future<void> _fetchGrades() async {
    final snapshot = await firestore.collection('scores').get();
    grades.assignAll(
      snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList(),
    );
  }

  double _nameSimilarity(String a, String b) {
    // Normalize
    a = a.toLowerCase().replaceAll(RegExp(r'[^a-z\s]'), '').trim();
    b = b.toLowerCase().replaceAll(RegExp(r'[^a-z\s]'), '').trim();

    final tokensA = a.split(RegExp(r'\s+'));
    final tokensB = b.split(RegExp(r'\s+'));

    // Token-based match score
    int matches = 0;
    for (final tA in tokensA) {
      for (final tB in tokensB) {
        final similarity = tA.similarityTo(tB);
        if (similarity > 0.6) matches++;
      }
    }

    final tokenScore = matches / (tokensA.length + tokensB.length - matches);

    // Fallback to whole-string similarity for fine-tuning
    final globalScore = a.similarityTo(b);

    // Weighted average: favor token overlap but include fuzzy global match
    return (tokenScore * 0.7) + (globalScore * 0.3);
  }

  void openProfile(Map<String, dynamic> student) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Colors.white,
        title: Center(child: Text('${student['name']} Profile\'s')),
        content: SizedBox(
          width: Get.width > 800 ? 800 : Get.width * 0.9,
          height: Get.height * 0.8,
          child: ProfilePage(key: UniqueKey(), studentUID: student['uid']),
        ),
        actions: [TextButton(onPressed: Get.back, child: Text('OK'))],
      ),
    );
  }
}
