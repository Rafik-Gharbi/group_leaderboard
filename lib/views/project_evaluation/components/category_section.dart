import 'package:flutter/material.dart';
import '../../../models/project_evaluation.dart';
import '../project_evaluation_controller.dart';
import 'criterion_score_card.dart';

// Widget for displaying a category with all its criteria
class CategorySection extends StatelessWidget {
  final EvaluationCategory category;
  final ProjectEvaluationController controller;

  const CategorySection({
    super.key,
    required this.category,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
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
            color: _getCategoryColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(_getCategoryIcon(), color: _getCategoryColor(), size: 28),
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
                        color: _getCategoryColor(),
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
                  Text(
                    '${categoryScore.toStringAsFixed(1)} / $maxScore',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(),
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

        // Criteria cards
        ...category.criteria.map(
          (criterion) =>
              CriterionScoreCard(criterion: criterion, controller: controller),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Color _getCategoryColor() {
    switch (category.id) {
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

  IconData _getCategoryIcon() {
    switch (category.id) {
      case 'functional_implementation':
        return Icons.apps;
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
}
