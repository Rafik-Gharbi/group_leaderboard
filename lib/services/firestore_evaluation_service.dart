import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/project_evaluation.dart';
import '../models/user.dart';

/// Service for managing evaluation data in Firestore
///
/// Structure:
/// - evaluationSessions/{sessionId}
///   - groups/{groupId} (with studentOrder)
///   - evaluations/{studentUid}
class FirestoreEvaluationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== Evaluation Sessions ==========

  /// Create a new evaluation session
  Future<String> createSession(String title) async {
    final docRef = await _firestore.collection('evaluationSessions').add({
      'title': title,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Get all evaluation sessions
  Future<List<EvaluationSession>> getSessions() async {
    final snapshot = await _firestore
        .collection('evaluationSessions')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return EvaluationSession(
        id: doc.id,
        title: data['title'] as String,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  /// Update session title
  Future<void> updateSessionTitle(String sessionId, String title) async {
    await _firestore.collection('evaluationSessions').doc(sessionId).update({
      'title': title,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a session and all its data
  Future<void> deleteSession(String sessionId) async {
    final sessionRef = _firestore
        .collection('evaluationSessions')
        .doc(sessionId);

    // Delete all groups
    final groups = await sessionRef.collection('groups').get();
    for (final group in groups.docs) {
      await group.reference.delete();
    }

    // Delete all evaluations
    final evaluations = await sessionRef.collection('evaluations').get();
    for (final evaluation in evaluations.docs) {
      await evaluation.reference.delete();
    }

    // Delete session
    await sessionRef.delete();
  }

  // ========== Groups & Student Order ==========

  /// Initialize groups for a session with students from Firestore
  Future<void> initializeGroupsFromStudents(String sessionId) async {
    // Get all students from the students collection
    final studentsSnapshot = await _firestore
        .collection('scores')
        .orderBy('group')
        .orderBy('studentName')
        .get();

    // Group students by their group field
    final Map<String, List<String>> groupedStudents = {};

    for (final doc in studentsSnapshot.docs) {
      final data = doc.data();
      final group = data['group'] as String?;
      if (group != null) {
        groupedStudents.putIfAbsent(group, () => []);
        groupedStudents[group]!.add(doc.id);
      }
    }

    // Create group documents
    final sessionRef = _firestore
        .collection('evaluationSessions')
        .doc(sessionId);

    for (final entry in groupedStudents.entries) {
      await sessionRef.collection('groups').doc(entry.key).set({
        'groupId': entry.key,
        'studentOrder': entry.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Get student order for a group
  Future<List<String>> getStudentOrder(String sessionId, String groupId) async {
    final doc = await _firestore
        .collection('evaluationSessions')
        .doc(sessionId)
        .collection('groups')
        .doc(groupId)
        .get();

    if (!doc.exists) return [];

    final data = doc.data();
    return List<String>.from(data?['studentOrder'] ?? []);
  }

  /// Update student order for a group (for drag & drop)
  Future<void> updateStudentOrder(
    String sessionId,
    String groupId,
    List<String> studentOrder,
  ) async {
    await _firestore
        .collection('evaluationSessions')
        .doc(sessionId)
        .collection('groups')
        .doc(groupId)
        .set({
          'groupId': groupId,
          'studentOrder': studentOrder,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  /// Get all groups for a session
  Future<List<String>> getGroups(String sessionId) async {
    final snapshot = await _firestore
        .collection('evaluationSessions')
        .doc(sessionId)
        .collection('groups')
        .get();

    return snapshot.docs.map((doc) => doc.id).toList();
  }

  // ========== Students (Read-Only) ==========

  /// Fetch students from the existing students collection
  Future<List<User>> getStudentsByGroup(String group) async {
    final snapshot = await _firestore
        .collection('scores')
        .where('group', isEqualTo: group)
        .orderBy('studentName')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return User.fromData(data, picture: data['photo'], uid: doc.id);
    }).toList();
  }

  /// Fetch all students
  Future<List<User>> getAllStudents() async {
    final snapshot = await _firestore
        .collection('scores')
        .orderBy('group')
        .orderBy('studentName')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return User.fromData(data, picture: data['photo'], uid: doc.id);
    }).toList();
  }

  /// Get students in order for a session and group
  Future<List<User>> getOrderedStudents(
    String sessionId,
    String groupId,
  ) async {
    // Get the order
    final order = await getStudentOrder(sessionId, groupId);
    if (order.isEmpty) return [];

    // Fetch all students
    final students = await getStudentsByGroup(groupId);

    // Create a map for quick lookup
    final studentMap = {for (var s in students) s.uid!: s};

    // Return in order, filtering out any UIDs that don't exist
    return order
        .where((uid) => studentMap.containsKey(uid))
        .map((uid) => studentMap[uid]!)
        .toList();
  }

  // ========== Evaluations ==========

  /// Get evaluation for a student
  Future<ProjectEvaluation?> getEvaluation(
    String sessionId,
    String studentUid,
  ) async {
    final doc = await _firestore
        .collection('evaluationSessions')
        .doc(sessionId)
        .collection('evaluations')
        .doc(studentUid)
        .get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    return ProjectEvaluation.fromFirestore(data, studentUid);
  }

  /// Create or update evaluation (partial updates supported)
  Future<void> saveEvaluation(
    String sessionId,
    String studentUid,
    ProjectEvaluation evaluation,
  ) async {
    final data = evaluation.toFirestore();
    data['lastSavedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('evaluationSessions')
        .doc(sessionId)
        .collection('evaluations')
        .doc(studentUid)
        .set(data, SetOptions(merge: true));
  }

  /// Update specific fields in evaluation (for efficient partial updates)
  Future<void> updateEvaluationFields(
    String sessionId,
    String studentUid,
    Map<String, dynamic> fields,
  ) async {
    fields['lastSavedAt'] = FieldValue.serverTimestamp();

    await _firestore
        .collection('evaluationSessions')
        .doc(sessionId)
        .collection('evaluations')
        .doc(studentUid)
        .update(fields);
  }

  /// Get all evaluations for a session
  Future<Map<String, ProjectEvaluation>> getAllEvaluations(
    String sessionId,
  ) async {
    final snapshot = await _firestore
        .collection('evaluationSessions')
        .doc(sessionId)
        .collection('evaluations')
        .get();

    final Map<String, ProjectEvaluation> evaluations = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      evaluations[doc.id] = ProjectEvaluation.fromFirestore(data, doc.id);
    }

    return evaluations;
  }

  /// Stream evaluation updates in real-time
  Stream<ProjectEvaluation?> streamEvaluation(
    String sessionId,
    String studentUid,
  ) {
    return _firestore
        .collection('evaluationSessions')
        .doc(sessionId)
        .collection('evaluations')
        .doc(studentUid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          final data = doc.data()!;
          return ProjectEvaluation.fromFirestore(data, studentUid);
        });
  }

  // ========== Statistics ==========

  /// Get completion statistics for a session
  Future<EvaluationStatistics> getStatistics(String sessionId) async {
    final evaluations = await getAllEvaluations(sessionId);

    final total = evaluations.length;
    final completed = evaluations.values
        .where((e) => e.status == 'completed')
        .length;
    final inProgress = evaluations.values
        .where((e) => e.status == 'in_progress')
        .length;
    final notStarted = evaluations.values
        .where((e) => e.status == 'not_started')
        .length;

    final completedScores = evaluations.values
        .where((e) => e.status == 'completed')
        .map((e) => e.totalScore)
        .toList();

    final averageScore = completedScores.isEmpty
        ? 0.0
        : completedScores.reduce((a, b) => a + b) / completedScores.length;

    return EvaluationStatistics(
      total: total,
      completed: completed,
      inProgress: inProgress,
      notStarted: notStarted,
      averageScore: averageScore,
    );
  }
}

/// Model for evaluation session
class EvaluationSession {
  final String id;
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EvaluationSession({
    required this.id,
    required this.title,
    this.createdAt,
    this.updatedAt,
  });
}

/// Model for statistics
class EvaluationStatistics {
  final int total;
  final int completed;
  final int inProgress;
  final int notStarted;
  final double averageScore;

  EvaluationStatistics({
    required this.total,
    required this.completed,
    required this.inProgress,
    required this.notStarted,
    required this.averageScore,
  });
}
