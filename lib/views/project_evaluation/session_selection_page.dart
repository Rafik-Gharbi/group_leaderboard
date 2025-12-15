import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:group_leaderboard/helpers/helper.dart';
import '../../services/firestore_evaluation_service.dart';
import 'project_evaluation_controller_firestore.dart';
import 'project_evaluation_page_firestore.dart';

/// Screen for selecting or creating an evaluation session
class SessionSelectionPage extends StatefulWidget {
  static const String routeName = '/evaluation-sessions';

  const SessionSelectionPage({super.key});

  @override
  State<SessionSelectionPage> createState() => _SessionSelectionPageState();
}

class _SessionSelectionPageState extends State<SessionSelectionPage> {
  late final ProjectEvaluationControllerFirestore controller;
  final RxList<EvaluationSession> sessions = <EvaluationSession>[].obs;
  final RxBool isLoading = true.obs;

  @override
  void initState() {
    super.initState();
    // Get or create the controller
    if (Get.isRegistered<ProjectEvaluationControllerFirestore>()) {
      controller = Get.find<ProjectEvaluationControllerFirestore>();
    } else {
      controller = Get.put(ProjectEvaluationControllerFirestore());
    }
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      isLoading.value = true;
      final loadedSessions = await controller.getSessions();
      sessions.value = loadedSessions;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sessions d\'Évaluation'), elevation: 0),
      body: Obx(() {
        if (isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (sessions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assessment, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Aucune session d\'évaluation',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Créez une nouvelle session pour commencer',
                  style: TextStyle(color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _showCreateSessionDialog,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text(
                    'Créer une Session',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Header with stats
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sélectionnez une session',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${sessions.length} session(s) disponible(s)',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showCreateSessionDialog,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Nouvelle Session',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            // Sessions list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return _SessionCard(
                    session: session,
                    onTap: () => _selectSession(session),
                    // onDelete: () => _confirmDeleteSession(session),
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _selectSession(EvaluationSession session) async {
    await controller.selectSession(session);
    Get.to(() => const ProjectEvaluationPageFirestore());
  }

  void _showCreateSessionDialog() {
    final titleController = TextEditingController();

    // Generate default title
    final now = DateTime.now();
    final defaultTitle = 'DS Flutter - ${now.day}/${now.month}/${now.year}';
    titleController.text = defaultTitle;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Titre de la session',
                border: OutlineInputBorder(),
                hintText: 'Ex: DS Flutter - Décembre 2025',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Les étudiants seront importés automatiquement depuis Firestore',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                Navigator.pop(context);
                await controller.createSession(titleController.text);
                await _loadSessions();
              }
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  // void _confirmDeleteSession(EvaluationSession session) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Supprimer la session'),
  //       content: Text(
  //         'Voulez-vous vraiment supprimer "${session.title}"?\n\n'
  //         'Toutes les évaluations de cette session seront supprimées.',
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: const Text('Annuler'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () async {
  //             Navigator.pop(context);
  //             // TODO: Implement delete
  //             Helper.snackBar(
  //               title: 'Info',
  //               message: 'Suppression à implémenter',
  //             );
  //           },
  //           style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
  //           child: const Text('Supprimer'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}

class _SessionCard extends StatelessWidget {
  final EvaluationSession session;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _SessionCard({
    required this.session,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assessment,
                  color: Colors.blue,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (session.createdAt != null)
                      Text(
                        'Créée le ${_formatDate(session.createdAt!)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
