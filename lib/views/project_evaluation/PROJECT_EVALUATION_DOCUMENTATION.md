# Project Evaluation Module - Documentation

## 📚 Overview

The Project Evaluation Module is a comprehensive, modular system designed to help evaluate student Flutter projects during presentations. It provides a structured way to score projects based on predefined criteria, track evaluations across multiple students, and optionally sync data with Google Sheets.

## 🏗️ Architecture

The module follows a clean, modular architecture with clear separation of concerns:

```
lib/
├── models/
│   └── project_evaluation.dart           # Data models
├── constants/
│   └── evaluation_rubric.dart            # Rubric configuration
├── services/
│   └── google_sheets_service.dart        # Google Sheets integration
└── views/
    └── project_evaluation/
        ├── project_evaluation_page.dart           # Main page
        ├── project_evaluation_controller.dart     # Business logic
        └── components/                            # Reusable UI components
            ├── criterion_score_card.dart          # Score input widget
            ├── category_section.dart              # Category display
            ├── student_list_sidebar.dart          # Student navigation
            └── evaluation_header.dart             # Summary header
```

## 🎯 Key Features

### 1. **Modular Design**

- Each component is isolated and reusable
- Easy to maintain and extend
- Clear separation of data, logic, and UI

### 2. **Real-time Scoring**

- Instant score calculation
- Live progress indicators
- Automatic save to local storage

### 3. **Flexible Navigation**

- Sidebar for quick student selection
- Keyboard shortcuts (← → for navigation)
- Group filtering

### 4. **Comprehensive Rubric**

- 5 main categories
- 15+ evaluation criteria
- Configurable weights and descriptions
- Automatic penalty calculation

### 5. **Data Persistence**

- Auto-save to local storage (SharedPreferences)
- Export to JSON
- Google Sheets integration (optional)

### 6. **Student Management**

- Add students manually
- Import from JSON
- Track completion status
- Group organization

## 📋 Evaluation Criteria

### Categories (100 base points + 25 bonus):

1. **Mise en œuvre fonctionnelle (30 pts)**

   - Complétude des Fonctionnalités (15)
   - Navigation & Flow App (7)
   - Fiabilité & Stabilité (8)

2. **Design UI / UX (20 pts)**

   - Design Visuel (10)
   - Expérience Utilisateur (10)

3. **Qualité technique (20 pts)**

   - Organisation du Code (8)
   - Lisibilité du Code (7)
   - Cohérence avec le Niveau (5)

4. **Démo, Questions & Live coding (30 pts)**

   - Qualité de la Démo (10)
   - Questions Techniques (10)
   - Live Coding (10)

5. **Points Bonus (25 pts)**
   - Faible Dépendance à l'IA (10)
   - Créativité & Fonctionnalités Extras (8)
   - Effort & Professionnalisme (5)
   - Spécification à Temps (2)

## 🚀 Usage Guide

### Accessing the Module

Navigate to the evaluation page:

```dart
Get.toNamed(ProjectEvaluationPage.routeName);
// or
Navigator.pushNamed(context, '/project-evaluation');
```

### Adding Students

**Option 1: Manual Entry**

1. Click "Ajouter Étudiant" button
2. Fill in student information
3. Click "Ajouter"

**Option 2: Import JSON**

```json
[
  {
    "id": "1",
    "name": "John Doe",
    "group": "G1",
    "email": "john@example.com",
    "isInPair": false
  }
]
```

### Evaluating a Student

1. **Select Student**: Click on a student in the sidebar
2. **Enter Scores**: Type scores for each criterion
3. **Add Notes**: Add comments for each criterion (optional)
4. **Set Flags**: Mark important flags (AI declaration, etc.)
5. **Complete**: Click "Terminer l'évaluation" when done

### Keyboard Shortcuts

- `→` : Next student
- `←` : Previous student
- `Cmd/Ctrl + Enter` : Complete evaluation

## 🔧 Customization

### Modifying the Rubric

Edit `lib/constants/evaluation_rubric.dart`:

```dart
const EvaluationCriterion(
  id: 'your_criterion_id',
  name: 'Your Criterion Name',
  description: 'Description of what you evaluate',
  maxScore: 10,
  category: 'category_id',
  order: 1,
)
```

### Adding New Categories

```dart
const EvaluationCategory(
  id: 'new_category',
  name: 'New Category',
  description: 'Category description',
  order: 6,
  criteria: [
    // Add criteria here
  ],
)
```

### Customizing UI Colors

Edit `category_section.dart` to change category colors:

