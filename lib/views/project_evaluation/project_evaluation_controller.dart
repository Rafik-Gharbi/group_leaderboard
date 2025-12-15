import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/evaluation_rubric.dart';
import '../../models/project_evaluation.dart';

class ProjectEvaluationController extends GetxController {
  static ProjectEvaluationController get find =>
      Get.find<ProjectEvaluationController>();

  // State management
  final RxList<EvaluationStudent> students = <EvaluationStudent>[].obs;
  final RxMap<String, ProjectEvaluation> evaluations =
      <String, ProjectEvaluation>{}.obs;
  final Rx<EvaluationStudent?> currentStudent = Rx<EvaluationStudent?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isSyncing = false.obs;
  final RxString selectedGroup = 'All'.obs;

  // Current evaluation state
  ProjectEvaluation? get currentEvaluation => currentStudent.value != null
      ? evaluations[currentStudent.value!.id]
      : null;

  // Filtered students based on selected group
  List<EvaluationStudent> get filteredStudents {
    if (selectedGroup.value == 'All') {
      return students;
    }
    return students.where((s) => s.group == selectedGroup.value).toList();
  }

  // Statistics
  int get completedCount =>
      evaluations.values.where((e) => e.isCompleted).length;

  int get totalCount => students.length;

  double get averageScore {
    final completed = evaluations.values.where((e) => e.isCompleted).toList();
    if (completed.isEmpty) return 0.0;
    return completed.fold(0.0, (sum, e) => sum + e.totalScore) /
        completed.length;
  }

  @override
  void onInit() {
    super.onInit();
    _loadFromLocalStorage();
  }

