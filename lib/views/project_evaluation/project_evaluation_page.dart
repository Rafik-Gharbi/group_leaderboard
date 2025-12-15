import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../constants/evaluation_rubric.dart';
import 'components/category_section.dart';
import 'components/evaluation_header.dart';
import 'components/student_list_sidebar.dart';
import 'project_evaluation_controller.dart';

class ProjectEvaluationPage extends StatefulWidget {
  static const String routeName = '/project-evaluation';

  const ProjectEvaluationPage({super.key});

  @override
  State<ProjectEvaluationPage> createState() => _ProjectEvaluationPageState();
}

class _ProjectEvaluationPageState extends State<ProjectEvaluationPage> {
  late ProjectEvaluationController controller;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = Get.put(ProjectEvaluationController());

    // Request focus for keyboard shortcuts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Évaluation des Projets Flutter'),
          elevation: 0,
          actions: [
            // Statistics
            Obx(
              () => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    'Moyenne: ${controller.averageScore.toStringAsFixed(1)} | '
                    'Complétés: ${controller.completedCount}/${controller.totalCount}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),

            // Sync button (placeholder for Google Sheets integration)
            IconButton(
              icon: Obx(
                () => controller.isSyncing.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Icon(Icons.sync),
              ),
              onPressed: () {
                Get.snackbar(
                  'Info',
                  'Synchronisation Google Sheets à venir',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              tooltip: 'Synchroniser avec Google Sheets',
            ),

            // Settings
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showSettingsDialog,
              tooltip: 'Paramètres',
            ),
          ],
        ),
        body: Row(
          children: [
            // Left sidebar - Student list
            StudentListSidebar(controller: controller),

            // Main content - Evaluation form
            Expanded(
              child: Obx(() {
                if (controller.currentStudent.value == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Sélectionnez un étudiant pour commencer l\'évaluation',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showQuickStartDialog(),
                          icon: const Icon(Icons.rocket_launch),
                          label: const Text('Démarrage Rapide'),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    // Header with student info and summary
                    EvaluationHeader(controller: controller),

                    // Scrollable content with categories
                    Expanded(
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Instructions
                            _buildInstructionsCard(),
                            const SizedBox(height: 24),

                            // Categories
                            ...EvaluationRubricConfig.categories.map(
                              (category) => CategorySection(
                                category: category,
                                controller: controller,
                              ),
                            ),

                            // Bottom spacing
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),

        // Floating action button for quick actions
        floatingActionButton: Obx(() {
          if (controller.currentStudent.value == null)
            return const SizedBox.shrink();

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'scroll_top',
                mini: true,
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                },
                tooltip: 'Haut de page',
                child: const Icon(Icons.arrow_upward),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'save',
                onPressed: () {
                  Get.snackbar(
                    'Info',
                    'Les modifications sont sauvegardées automatiquement',
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                tooltip: 'Sauvegarder',
                child: const Icon(Icons.save),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[700], size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Évaluez chaque critère pendant la présentation. '
                    'Utilisez les flèches ← → pour naviguer entre étudiants. '
                    'Les modifications sont sauvegardées automatiquement.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    // Navigation shortcuts
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      controller.navigateToNextStudent();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      controller.navigateToPreviousStudent();
    }
    // Complete evaluation (Ctrl/Cmd + Enter)
    else if ((event.logicalKey == LogicalKeyboardKey.enter) &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      controller.completeEvaluation();
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paramètres'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Raccourcis clavier:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildShortcutItem('←/→', 'Naviguer entre étudiants'),
              _buildShortcutItem('Cmd/Ctrl + Enter', 'Terminer l\'évaluation'),
              const Divider(height: 32),
              ListTile(
                title: const Text('Importer étudiants'),
                leading: const Icon(Icons.upload_file),
                onTap: () {
                  Navigator.pop(context);
                  _showImportDialog();
                },
              ),
              ListTile(
                title: const Text('Effacer toutes les données'),
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                onTap: () {
                  Navigator.pop(context);
                  _showClearDataDialog();
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutItem(String shortcut, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(description),
        ],
      ),
    );
  }

  void _showQuickStartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Démarrage Rapide'),
        content: const Text(
          'Pour commencer:\n\n'
          '1. Ajoutez des étudiants via le bouton "Ajouter Étudiant"\n'
          '2. Ou importez une liste d\'étudiants (Paramètres > Importer)\n'
          '3. Sélectionnez un étudiant dans la liste\n'
          '4. Évaluez pendant la présentation\n\n'
          'Conseils:\n'
          '• Les modifications sont automatiquement sauvegardées\n'
          '• Utilisez les flèches ← → pour naviguer rapidement\n'
          '• Marquez l\'évaluation comme complète quand terminée',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importer étudiants'),
        content: const Text(
          'Format JSON attendu:\n\n'
          '[\n'
          '  {\n'
          '    "id": "1",\n'
          '    "name": "Nom Prénom",\n'
          '    "group": "G1",\n'
          '    "email": "email@example.com"\n'
          '  }\n'
          ']\n\n'
          'Fonctionnalité à venir...',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text(
          'Êtes-vous sûr de vouloir effacer toutes les données?\n\n'
          'Cette action est irréversible!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.clearAllData();
              Navigator.pop(context);
              Get.snackbar(
                'Succès',
                'Toutes les données ont été effacées',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }
}
