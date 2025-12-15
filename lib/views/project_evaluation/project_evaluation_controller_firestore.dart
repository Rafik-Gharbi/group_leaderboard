import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/evaluation_rubric.dart';
import '../../helpers/save_debouncer.dart';
import '../../models/project_evaluation.dart';
import '../../models/user.dart';
import '../../services/firestore_evaluation_service.dart';

/// Firestore-enabled evaluation controller with auto-save
class ProjectEvaluationControllerFirestore extends GetxController {
  static ProjectEvaluationControllerFirestore get find =>
      Get.find<ProjectEvaluationControllerFirestore>();

  final FirestoreEvaluationService _firestoreService =
      FirestoreEvaluationService();
  final SaveDebouncer _saveDebouncer = SaveDebouncer();

  // Current session
  final Rx<EvaluationSession?> currentSession = Rx<EvaluationSession?>(null);

  // State management
  final RxList<User> students = <User>[].obs;
  final RxList<String> studentOrder = <String>[].obs;
  final RxMap<String, ProjectEvaluation> evaluations =
      <String, ProjectEvaluation>{}.obs;
  final Rx<User?> currentStudent = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxBool hasUnsavedChanges = false.obs;
  final Rx<DateTime?> lastSavedAt = Rx<DateTime?>(null);
  final RxString selectedGroup = 'All'.obs;
  final scrollController = ScrollController();

  // Current evaluation state
  ProjectEvaluation? get currentEvaluation => currentStudent.value != null
      ? evaluations[currentStudent.value!.uid]
      : null;

  // Filtered students based on selected group
  List<User> get filteredStudents {
    if (selectedGroup.value == 'All') {
      return students;
    }
    return students.where((s) => s.group == selectedGroup.value).toList();
  }

  // Statistics
  int get completedCount =>
      evaluations.values.where((e) => e.status == 'completed').length;

  int get inProgressCount =>
      evaluations.values.where((e) => e.status == 'in_progress').length;

  int get totalCount => students.length;

  double get averageScore {
    final completed = evaluations.values
        .where((e) => e.status == 'completed')
        .toList();
    if (completed.isEmpty) return 0.0;
    return completed.fold(0.0, (sum, e) => sum + e.totalScore) /
        completed.length;
  }

  @override
  void onClose() {
    _saveDebouncer.dispose();
    super.onClose();
  }

  // ========== Session Management ==========

  /// Load sessions list
  Future<List<EvaluationSession>> getSessions() async {
    return await _firestoreService.getSessions();
  }

