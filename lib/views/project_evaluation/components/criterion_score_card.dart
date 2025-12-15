import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/project_evaluation.dart';
import '../project_evaluation_controller.dart';

// Widget for displaying and editing a single criterion score
class CriterionScoreCard extends StatefulWidget {
  final EvaluationCriterion criterion;
  final ProjectEvaluationController controller;

  const CriterionScoreCard({
    super.key,
    required this.criterion,
    required this.controller,
  });

  @override
  State<CriterionScoreCard> createState() => _CriterionScoreCardState();
}

class _CriterionScoreCardState extends State<CriterionScoreCard> {
  late TextEditingController _scoreController;
  late TextEditingController _noteController;
  final FocusNode _scoreFocusNode = FocusNode();
  final FocusNode _noteFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scoreController = TextEditingController(
      text: widget.controller.getScore(widget.criterion.id).toString(),
    );
    _noteController = TextEditingController(
      text: widget.controller.getNote(widget.criterion.id),
    );
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _noteController.dispose();
    _scoreFocusNode.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  void _updateScore() {
    final score = double.tryParse(_scoreController.text);
    if (score != null) {
      widget.controller.updateScore(widget.criterion.id, score);
    }
  }

  void _updateNote() {
    widget.controller.updateNote(widget.criterion.id, _noteController.text);
  }

  @override
  Widget build(BuildContext context) {
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
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Score input
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _scoreController,
                    focusNode: _scoreFocusNode,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Score',
                      suffix: Text('/${widget.criterion.maxScore}'),
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => _updateScore(),
                    onSubmitted: (_) {
                      _updateScore();
                      _noteFocusNode.requestFocus();
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

            // Notes field
            TextField(
              controller: _noteController,
              focusNode: _noteFocusNode,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Commentaires additionnels...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _updateNote(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForProgress(double progress) {
    if (progress >= 0.8) return Colors.green;
    if (progress >= 0.6) return Colors.lightGreen;
    if (progress >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
