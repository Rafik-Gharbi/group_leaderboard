# Project Evaluation Module - Quick Start Guide

## 🚀 Getting Started in 5 Minutes

### Step 1: Navigate to the Module

From anywhere in your app, navigate to the evaluation page:

```dart
// Add this button to your main menu or navigation
ElevatedButton(
  onPressed: () => Get.toNamed(ProjectEvaluationPage.routeName),
  child: Text('Project Evaluation'),
)
```

Or access directly via URL: `/project-evaluation`

### Step 2: Add Your Students

#### Option A: Manual Entry (Quick)

1. Click **"Ajouter Étudiant"** in the sidebar
2. Enter:
   - Full name
   - Email (optional)
   - Group (G1-G6)
3. Click **"Ajouter"**
4. Repeat for all students

#### Option B: Import from JSON (Recommended for many students)

Prepare a JSON file:

```json
[
  {
    "id": "1",
    "name": "Alice Martin",
    "group": "G1",
    "email": "alice@example.com"
  },
  {
    "id": "2",
    "name": "Bob Dubois",
    "group": "G1",
    "email": "bob@example.com"
  },
  {
    "id": "3",
    "name": "Claire Petit",
    "group": "G2",
    "email": "claire@example.com"
  }
]
```

Click **Settings** (⚙️) → **Import Students** → Paste JSON

### Step 3: Start Evaluating

1. **Select a student** from the sidebar (click on their name)
2. **Enter scores** as the student presents:
   - Type the score for each criterion
   - Add notes if needed (optional)
   - Press Enter to move to next field
3. **Set flags** at the top:
   - ✅ Comprend parfaitement
   - 🚫 Téléchargé depuis Internet (applies -50% penalty)
   - 📄 Spécification Valide
   - 🤖 Déclaration de l'IA
4. **Complete** when done: Click "Terminer l'évaluation"

### Step 4: Navigate Quickly

Use keyboard shortcuts:

- **→** (Right Arrow): Next student
- **←** (Left Arrow): Previous student
- **Cmd/Ctrl + Enter**: Complete evaluation

### Step 5: Review & Export

- **View statistics** in the app bar (average score, completion count)
- **Filter by group** using the dropdown in sidebar
- **Export data**: Click Settings → Export (copy JSON to clipboard)

---

## 📊 Understanding the Scoring

### Base Score (100 points)

- **Functional Implementation**: 30 pts
- **Design UI/UX**: 20 pts
- **Technical Quality**: 20 pts
- **Demo & Questions**: 30 pts

### Bonus Points (25 points)

- Low AI dependency: 10 pts
- Creativity: 8 pts
- Professionalism: 5 pts
- On-time submission: 2 pts

### Total Possible: 125 points

### Penalties

- Downloaded from Internet: **-50% of final score** ⚠️

---

## 💡 Tips for Efficient Evaluation

### During Presentation (7 minutes)

1. **Minute 0-3: Demo**

   - Quickly note scores for:
     - Feature completeness
     - Navigation flow
     - Visual design
     - User experience

2. **Minute 3-5: Questions**

   - Score:
     - Code organization (as they explain)
     - Code readability
     - Technical understanding
     - Smart feature implementation

3. **Minute 5-7: Live Coding**

   - Score:
     - Live coding ability
     - Problem-solving
     - Flutter fundamentals

4. **After Presentation**
   - Set flags (AI declaration, etc.)
   - Add any final notes
   - Click "Complete"

### Keyboard-First Workflow

1. Select student (mouse click or ↓/↑)
2. Tab through score fields
3. Type scores quickly
4. Press Enter to move to next
5. Use ← → to navigate students
6. Cmd/Ctrl+Enter to complete

### Focus on Key Criteria

Priority scoring (most important first):

1. ⭐ Feature completeness (15 pts)
2. ⭐ Demo quality (10 pts)
3. ⭐ Technical questions (10 pts)
4. ⭐ Live coding (10 pts)
5. Visual design (10 pts)
6. User experience (10 pts)
7. Everything else

---

