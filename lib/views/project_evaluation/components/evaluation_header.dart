import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../constants/evaluation_rubric.dart';
import '../project_evaluation_controller.dart';

// Widget for displaying evaluation summary and controls
class EvaluationHeader extends StatelessWidget {
  final ProjectEvaluationController controller;

  const EvaluationHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final student = controller.currentStudent.value;
      final evaluation = controller.currentEvaluation;

      if (student == null || evaluation == null) {
        return const Center(
          child: Text(
            'Sélectionnez un étudiant pour commencer',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        );
      }

      final baseScore = EvaluationRubricConfig.categories
          .where((cat) => cat.id != 'bonus_points')
          .fold(0.0, (sum, cat) => sum + controller.getCategoryScore(cat.id));

      final bonusScore = controller.getCategoryScore('bonus_points');
      final totalScore = evaluation.totalScore;
      final finalScore = controller.calculateFinalScore(student.id);
      final hasPenalty = evaluation.downloadedFromInternet;

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student info and navigation
            Row(
              children: [
                // Previous button
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: controller.navigateToPreviousStudent,
                  tooltip: 'Étudiant précédent',
                ),

                // Student info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Groupe: ${student.group}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (student.email != null) ...[
                            const SizedBox(width: 16),
                            Text(
                              student.email!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          if (student.isInPair) ...[
                            const SizedBox(width: 16),
                            Chip(
                              label: const Text('En binôme'),
                              backgroundColor: Colors.blue[100],
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Next button
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: controller.navigateToNextStudent,
                  tooltip: 'Étudiant suivant',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Score summary
            Row(
              children: [
                // Base score
                _ScoreCard(
                  title: 'Note de Base',
                  score: baseScore,
                  maxScore: EvaluationRubricConfig.maxBaseScore,
                  color: Colors.blue,
                ),
                const SizedBox(width: 16),

                // Bonus score
                _ScoreCard(
                  title: 'Bonus',
                  score: bonusScore,
                  maxScore: 25,
                  color: Colors.green,
                ),
                const SizedBox(width: 16),

                // Total score
                _ScoreCard(
                  title: 'Total',
                  score: totalScore,
                  maxScore: EvaluationRubricConfig.maxTotalScore,
                  color: Colors.purple,
                  isTotal: true,
                ),

                if (hasPenalty) ...[
                  const SizedBox(width: 16),
                  _ScoreCard(
                    title: 'Note Finale (-50%)',
                    score: finalScore,
                    maxScore: EvaluationRubricConfig.maxTotalScore,
                    color: Colors.red,
                    isTotal: true,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),

            // Flags and actions
            Row(
              children: [
                // Flags
                Expanded(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _FlagChip(
                        label: 'Comprend parfaitement',
                        value: evaluation.understandsPerfectly,
                        onChanged: (value) =>
                            controller.updateFlags(understandsPerfectly: value),
                        color: Colors.green,
                      ),
                      _FlagChip(
                        label: 'Téléchargé depuis Internet',
                        value: evaluation.downloadedFromInternet,
                        onChanged: (value) => controller.updateFlags(
                          downloadedFromInternet: value,
                        ),
                        color: Colors.red,
                      ),
                      _FlagChip(
                        label: 'Spécification Valide',
                        value: evaluation.specificationValid,
                        onChanged: (value) =>
                            controller.updateFlags(specificationValid: value),
                        color: Colors.blue,
                      ),
                      _FlagChip(
                        label: 'Déclaration de l\'IA',
                        value: evaluation.aiDeclaration,
                        onChanged: (value) =>
                            controller.updateFlags(aiDeclaration: value),
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Complete button
                ElevatedButton.icon(
                  onPressed: evaluation.isCompleted
                      ? null
                      : controller.completeEvaluation,
                  icon: const Icon(Icons.check_circle),
                  label: Text(
                    evaluation.isCompleted
                        ? 'Complété'
                        : 'Terminer l\'évaluation',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: evaluation.isCompleted
                        ? Colors.green
                        : null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _ScoreCard extends StatelessWidget {
  final String title;
  final double score;
  final double maxScore;
  final Color color;
  final bool isTotal;

  const _ScoreCard({
    required this.title,
    required this.score,
    required this.maxScore,
    required this.color,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score / maxScore * 100).toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${score.toStringAsFixed(1)} / $maxScore',
            style: TextStyle(
              fontSize: isTotal ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            '$percentage%',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color color;

  const _FlagChip({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      side: BorderSide(color: value ? color : Colors.grey[400]!),
    );
  }
}