  /// Create new session
  Future<void> createSession(String title) async {
    try {
      isLoading.value = true;
      final sessionId = await _firestoreService.createSession(title);

      // Initialize groups from existing students
      await _firestoreService.initializeGroupsFromStudents(sessionId);

      // Load the new session
      final sessions = await getSessions();
      currentSession.value = sessions.firstWhere((s) => s.id == sessionId);

      Get.snackbar(
        'Succès',
        'Session créée: $title',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      debugPrint('Error creating session: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de créer la session',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Select and load a session
  Future<void> selectSession(EvaluationSession session) async {
    try {
      isLoading.value = true;
      currentSession.value = session;

      // Load evaluations for this session
      final evals = await _firestoreService.getAllEvaluations(session.id);
      evaluations.value = evals;

      // Load students for current group
      if (selectedGroup.value != 'All') {
        await loadGroupStudents(selectedGroup.value);
      }

      debugPrint(
        'Loaded session: ${session.title} with ${evals.length} evaluations',
      );
    } catch (e) {
      debugPrint('Error loading session: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger la session',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ========== Student Management ==========

  /// Load students for a specific group
  Future<void> loadGroupStudents(String group) async {
    if (currentSession.value == null) {
      Get.snackbar(
        'Erreur',
        'Aucune session sélectionnée',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;
      selectedGroup.value = group;

      // Get ordered students from Firestore
      final orderedStudents = await _firestoreService.getOrderedStudents(
        currentSession.value!.id,
        group,
      );

      final allStudents = await _firestoreService.getStudentsByGroup(group);

      // Remove already ordered students from allStudents and add all students at the end
      for (final student in orderedStudents) {
        allStudents.removeWhere((s) => s.uid == student.uid);
      }
      orderedStudents.addAll(allStudents.where((s) => s.group == group));

      students.value = orderedStudents;
      studentOrder.value = orderedStudents.map((s) => s.uid!).toList();

      // Ensure evaluations exist for all students with correct studentName
      for (final student in orderedStudents) {
        if (!evaluations.containsKey(student.uid)) {
          evaluations[student.uid!] = ProjectEvaluation(
            studentId: student.uid!,
            studentName: student.name!,
            groupName: student.group!,
          );
        } else {
          // Update student name in existing evaluation
          final eval = evaluations[student.uid!]!;
          evaluations[student.uid!] = eval.copyWith(studentName: student.name);
        }
      }

      debugPrint('Loaded ${orderedStudents.length} students for group $group');
    } catch (e) {
      debugPrint('Error loading students: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les étudiants',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Reorder students (for drag & drop)
  Future<void> reorderStudents(int oldIndex, int newIndex) async {
    if (currentSession.value == null) return;
    if (newIndex > oldIndex) newIndex--;

    // Update local list
    final student = students.removeAt(oldIndex);
    students.insert(newIndex, student);

    // Update order list
    final uid = studentOrder.removeAt(oldIndex);
    studentOrder.insert(newIndex, uid);

    // Save to Firestore (debounced)
    _saveDebouncer.run(() async {
      try {
        await _firestoreService.updateStudentOrder(
          currentSession.value!.id,
          selectedGroup.value,
          studentOrder.toList(),
        );
        debugPrint('Student order saved');
      } catch (e) {
        debugPrint('Error saving student order: $e');
      }
    });
  }

  // ========== Student Selection & Navigation ==========

  /// Select student for evaluation
  void selectStudent(User student) {
    currentStudent.value = student;

    // Mark as in progress if not already completed
    final eval = evaluations[student.uid];
    if (eval != null && eval.status == 'not_started') {
      updateStatus('in_progress');
    }
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: Durations.medium1,
        curve: Curves.easeInOut,
      );
    }
  }

  /// Navigate to next student in order
  void navigateToNextStudent() {
    if (currentStudent.value == null) return;

    final currentIndex = students.indexWhere(
      (s) => s.uid == currentStudent.value!.uid,
    );

    if (currentIndex < students.length - 1) {
      selectStudent(students[currentIndex + 1]);
    }
  }

  /// Navigate to previous student
  void navigateToPreviousStudent() {
    if (currentStudent.value == null) return;

    final currentIndex = students.indexWhere(
      (s) => s.uid == currentStudent.value!.uid,
    );

    if (currentIndex > 0) {
      selectStudent(students[currentIndex - 1]);
    }
  }

  // ========== Evaluation Updates (with auto-save) ==========

  /// Update score for a criterion
  Future<void> updateScore(String criterionId, double score) async {
    if (currentStudent.value == null || currentSession.value == null) return;

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

    final studentUid = currentStudent.value!.uid!;
    final currentEval = evaluations[studentUid]!;
    final updatedScores = Map<String, double>.from(currentEval.scores);
    updatedScores[criterionId] = score;

    // Update local state immediately
    evaluations[studentUid] = currentEval.copyWith(scores: updatedScores);
    hasUnsavedChanges.value = true;

    // Debounced save to Firestore
    _debouncedSave(studentUid);
  }

  /// Update comment for a criterion
  Future<void> updateComment(String criterionId, String comment) async {
    if (currentStudent.value == null || currentSession.value == null) return;

    final studentUid = currentStudent.value!.uid!;
    final currentEval = evaluations[studentUid]!;
    final updatedComments = Map<String, String>.from(currentEval.comments);

    if (comment.isEmpty) {
      updatedComments.remove(criterionId);
    } else {
      updatedComments[criterionId] = comment;
    }

    evaluations[studentUid] = currentEval.copyWith(comments: updatedComments);
    hasUnsavedChanges.value = true;

    _debouncedSave(studentUid);
  }

  /// Update boolean flags
  Future<void> updateFlag(String flagName, bool value) async {
    if (currentStudent.value == null || currentSession.value == null) return;

    final studentUid = currentStudent.value!.uid!;
    final currentEval = evaluations[studentUid]!;
    final updatedFlags = Map<String, bool>.from(currentEval.flags);
    updatedFlags[flagName] = value;

    evaluations[studentUid] = currentEval.copyWith(flags: updatedFlags);
    hasUnsavedChanges.value = true;

    _debouncedSave(studentUid);
  }

  bool understandsPerfectly(String studentUid) {
    final eval = evaluations[studentUid];
    if (eval == null) return false;
    return eval.understandsPerfectly;
  }

  /// Update status
  Future<void> updateStatus(String status) async {
    if (currentStudent.value == null || currentSession.value == null) return;

    final studentUid = currentStudent.value!.uid!;
    final currentEval = evaluations[studentUid]!;

    evaluations[studentUid] = currentEval.copyWith(status: status);
    hasUnsavedChanges.value = true;

    _debouncedSave(studentUid);
  }

  /// Mark evaluation as completed
  Future<void> completeEvaluation() async {
    if (currentStudent.value == null) return;

    await updateStatus('completed');

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

  /// Debounced save to Firestore
  void _debouncedSave(String studentUid) {
    _saveDebouncer.run(() async {
      await _saveToFirestore(studentUid);
    });
  }

  /// Save evaluation to Firestore
  Future<void> _saveToFirestore(String studentUid) async {
    if (currentSession.value == null) return;

    try {
      isSaving.value = true;

      final evaluation = evaluations[studentUid];
      if (evaluation == null) return;

      await _firestoreService.saveEvaluation(
        currentSession.value!.id,
        studentUid,
        evaluation,
      );

      hasUnsavedChanges.value = false;
      lastSavedAt.value = DateTime.now();

      debugPrint('Saved evaluation for $studentUid');
    } catch (e) {
      debugPrint('Error saving evaluation: $e');
      Get.snackbar(
        'Erreur de sauvegarde',
        'Réessai automatique en cours...',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    } finally {
      isSaving.value = false;
    }
  }

  // ========== Getters ==========

  double getScore(String criterionId) {
    return currentEvaluation?.scores[criterionId] ?? 0.0;
  }

  String getComment(String criterionId) {
    return currentEvaluation?.comments[criterionId] ?? '';
  }

  bool getFlag(String flagName) {
    return currentEvaluation?.flags[flagName] ?? false;
  }

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

  double calculateFinalScore(String studentUid) {
    final evaluation = evaluations[studentUid];
    if (evaluation == null) return 0.0;

    double score = evaluation.totalScore;

    if (evaluation.downloadedFromInternet) {
      score *= 0.5;
    }

    return score;
  }
}