## 🔄 Google Sheets Integration (Optional)

### Quick Setup

1. **Create a Google Sheet** with these columns:

   ```
   Group | Student Name | Feature Completeness | Navigation Flow | ... | Total Score
   ```

2. **Create Apps Script** (Tools → Script Editor):

   - Copy code from `google_sheets_service.dart`
   - Deploy as Web App
   - Set "Execute as: Me"
   - Set "Who has access: Anyone"

3. **Configure URL** in your code:

   ```dart
   // lib/services/google_sheets_service.dart
   static const String webAppUrl = 'YOUR_WEB_APP_URL_HERE';
   ```

4. **Sync**: Click the sync button (🔄) in app bar

---

## 🎯 Common Workflows

### Scenario 1: Single Student Evaluation

```
1. Click student → 2. Enter scores → 3. Complete → Done!
```

### Scenario 2: Batch Evaluation (20+ students)

```
1. Import students via JSON
2. Filter by group (G1)
3. Evaluate all G1 students
4. Switch to G2, repeat
5. Export results at end
```

### Scenario 3: Re-evaluation / Corrections

```
1. Select student from sidebar
2. Modify scores/notes
3. Changes auto-save
4. No need to "complete" again
```

---

## ⚠️ Important Notes

### Data Persistence

- ✅ All changes **auto-save** to local storage
- ✅ Data persists across app restarts
- ⚠️ Clearing browser data will delete evaluations
- 💡 Export regularly as backup!

### Scoring Guidelines

- Enter exact scores (e.g., 8.5, 12.75)
- Max score for each criterion is shown
- Progress bar shows percentage
- Total is calculated automatically

### Penalties

- "Téléchargé depuis Internet" flag → **Final score × 0.5**
- Apply only if certain!
- Cannot be undone after completion

---

## 🐛 Quick Troubleshooting

| Problem                 | Solution                                           |
| ----------------------- | -------------------------------------------------- |
| Student list empty      | Click "Ajouter Étudiant" or import JSON            |
| Scores not saving       | Check console for errors, verify SharedPreferences |
| Can't navigate students | Use mouse or arrow keys                            |
| Export not working      | Copy JSON manually from dialog                     |
| Google Sheets fails     | Verify URL and deployment settings                 |

---

## 📱 Best Practices

### Before Evaluation Session

- [ ] Import all students
- [ ] Test with 1-2 sample evaluations
- [ ] Verify data saves correctly
- [ ] Close unnecessary apps
- [ ] Have evaluation rubric ready

### During Evaluation

- [ ] Focus on key criteria first
- [ ] Take brief notes only
- [ ] Use keyboard shortcuts
- [ ] Complete each evaluation immediately
- [ ] Don't overthink - trust your judgment

### After Evaluation

- [ ] Review all evaluations
- [ ] Check for outliers
- [ ] Export final results
- [ ] Sync to Google Sheets (if using)
- [ ] Backup data

---

## 🎓 Example Evaluation (90 seconds)

**Student**: Alice Martin (G1)

```
[0:00-0:30] During demo:
  - Feature completeness: 14/15 ✅
  - Navigation: 6/7 ✅
  - Visual design: 9/10 ✅
  - UX: 9/10 ✅

[0:30-1:00] During questions:
  - Code organization: 7/8 ✅
  - Readability: 6/7 ✅
  - Technical questions: 9/10 ✅

[1:00-1:30] During live coding:
  - Live coding: 8/10 ✅
  - Reliability: 7/8 ✅

[1:30] Final:
  - Flags: Comprend parfaitement ✅
  - Bonus: Low AI (8/10), Creativity (6/8)
  - Click "Terminer l'évaluation"
```

**Total Time**: 90 seconds  
**Total Score**: 104/125 (83%)

---

## 🆘 Need Help?

1. Check **PROJECT_EVALUATION_DOCUMENTATION.md** for details
2. Review code comments in source files
3. Check browser console for errors
4. Verify all dependencies installed

---

**Ready to evaluate? Click a student and start scoring!** 🚀