```dart
Color _getCategoryColor() {
  switch (category.id) {
    case 'your_category':
      return Colors.yourColor;
    // ...
  }
}
```

## 🔗 Google Sheets Integration

### Setup Steps

1. **Create a Google Sheet** with columns matching the rubric

2. **Create Google Apps Script**:

   - Tools → Script editor
   - Copy the provided code from `google_sheets_service.dart`
   - Deploy as Web App

3. **Configure URL**:

   ```dart
   // In google_sheets_service.dart
   static const String webAppUrl = 'YOUR_DEPLOYED_URL';
   ```

4. **Update Controller**:

   ```dart
   final googleSheetsService = GoogleSheetsService();

   // Export all evaluations
   await googleSheetsService.exportToGoogleSheets(
     evaluations.values.toList()
   );

   // Sync single evaluation
   await googleSheetsService.syncEvaluation(evaluation);
   ```

### Expected Sheet Format

| Group | Student Name | Criterion 1 | Criterion 2 | ... | Total Score |
| ----- | ------------ | ----------- | ----------- | --- | ----------- |
| G1    | John Doe     | 15          | 7           | ... | 95          |

## 💾 Data Storage

### Local Storage Structure

```json
{
  "evaluation_students": [
    {
      "id": "1",
      "name": "Student Name",
      "group": "G1",
      "email": "email@example.com"
    }
  ],
  "evaluations": {
    "1": {
      "studentId": "1",
      "studentName": "Student Name",
      "scores": {
        "criterion_id": 15.0
      },
      "notes": {
        "criterion_id": "Good work"
      },
      "totalScore": 95.0,
      "isCompleted": true
    }
  }
}
```

### Exporting Data

```dart
// Export to JSON
final data = controller.exportEvaluations();
final jsonString = jsonEncode(data);

// Save to file or clipboard
```

## 🧪 Testing

### Manual Testing Checklist

- [ ] Add a student
- [ ] Enter scores for all criteria
- [ ] Add notes
- [ ] Set flags
- [ ] Navigate between students
- [ ] Complete an evaluation
- [ ] Filter by group
- [ ] Export data
- [ ] Verify local storage persistence

## 🔍 Troubleshooting

### Scores Not Saving

- Check console for errors
- Verify SharedPreferences initialization
- Clear app data and restart

### Google Sheets Sync Failing

- Verify Web App URL is correct
- Check Apps Script deployment settings
- Ensure "Anyone" has access
- Check network connectivity

### UI Not Updating

- Ensure using GetX reactive variables (.obs)
- Check controller is properly initialized
- Verify update() calls in controller

## 📱 Responsive Design

The module is designed for desktop use but adapts to:

- Large screens (1920x1080+)
- Medium screens (1366x768+)
- Tablets (768x1024+)

For optimal experience during presentations, use on a laptop or desktop.

## 🎨 Customization Examples

### Change Theme Colors

```dart
// In category_section.dart
Color _getCategoryColor() {
  return Theme.of(context).primaryColor; // Use app theme
}
```

### Add Custom Validation

```dart
// In project_evaluation_controller.dart
Future<void> updateScore(String criterionId, double score) async {
  // Add custom validation
  if (score < minAllowedScore) {
    Get.snackbar('Error', 'Score too low!');
    return;
  }

  // ... rest of the code
}
```

### Add Export Formats

```dart
// In project_evaluation_controller.dart
String exportToCSV() {
  final csv = StringBuffer();
  csv.writeln('Student,Group,Total Score');

  for (final eval in evaluations.values) {
    csv.writeln('${eval.studentName},${eval.groupName},${eval.totalScore}');
  }

  return csv.toString();
}
```

## 🔐 Security Considerations

- Data is stored locally on the device
- Google Sheets access should be restricted
- Consider encrypting sensitive data
- Implement user authentication for multi-user scenarios

## 🚀 Future Enhancements

Potential improvements:

- [ ] Cloud storage (Firebase/Supabase)
- [ ] Multi-user collaboration
- [ ] Real-time sync between devices
- [ ] PDF report generation
- [ ] Analytics dashboard
- [ ] Voice-to-text for notes
- [ ] Timer for presentations
- [ ] Comparison views

## 📞 Support

For issues or questions:

1. Check this documentation
2. Review code comments
3. Check console logs for errors
4. Verify all dependencies are installed

## 📄 License

This module is part of the group_leaderboard project. Use and modify as needed for your evaluation purposes.

---

**Version**: 1.0.0  
**Last Updated**: December 2025  
**Maintainer**: Development Team
