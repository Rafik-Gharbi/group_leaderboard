import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/project_evaluation.dart';
import '../project_evaluation_controller.dart';

// Widget for student selection sidebar
class StudentListSidebar extends StatelessWidget {
  final ProjectEvaluationController controller;

  const StudentListSidebar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final filteredStudents = controller.filteredStudents;

      return Container(
        width: 300,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border(right: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Column(
          children: [
            // Header with group filter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Étudiants',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${controller.completedCount} / ${controller.totalCount} complétés',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 12),

                  // Group filter dropdown
                  DropdownButtonFormField<String>(
                    value: controller.selectedGroup.value,
                    decoration: const InputDecoration(
                      labelText: 'Groupe',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: ['All', 'G1', 'G2', 'G3', 'G4', 'G5', 'G6']
                        .map(
                          (group) => DropdownMenuItem(
                            value: group,
                            child: Text(group),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        controller.selectedGroup.value = value;
                      }
                    },
                  ),
                ],
              ),
            ),

            // Student list
            Expanded(
              child: ListView.builder(
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  final evaluation = controller.evaluations[student.id];
                  final isSelected =
                      controller.currentStudent.value?.id == student.id;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Colors.blue[100],
                    leading: CircleAvatar(
                      backgroundColor: evaluation?.isCompleted == true
                          ? Colors.green
                          : Colors.grey,
                      child: Icon(
                        evaluation?.isCompleted == true
                            ? Icons.check
                            : Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      student.name,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Groupe: ${student.group}'),
                        if (evaluation != null)
                          Text(
                            'Score: ${evaluation.totalScore.toStringAsFixed(1)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                    onTap: () => controller.selectStudent(student),
                  );
                },
              ),
            ),

            // Actions footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _showAddStudentDialog(context),
                    icon: const Icon(Icons.person_add),
                    label: const Text('Ajouter Étudiant'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showExportDialog(context),
                    icon: const Icon(Icons.download),
                    label: const Text('Exporter'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 40),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  void _showAddStudentDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String selectedGroup = 'G1';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un étudiant'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedGroup,
              decoration: const InputDecoration(
                labelText: 'Groupe',
                border: OutlineInputBorder(),
              ),
              items: ['G1', 'G2', 'G3', 'G4', 'G5', 'G6']
                  .map(
                    (group) =>
                        DropdownMenuItem(value: group, child: Text(group)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) selectedGroup = value;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final student = EvaluationStudent(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text,
                  group: selectedGroup,
                  email: emailController.text.isNotEmpty
                      ? emailController.text
                      : null,
                );
                controller.addOrUpdateStudent(student);
                Navigator.pop(context);
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporter les évaluations'),
        content: const Text(
          'Les évaluations seront exportées au format JSON et copiées dans le presse-papiers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement export to clipboard
              Navigator.pop(context);
              Get.snackbar(
                'Succès',
                'Évaluations exportées',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            child: const Text('Exporter'),
          ),
        ],
      ),
    );
  }
}
