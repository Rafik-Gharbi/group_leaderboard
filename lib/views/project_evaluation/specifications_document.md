# Student Evaluation Module – Full Specification

## 1. Purpose & Scope

This module is a **desktop-first Flutter application module** designed to assist a teacher in **evaluating students efficiently during live sessions** (e.g. project defenses).

The module focuses on:

* Fast navigation between students
* Minimal cognitive load during evaluation
* Safe, automatic persistence of evaluation data
* Clear alignment with an existing **DS evaluation rubric**

It is a **single-evaluator tool** (not collaborative), optimized for **real-time usage in class**, not post-processing.

---

## 2. Target Users & Usage Context

### Primary User

* Teacher / evaluator
* Uses laptop (macOS / Windows)
* Evaluates students group by group
* Often under time pressure

### Usage Context

* Classroom or lab
* Live oral presentations
* Frequent context switching between students
* Partial evaluations (some criteria filled later)

---

## 3. Non-Goals

* No student access
* No real-time collaboration
* No grading analytics or reports (out of scope)
* No strict offline-first requirement (Firestore is sufficient)

---

## 4. Technology Stack

* **Frontend**: Flutter (desktop-first)
* **State Management**: Local widget state / controller (lightweight)
* **Backend**: Firebase Firestore
* **Authentication**: Assumed already handled
* **Database Type**: Firestore (NOT Realtime Database)

Firestore is sufficient because:

* Single evaluator
* Low write frequency
* No concurrent editing

---

## 5. Existing Firebase Context (Read-Only Source)

### Collection: `students`

This collection already exists and is used as the **source of truth for student identity**.

Each document represents one student.

#### Fields

* `uid: String`
* `name: String`
* `email: String`
* `group: String` (e.g. `G1`, `G2`, `G3`)
* `linkedGradesId: String` (external identifier)
* `photo: String` (URL)
* `createdAt: Timestamp`

⚠️ This collection is **not modified** by this module.

---

## 6. New Firestore Data Model

### 6.1 Collection: `evaluationSessions`

Represents a logical evaluation context (e.g. DS evaluation for a specific class).

#### Document ID

* Auto-generated or semantic (e.g. `DS_2025_G3`)

#### Fields

* `title: String`
* `createdAt: Timestamp`
* `updatedAt: Timestamp`

---

### 6.2 Subcollection: `groups`

Each document represents a **group being evaluated**.

#### Document ID

* Group name (e.g. `G3`)

#### Fields

* `name: String`
* `studentOrder: List<String>` (ordered list of student UIDs)
* `updatedAt: Timestamp`

This list is managed via **drag & drop** in the UI and defines navigation order.

---

### 6.3 Subcollection: `evaluations`

One document per student **per evaluation session**.

#### Document ID

* `studentUid`

#### Fields

* `studentUid: String`
* `group: String`
* `status: String` (`not_started | in_progress | completed`)
* `scores: Map<String, int?>`
* `flags: Map<String, bool?>`
* `comments: Map<String, String?>`
* `lastSavedAt: Timestamp`

Partial documents are valid and expected.

---

## 7. Dart Data Models

### 7.1 Student (existing)

```dart
class Student {
  final String uid;
  final String name;
  final String email;
  final String group;
  final String? photo;

  Student({
    required this.uid,
    required this.name,
    required this.email,
    required this.group,
    this.photo,
  });
}
```

---

### 7.2 StudentEvaluation

```dart
class StudentEvaluation {
  final String studentUid;
  String status;
  Map<String, int?> scores;
  Map<String, bool?> flags;
  Map<String, String?> comments;

  StudentEvaluation({
    required this.studentUid,
    this.status = 'not_started',
    Map<String, int?>? scores,
    Map<String, bool?>? flags,
    Map<String, String?>? comments,
  })  : scores = scores ?? {},
        flags = flags ?? {},
        comments = comments ?? {};
}
```

---

## 8. UX Flow Overview

### 8.1 Screen 1 – Group Selection

* Displays list of available groups
* Selecting a group loads its student list using saved order

---

### 8.2 Screen 2 – Student List (Ordered)

* Displays students of selected group
* Drag & drop to reorder students
* Order persisted in Firestore (`studentOrder`)
* Selecting a student opens evaluation screen

---

### 8.3 Screen 3 – Evaluation Screen

Focused on **one student at a time**.

Features:

* Student identity header (name + photo)
* Evaluation criteria with sliders / checkboxes / text fields
* Auto-save with debounce
* Save status indicator (`Saving…` / `Saved`)
* Navigation:

  * Swipe left/right OR
  * Back to student list

---

## 9. Evaluation Screen State Design

### Local State Object

```dart
class EvaluationScreenState {
  final Student student;
  StudentEvaluation evaluation;
  bool isSaving;
  bool hasUnsavedChanges;
  DateTime? lastSavedAt;
}
```

State principles:

* Local copy first
* Firestore sync is background-only
* UI never blocks user input

---

## 10. Auto-Save & Debouncer

### Design Goals

* No save button
* No accidental data loss
* No excessive writes

### Debouncer

* Timer-based
* Default delay: 500ms
* Triggered on any field change

```dart
class SaveDebouncer {
  final Duration delay;
  Timer? _timer;

  SaveDebouncer({this.delay = const Duration(milliseconds: 500)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }
}
```

---

### Save Behavior

On any change:

1. Update local model
2. Mark `hasUnsavedChanges = true`
3. Debounced Firestore patch update
4. Update save indicators

Partial updates use `update()` with dotted paths.

---

## 11. Evaluation Criteria & Rubric Integration

### Centralized Criterion Definition

```dart
class CriterionInfo {
  final String key;
  final String title;
  final String description;
  final int maxScore;
}
```

All rubric text is stored **once**, not duplicated in UI.

---

### UI Rules for Descriptions

* Font size: small
* Color: grey
* Always visible
* Never collapses main controls

Purpose:

* Assist evaluator memory
* Avoid breaking focus

---

## 12. Firestore Service Layer Responsibilities

* Fetch students by group
* Fetch / create evaluation document
* Patch evaluation fields
* Persist student ordering

All Firestore logic is isolated from UI.

---

## 13. Navigation & Safety

* Leaving screen is allowed anytime
* Save indicator reassures persistence
* No confirmation dialogs
* No forced completeness

---

## 14. Error Handling Strategy

* Silent retry on transient failures
* Optional snack bar on permanent failure
* Local state remains intact

---

## 15. Quality Attributes

* Fast
* Predictable
* Low cognitive load
* Teacher-centric
* Robust under pressure

---

## 16. Future Extensions (Out of Scope)

* PDF export
* Final grade calculation
* Statistics dashboard
* Multi-evaluator support

---

## 17. Summary

This module is intentionally:

* Simple in architecture
* Thoughtful in UX
* Safe in data handling

It mirrors how **a human evaluator actually works**, not how databases want data.
