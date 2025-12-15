import '../models/project_evaluation.dart';

// Central configuration for evaluation rubric
class EvaluationRubricConfig {
  static const List<EvaluationCategory> categories = [
    EvaluationCategory(
      id: 'functional_implementation',
      name: 'Mise en œuvre fonctionnelle',
      description: 'Évaluation de la complétude et la qualité fonctionnelle',
      order: 1,
      criteria: [
        EvaluationCriterion(
          id: 'feature_completeness',
          name: 'Complétude des Fonctionnalités',
          description:
              'Toutes les fonctionnalités du document validé sont implémentées, fonctionnalité intelligente fonctionne correctement',
          maxScore: 15,
          category: 'functional_implementation',
          order: 1,
        ),
        EvaluationCriterion(
          id: 'navigation_flow',
          name: 'Navigation & Flow App',
          description:
              'Navigation fluide et cohérente, structure logique, hiérarchie UX claire',
          maxScore: 7,
          category: 'functional_implementation',
          order: 2,
        ),
        EvaluationCriterion(
          id: 'reliability_stability',
          name: 'Fiabilité & Stabilité',
          description:
              'Aucun crash durant la démo, formulaires fonctionnels, tests réalisés',
          maxScore: 8,
          category: 'functional_implementation',
          order: 3,
        ),
      ],
    ),
    EvaluationCategory(
      id: 'design_ui_ux',
      name: 'Design UI / UX',
      description:
          'Évaluation du design visuel et de l\'expérience utilisateur',
      order: 2,
      criteria: [
        EvaluationCriterion(
          id: 'visual_design',
          name: 'Design Visuel',
          description:
              'Design propre et agréable, palette cohérente, bon espacement, typographie lisible',
          maxScore: 10,
          category: 'design_ui_ux',
          order: 1,
        ),
        EvaluationCriterion(
          id: 'user_experience',
          name: 'Expérience Utilisateur',
          description:
              'Parcours intuitif, actions faciles à trouver, responsive multi-tailles',
          maxScore: 10,
          category: 'design_ui_ux',
          order: 2,
        ),
      ],
    ),
    EvaluationCategory(
      id: 'technical_quality',
      name: 'Qualité technique et meilleures pratiques',
      description: 'Évaluation de la qualité du code et des pratiques',
      order: 3,
      criteria: [
        EvaluationCriterion(
          id: 'code_organization',
          name: 'Organisation du Code',
          description:
              'Structure claire, fichiers bien nommés, pas de répétition, widgets réutilisables',
          maxScore: 8,
          category: 'technical_quality',
          order: 1,
        ),
        EvaluationCriterion(
          id: 'code_readability',
          name: 'Lisibilité du Code',
          description:
              'Logique claire, commentaires utiles, bon nommage, pas de complexité inutile',
          maxScore: 7,
          category: 'technical_quality',
          order: 2,
        ),
        EvaluationCriterion(
          id: 'course_consistency',
          name: 'Cohérence avec le Niveau & le Cours',
          description:
              'Code réaliste pour un étudiant, pas de patterns IA avancés',
          maxScore: 5,
          category: 'technical_quality',
          order: 3,
        ),
      ],
    ),
    EvaluationCategory(
      id: 'presentation_questions_live',
      name: 'Démo, Questions & Live coding',
      description:
          'Évaluation de la présentation orale et des compétences pratiques',
      order: 4,
      criteria: [
        EvaluationCriterion(
          id: 'demo_quality',
          name: 'Qualité de la Démo',
          description:
              'Claire et structurée (2-3 min max), montre les principaux cas d\'usage',
          maxScore: 10,
          category: 'presentation_questions_live',
          order: 1,
        ),
        EvaluationCriterion(
          id: 'technical_questions',
          name: 'Questions Techniques',
          description:
              'Explique son code, sa fonctionnalité intelligente, ses choix d\'implémentation',
          maxScore: 10,
          category: 'presentation_questions_live',
          order: 2,
        ),
        EvaluationCriterion(
          id: 'live_coding',
          name: 'Live Coding',
          description:
              'Capacité de raisonnement, maîtrise des fondamentaux Flutter',
          maxScore: 10,
          category: 'presentation_questions_live',
          order: 3,
        ),
      ],
    ),
    EvaluationCategory(
      id: 'bonus_points',
      name: 'Points Bonus',
      description: 'Points additionnels pour excellence et créativité',
      order: 5,
      criteria: [
        EvaluationCriterion(
          id: 'low_ai_dependency',
          name: 'Faible Dépendance à l\'IA',
          description:
              'Grande partie codée manuellement avec compréhension profonde',
          maxScore: 10,
          category: 'bonus_points',
          order: 1,
        ),
        EvaluationCriterion(
          id: 'creativity_extras',
          name: 'Créativité & Fonctionnalités Extras',
          description:
              'Fonctionnalités originales, animations, design exceptionnel',
          maxScore: 8,
          category: 'bonus_points',
          order: 2,
        ),
        EvaluationCriterion(
          id: 'effort_professionalism',
          name: 'Effort, Finition & Professionnalisme',
          description:
              'Attention aux détails, qualité de finition, professionnalisme global',
          maxScore: 5,
          category: 'bonus_points',
          order: 3,
        ),
        EvaluationCriterion(
          id: 'specification_on_time',
          name: 'Spécification Rendue à Temps',
          description: 'Document de spécification soumis avant la date limite',
          maxScore: 2,
          category: 'bonus_points',
          order: 4,
        ),
      ],
    ),
  ];

  // Get all criteria as a flat list
  static List<EvaluationCriterion> get allCriteria {
    return categories.expand((category) => category.criteria).toList();
  }

  // Get criterion by id
  static EvaluationCriterion? getCriterionById(String id) {
    return allCriteria.firstWhere(
      (criterion) => criterion.id == id,
      orElse: () => throw Exception('Criterion not found: $id'),
    );
  }

  // Get category by id
  static EvaluationCategory? getCategoryById(String id) {
    return categories.firstWhere(
      (category) => category.id == id,
      orElse: () => throw Exception('Category not found: $id'),
    );
  }

  // Calculate base score (without bonus)
  static double get maxBaseScore {
    return categories
        .where((cat) => cat.id != 'bonus_points')
        .fold(0.0, (sum, cat) => sum + cat.maxScore);
  }

  // Calculate total score (with bonus)
  static double get maxTotalScore {
    return categories.fold(0.0, (sum, cat) => sum + cat.maxScore);
  }

  // Get bonus category
  static EvaluationCategory get bonusCategory {
    return categories.firstWhere((cat) => cat.id == 'bonus_points');
  }
}
