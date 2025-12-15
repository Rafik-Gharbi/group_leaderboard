import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../constants/evaluation_rubric.dart';
import '../../models/project_evaluation.dart';
import 'project_evaluation_controller_firestore.dart';

/// Firestore-enabled evaluation page
/// This is the main evaluation screen that works with sessions
class ProjectEvaluationPageFirestore extends StatefulWidget {
  static const String routeName = '/project-evaluation-firestore';

  const ProjectEvaluationPageFirestore({super.key});

  @override
  State<ProjectEvaluationPageFirestore> createState() =>
      _ProjectEvaluationPageFirestoreState();
}

class _ProjectEvaluationPageFirestoreState
    extends State<ProjectEvaluationPageFirestore> {
  late ProjectEvaluationControllerFirestore controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = Get.find<ProjectEvaluationControllerFirestore>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();

      // Load default group if session is selected
      if (controller.currentSession.value != null &&
          controller.selectedGroup.value == 'All') {
        controller.loadGroupStudents('G1');
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          title: Obx(
            () => Text(
              controller.currentSession.value?.title ??
                  'Évaluation des Projets',
            ),
          ),
          actions: [
            // Save status indicator
            Obx(() {
              if (controller.isSaving.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Sauvegarde...'),
                      ],
                    ),
                  ),
                );
              }

              if (controller.lastSavedAt.value != null) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Center(
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Sauvegardé ${_formatTime(controller.lastSavedAt.value!)}',
                        ),
                      ],
                    ),
                  ),
                );
              }

              return const SizedBox.shrink();
            }),

            // Statistics
            Obx(
              () => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    'Moyenne: ${controller.averageScore.toStringAsFixed(1)} | '
                    'Complétés: ${controller.completedCount}/${controller.totalCount}',
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Obx(() {
          if (controller.currentSession.value == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning, size: 64, color: Colors.orange[300]),
                  const SizedBox(height: 16),
                  const Text('Aucune session sélectionnée'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour aux sessions'),
                  ),
                ],
              ),
            );
          }

          return Row(
            children: [
              // Left sidebar - Student list with drag & drop
              _buildStudentSidebar(),

              // Main content - Evaluation form
              Expanded(
                child: Obx(() {
                  if (controller.currentStudent.value == null) {
                    return const Center(
                      child: Text('Sélectionnez un étudiant'),
                    );
                  }

                  return SingleChildScrollView(
                    controller: controller.scrollController,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStudentHeader(),
                        const SizedBox(height: 24),
                        _buildEvaluationForm(),
                      ],
                    ),
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStudentSidebar() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Group selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(
              () => DropdownButtonFormField<String>(
                initialValue: controller.selectedGroup.value == 'All'
                    ? null
                    : controller.selectedGroup.value,
                decoration: const InputDecoration(
                  labelText: 'Groupe',
                  border: OutlineInputBorder(),
                ),
                items: ['G1', 'G2', 'G3', 'G4', 'G5', 'G6']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (group) {
                  if (group != null) {
                    controller.loadGroupStudents(group);
                  }
                },
              ),
            ),
          ),

          // Reorderable student list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.students.isEmpty) {
                return const Center(child: Text('Aucun étudiant'));
              }

              return ReorderableListView.builder(
                onReorder: controller.reorderStudents,
                itemCount: controller.students.length,
                itemBuilder: (context, index) {
                  final student = controller.students[index];
                  return Obx(key: ValueKey(student.uid), () {
                    final evaluation = controller.evaluations[student.uid];
                    final isSelected =
                        controller.currentStudent.value?.uid == student.uid;
                    return ListTile(
                      selected: isSelected,
                      leading: CircleAvatar(
                        backgroundColor: evaluation?.status == 'completed'
                            ? Colors.green
                            : evaluation?.status == 'in_progress'
                            ? Colors.orange
                            : Colors.grey,
                        child: Text(
                          evaluation?.status == 'completed'
                              ? '✓'
                              : evaluation?.status == 'in_progress'
                              ? '...'
                              : '○',
                        ),
                      ),
                      title: Text(
                        student.name!,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                      subtitle: evaluation != null
                          ? Text(
                              '${evaluation.totalScore.toStringAsFixed(1)} pts',
                            )
                          : null,
                      onTap: () => controller.selectStudent(student),
                    );
                  });
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentHeader() {
    final student = controller.currentStudent.value!;
    final evaluation = controller.currentEvaluation;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (student.photo != null && student.photo!.isNotEmpty)
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(student.photo!),
                  )
                else
                  const CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 32),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('${student.group} • ${student.email ?? ''}'),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${evaluation?.totalScore.toStringAsFixed(1) ?? 0} / 125',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (evaluation != null)
                      Chip(
                        label: Text(_statusLabel(evaluation.status)),
                        backgroundColor: _statusColor(evaluation.status),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvaluationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Categories
        ...EvaluationRubricConfig.categories.map((category) {
          if (category.id == 'bonus_points' &&
              !controller.understandsPerfectly(
                controller.currentStudent.value!.uid!,
              )) {
            return const SizedBox.shrink();
          } else {
            return _buildCategorySection(category);
          }
        }),

        const SizedBox(height: 24),

        // Flags section
        _buildFlagsSection(),
        const SizedBox(height: 24),

        // Action buttons
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildFlagsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Indicateurs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildFlagChip(
                  'Comprend parfaitement',
                  'understandsPerfectly',
                  Colors.green,
                ),
                _buildFlagChip(
                  'Téléchargé depuis Internet',
                  'downloadedFromInternet',
                  Colors.red,
                ),
                _buildFlagChip(
                  'Spécification Valide',
                  'specificationValid',
                  Colors.blue,
                ),
                _buildFlagChip(
                  'Déclaration de l\'IA',
                  'aiDeclaration',
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlagChip(String label, String flagKey, Color color) {
    return Obx(() {
      final value = controller.getFlag(flagKey);
      return FilterChip(
        label: Text(label),
        selected: value,
        onSelected: (newValue) => controller.updateFlag(flagKey, newValue),
        selectedColor: color.withAlpha(50),
        checkmarkColor: color,
        side: BorderSide(color: value ? color : Colors.grey[400]!),
      );
    });
  }

  Widget _buildCategorySection(EvaluationCategory category) {
    final categoryScore = controller.getCategoryScore(category.id);
    final maxScore = category.maxScore;
    final percentage = maxScore > 0 ? (categoryScore / maxScore * 100) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _getCategoryColor(category.id).withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _getCategoryIcon(category.id),
                color: _getCategoryColor(category.id),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _getCategoryColor(category.id),
                      ),
                    ),
                    Text(
                      category.description,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Obx(
                    () => Text(
                      '${controller.getCategoryScore(category.id).toStringAsFixed(1)} / $maxScore',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getCategoryColor(category.id),
                      ),
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Criteria
        ...category.criteria.map((criterion) {
          return _buildCriterionCard(criterion);
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCriterionCard(EvaluationCriterion criterion) {
    return _CriterionCardWidget(
      key: ValueKey(criterion.id),
      criterion: criterion,
      controller: controller,
    );
  }
}

/// Stateful widget for criterion card to manage text controllers properly
class _CriterionCardWidget extends StatefulWidget {
  final EvaluationCriterion criterion;
  final ProjectEvaluationControllerFirestore controller;

  const _CriterionCardWidget({
    super.key,
    required this.criterion,
    required this.controller,
  });

  @override
  State<_CriterionCardWidget> createState() => _CriterionCardWidgetState();
}

class _CriterionCardWidgetState extends State<_CriterionCardWidget> {
  late TextEditingController _scoreController;
  late TextEditingController _commentController;
  Timer? _commentDebounce;

  @override
  void initState() {
    super.initState();
    final existingScore = widget.controller
        .getScore(widget.criterion.id)
        .toString();
    _scoreController = TextEditingController(
      text: existingScore == '0.0' ? '' : existingScore,
    );
    _commentController = TextEditingController(
      text: widget.controller.getComment(widget.criterion.id),
    );

    // Listen to controller updates to sync text when student changes
    ever(widget.controller.currentStudent, (_) {
      _updateControllersFromData();
    });
  }

  void _updateControllersFromData() {
    final existingScore = widget.controller
        .getScore(widget.criterion.id)
        .toString();
    final newScoreText = existingScore == '0.0' ? '' : existingScore;

    if (_scoreController.text != newScoreText) {
      _scoreController.text = newScoreText;
    }

    final newComment = widget.controller.getComment(widget.criterion.id);
    if (_commentController.text != newComment) {
      _commentController.text = newComment;
    }
  }

  @override
  void dispose() {
    _commentDebounce?.cancel();
    _scoreController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _onCommentChanged(String value) {
    // Cancel previous timer
    _commentDebounce?.cancel();

    // Set new timer for 1000ms
    _commentDebounce = Timer(const Duration(seconds: 1), () {
      widget.controller.updateComment(widget.criterion.id, value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentScore = widget.controller.getScore(widget.criterion.id);
      final progress = currentScore / widget.criterion.maxScore;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Criterion header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.criterion.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.criterion.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Score input
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: _scoreController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Score',
                        suffix: Text('/${widget.criterion.maxScore}'),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        final score = double.tryParse(value);
                        if (score != null) {
                          widget.controller.updateScore(
                            widget.criterion.id,
                            score,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getColorForProgress(progress),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Comments field
              TextField(
                controller: _commentController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Commentaires',
                  hintText: 'Commentaires additionnels...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: _onCommentChanged,
              ),
            ],
          ),
        ),
      );
    });
  }

  Color _getColorForProgress(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.6) return Colors.lightGreen;
    if (progress >= 0.4) return Colors.orange;
    return Colors.red;
  }
}

// Extension methods for the main state class
extension _ProjectEvaluationPageFirestoreStateExtensions
    on _ProjectEvaluationPageFirestoreState {
  Widget _buildActionButtons() {
    return Obx(() {
      final evaluation = controller.currentEvaluation;
      final isCompleted = evaluation?.status == 'completed';

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Score summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score Total',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${evaluation?.totalScore.toStringAsFixed(1) ?? 0} / 125',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          ),
          // const SizedBox(width: 16),

          // Complete button
          ElevatedButton.icon(
            onPressed: isCompleted ? null : controller.completeEvaluation,
            icon: const Icon(Icons.check_circle, color: Colors.white),
            label: Text(
              isCompleted ? 'Complété' : 'Terminer l\'évaluation',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompleted ? Colors.green.shade600 : null,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      );
    });
  }

  Color _getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'functional_implementation':
        return Colors.blue;
      case 'design_ui_ux':
        return Colors.purple;
      case 'technical_quality':
        return Colors.teal;
      case 'presentation_questions_live':
        return Colors.orange;
      case 'bonus_points':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String categoryId) {
    switch (categoryId) {
      case 'functional_implementation':
        return Icons.check_circle_outline;
      case 'design_ui_ux':
        return Icons.palette;
      case 'technical_quality':
        return Icons.code;
      case 'presentation_questions_live':
        return Icons.present_to_all;
      case 'bonus_points':
        return Icons.star;
      default:
        return Icons.category;
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      controller.navigateToNextStudent();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      controller.navigateToPreviousStudent();
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return 'à l\'instant';
    } else if (diff.inMinutes < 60) {
      return 'il y a ${diff.inMinutes}min';
    } else {
      return 'à ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Terminé';
      case 'in_progress':
        return 'En cours';
      default:
        return 'Non commencé';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green[100]!;
      case 'in_progress':
        return Colors.orange[100]!;
      default:
        return Colors.grey[200]!;
    }
  }
}