  // Load data from local storage
  Future<void> _loadFromLocalStorage() async {
    try {
      isLoading.value = true;
      final prefs = await SharedPreferences.getInstance();

      // Load students
      final studentsJson = prefs.getString('evaluation_students');
      if (studentsJson != null) {
        final List<dynamic> studentsList = jsonDecode(studentsJson);
        students.value = studentsList
            .map((json) => EvaluationStudent.fromJson(json))
            .toList();
      }

      // Load evaluations
      final evaluationsJson = prefs.getString('evaluations');
      if (evaluationsJson != null) {
        final Map<String, dynamic> evaluationsMap = jsonDecode(evaluationsJson);
        evaluations.value = evaluationsMap.map(
          (key, value) => MapEntry(key, ProjectEvaluation.fromJson(value)),
        );
      }
    } catch (e) {
      debugPrint('Error loading from local storage: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Save data to local storage
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save students
      final studentsJson = jsonEncode(students.map((s) => s.toJson()).toList());
      await prefs.setString('evaluation_students', studentsJson);

      // Save evaluations
      final evaluationsJson = jsonEncode(
        evaluations.map((key, value) => MapEntry(key, value.toJson())),
      );
      await prefs.setString('evaluations', evaluationsJson);
    } catch (e) {
      debugPrint('Error saving to local storage: $e');
    }
  }

  // Add or update student
  Future<void> addOrUpdateStudent(EvaluationStudent student) async {
    final index = students.indexWhere((s) => s.id == student.id);
    if (index != -1) {
      students[index] = student;
    } else {
      students.add(student);
      // Initialize evaluation for new student
      evaluations[student.id] = ProjectEvaluation(
        studentId: student.id,
        studentName: student.name,
        groupName: student.group,
      );
    }
    await _saveToLocalStorage();
  }

  // Remove student
  Future<void> removeStudent(String studentId) async {
    students.removeWhere((s) => s.id == studentId);
    evaluations.remove(studentId);
    await _saveToLocalStorage();
  }

  // Select student for evaluation
  void selectStudent(EvaluationStudent student) {
    currentStudent.value = student;
    // Initialize evaluation if not exists
    if (!evaluations.containsKey(student.id)) {
      evaluations[student.id] = ProjectEvaluation(
        studentId: student.id,
        studentName: student.name,
        groupName: student.group,
      );
    }
  }

  // Navigate to next/previous student
  void navigateToNextStudent() {
    if (currentStudent.value == null) return;
    final filtered = filteredStudents;
    final currentIndex = filtered.indexWhere(
      (s) => s.id == currentStudent.value!.id,
    );
    if (currentIndex < filtered.length - 1) {
      selectStudent(filtered[currentIndex + 1]);
    }
  }

  void navigateToPreviousStudent() {
    if (currentStudent.value == null) return;
    final filtered = filteredStudents;
    final currentIndex = filtered.indexWhere(
      (s) => s.id == currentStudent.value!.id,
    );
    if (currentIndex > 0) {
      selectStudent(filtered[currentIndex - 1]);
    }
  }

  // Update score for a criterion
  Future<void> updateScore(String criterionId, double score) async {
    if (currentStudent.value == null) return;

    final criterion = EvaluationRubricConfig.getCriterionById(criterionId);
    if (criterion == null) return;

    // Validate score
    if (score < 0 || score > criterion.maxScore) {
      Get.snackbar(
        'Erreur',
        'Score doit être entre 0 et ${criterion.maxScore}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final studentId = currentStudent.value!.id;
    final currentEval = evaluations[studentId]!;
    final updatedScores = Map<String, double>.from(currentEval.scores);
    updatedScores[criterionId] = score;

    evaluations[studentId] = currentEval.copyWith(scores: updatedScores);
    await _saveToLocalStorage();
  }

  // Update note for a criterion
  Future<void> updateNote(String criterionId, String note) async {
    if (currentStudent.value == null) return;

    final studentId = currentStudent.value!.id;
    final currentEval = evaluations[studentId]!;
    final updatedComments = Map<String, String>.from(currentEval.comments);

    if (note.isEmpty) {
      updatedComments.remove(criterionId);
    } else {
      updatedComments[criterionId] = note;
    }

    evaluations[studentId] = currentEval.copyWith(comments: updatedComments);
    await _saveToLocalStorage();
  }

  // Update boolean flags
  Future<void> updateFlags({
    bool? understandsPerfectly,
    bool? downloadedFromInternet,
    bool? specificationValid,
    bool? aiDeclaration,
  }) async {
    if (currentStudent.value == null) return;

    final studentId = currentStudent.value!.id;
    final currentEval = evaluations[studentId]!;

    final updatedFlags = Map<String, bool>.from(currentEval.flags);
    if (understandsPerfectly != null) {
      updatedFlags['understandsPerfectly'] = understandsPerfectly;
    }
    if (downloadedFromInternet != null) {
      updatedFlags['downloadedFromInternet'] = downloadedFromInternet;
    }
    if (specificationValid != null) {
      updatedFlags['specificationValid'] = specificationValid;
    }
    if (aiDeclaration != null) {
      updatedFlags['aiDeclaration'] = aiDeclaration;
    }

    evaluations[studentId] = currentEval.copyWith(flags: updatedFlags);
    await _saveToLocalStorage();
  }

  // Mark evaluation as completed
  Future<void> completeEvaluation() async {
    if (currentStudent.value == null) return;

    final studentId = currentStudent.value!.id;
    final currentEval = evaluations[studentId]!;

    evaluations[studentId] = currentEval.copyWith(
      status: 'completed',
      lastSavedAt: DateTime.now(),
    );
    await _saveToLocalStorage();

    Get.snackbar(
      'Succès',
      'Évaluation de ${currentStudent.value!.name} complétée',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    // Auto-navigate to next student
    navigateToNextStudent();
  }

  // Get score for a criterion
  double getScore(String criterionId) {
    return currentEvaluation?.scores[criterionId] ?? 0.0;
  }

  // Get note for a criterion
  String getNote(String criterionId) {
    return currentEvaluation?.comments[criterionId] ?? '';
  }

  // Get category score
  double getCategoryScore(String categoryId) {
    if (currentEvaluation == null) return 0.0;

    final category = EvaluationRubricConfig.getCategoryById(categoryId);
    if (category == null) return 0.0;

    return category.criteria.fold(
      0.0,
      (sum, criterion) =>
          sum + (currentEvaluation!.scores[criterion.id] ?? 0.0),
    );
  }

  // Calculate penalty for downloaded projects
  double calculateFinalScore(String studentId) {
    final evaluation = evaluations[studentId];
    if (evaluation == null) return 0.0;

    double score = evaluation.totalScore;

    // Apply -50% penalty if downloaded from internet
    if (evaluation.downloadedFromInternet) {
      score *= 0.5;
    }

    return score;
  }

  // Import students from JSON or CSV
  Future<void> importStudents(List<Map<String, dynamic>> studentsData) async {
    try {
      isLoading.value = true;
      for (final data in studentsData) {
        final student = EvaluationStudent.fromJson(data);
        await addOrUpdateStudent(student);
      }
      Get.snackbar(
        'Succès',
        '${studentsData.length} étudiants importés',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'importation: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Export evaluations to JSON
  Map<String, dynamic> exportEvaluations() {
    return {
      'students': students.map((s) => s.toJson()).toList(),
      'evaluations': evaluations.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }

  // Clear all data
  Future<void> clearAllData() async {
    students.clear();
    evaluations.clear();
    currentStudent.value = null;
    await _saveToLocalStorage();
  }
}
