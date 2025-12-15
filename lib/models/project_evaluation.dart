// Model for representing a student's project evaluation
class ProjectEvaluation {
  final String studentId;
  final String studentName;
  final String groupName;
  final String status; // not_started | in_progress | completed
  final Map<String, double> scores; // criteriaId -> score
  final Map<String, String> comments; // criteriaId -> comment
  final Map<String, bool> flags; // flag name -> value
  final DateTime? lastSavedAt;

  ProjectEvaluation({
    required this.studentId,
    required this.studentName,
    required this.groupName,
    this.status = 'not_started',
    this.scores = const {},
    this.comments = const {},
    this.flags = const {},
    this.lastSavedAt,
  });

  // Convenience getters for specific flags
  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isNotStarted => status == 'not_started';

  bool get understandsPerfectly => flags['understandsPerfectly'] ?? false;
  bool get downloadedFromInternet => flags['downloadedFromInternet'] ?? false;
  bool get specificationValid => flags['specificationValid'] ?? false;
  bool get aiDeclaration => flags['aiDeclaration'] ?? false;

  double get totalScore {
    return scores.values.fold(0.0, (sum, score) => sum + score);
  }

  ProjectEvaluation copyWith({
    String? studentId,
    String? studentName,
    String? groupName,
    String? status,
    Map<String, double>? scores,
    Map<String, String>? comments,
    Map<String, bool>? flags,
    DateTime? lastSavedAt,
  }) {
    return ProjectEvaluation(
      studentId: studentId ?? this.studentId,
      studentName: studentName ?? this.studentName,
      groupName: groupName ?? this.groupName,
      status: status ?? this.status,
      scores: scores ?? this.scores,
      comments: comments ?? this.comments,
      flags: flags ?? this.flags,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    );
  }

  // Firestore serialization (used by service)
  Map<String, dynamic> toFirestore() {
    return {
      'studentUid': studentId,
      'group': groupName,
      'status': status,
      'scores': scores,
      'flags': flags,
      'comments': comments,
    };
  }

  factory ProjectEvaluation.fromFirestore(
    Map<String, dynamic> data,
    String studentUid,
  ) {
    // Handle both old and new formats
    final scoresData = data['scores'] ?? {};
    final Map<String, double> parsedScores = {};
    scoresData.forEach((key, value) {
      if (value != null) {
        parsedScores[key] = (value is int) ? value.toDouble() : value as double;
      }
    });

    return ProjectEvaluation(
      studentId: studentUid,
      studentName: '', // Will be filled from student data
      groupName: data['group'] as String? ?? '',
      status: data['status'] as String? ?? 'not_started',
      scores: parsedScores,
      comments: Map<String, String>.from(data['comments'] ?? {}),
      flags: Map<String, bool>.from(data['flags'] ?? {}),
      lastSavedAt: data['lastSavedAt'] != null
          ? (data['lastSavedAt'] as dynamic).toDate()
          : null,
    );
  }

  // Legacy JSON methods for backward compatibility
  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'groupName': groupName,
      'status': status,
      'scores': scores,
      'comments': comments,
      'flags': flags,
      'lastSavedAt': lastSavedAt?.toIso8601String(),
      'totalScore': totalScore,
    };
  }

  factory ProjectEvaluation.fromJson(Map<String, dynamic> json) {
    // Handle migration from old format
    final Map<String, bool> parsedFlags = {};
    if (json.containsKey('flags')) {
      parsedFlags.addAll(Map<String, bool>.from(json['flags']));
    } else {
      // Migrate from old format
      parsedFlags['understandsPerfectly'] =
          json['understandsPerfectly'] as bool? ?? false;
      parsedFlags['downloadedFromInternet'] =
          json['downloadedFromInternet'] as bool? ?? false;
      parsedFlags['specificationValid'] =
          json['specificationValid'] as bool? ?? false;
      parsedFlags['aiDeclaration'] = json['aiDeclaration'] as bool? ?? false;
    }

    return ProjectEvaluation(
      studentId: json['studentId'] as String,
      studentName: json['studentName'] as String,
      groupName: json['groupName'] as String,
      status:
          json['status'] as String? ??
          (json['isCompleted'] == true ? 'completed' : 'not_started'),
      scores: Map<String, double>.from(json['scores'] ?? {}),
      comments: Map<String, String>.from(
        json['comments'] ?? json['notes'] ?? {},
      ),
      flags: parsedFlags,
      lastSavedAt: json['lastSavedAt'] != null
          ? DateTime.parse(json['lastSavedAt'] as String)
          : json['evaluationDate'] != null
          ? DateTime.parse(json['evaluationDate'] as String)
          : null,
    );
  }
}

// Model for evaluation criteria
class EvaluationCriterion {
  final String id;
  final String name;
  final String description;
  final double maxScore;
  final String category;
  final int order;

  const EvaluationCriterion({
    required this.id,
    required this.name,
    required this.description,
    required this.maxScore,
    required this.category,
    required this.order,
  });
}

// Model for evaluation categories
class EvaluationCategory {
  final String id;
  final String name;
  final String description;
  final List<EvaluationCriterion> criteria;
  final int order;

  const EvaluationCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.criteria,
    required this.order,
  });

  double get maxScore {
    return criteria.fold(0.0, (sum, criterion) => sum + criterion.maxScore);
  }
}

// Model for student info in evaluation
class EvaluationStudent {
  final String id;
  final String name;
  final String group;
  final String? email;
  final bool isInPair;
  final String? partnerId;

  const EvaluationStudent({
    required this.id,
    required this.name,
    required this.group,
    this.email,
    this.isInPair = false,
    this.partnerId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'group': group,
      'email': email,
      'isInPair': isInPair,
      'partnerId': partnerId,
    };
  }

  factory EvaluationStudent.fromJson(Map<String, dynamic> json) {
    return EvaluationStudent(
      id: json['id'] as String,
      name: json['name'] as String,
      group: json['group'] as String,
      email: json['email'] as String?,
      isInPair: json['isInPair'] as bool? ?? false,
      partnerId: json['partnerId'] as String?,
    );
  }
}
