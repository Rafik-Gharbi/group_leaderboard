import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../constants/evaluation_rubric.dart';
import '../../models/project_evaluation.dart';

/// Service for syncing evaluations with Google Sheets
///
/// This service provides methods to:
/// - Export evaluations to Google Sheets
/// - Import student list from Google Sheets
/// - Sync scores in real-time
///
/// Setup instructions:
/// 1. Create a Google Apps Script Web App with your sheet
/// 2. Deploy as web app with "Anyone" access
/// 3. Set the WEB_APP_URL below to your deployed URL
///
/// Example Google Apps Script code is provided in the documentation.
class GoogleSheetsService {
  // TODO: Replace with your Google Apps Script Web App URL
  static const String webAppUrl = 'YOUR_GOOGLE_APPS_SCRIPT_URL_HERE';

  /// Export all evaluations to Google Sheets
  Future<bool> exportToGoogleSheets(List<ProjectEvaluation> evaluations) async {
    try {
      final data = _prepareExportData(evaluations);

      final response = await http.post(
        Uri.parse('$webAppUrl?action=export'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        debugPrint('Successfully exported to Google Sheets');
        return true;
      } else {
        debugPrint('Failed to export: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error exporting to Google Sheets: $e');
      return false;
    }
  }

  /// Import students from Google Sheets
  Future<List<EvaluationStudent>?> importStudentsFromSheets() async {
    try {
      final response = await http.get(
        Uri.parse('$webAppUrl?action=getStudents'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => EvaluationStudent.fromJson(json)).toList();
      } else {
        debugPrint('Failed to import students: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error importing students from Google Sheets: $e');
      return null;
    }
  }

  /// Sync a single evaluation to Google Sheets
  Future<bool> syncEvaluation(ProjectEvaluation evaluation) async {
    try {
      final data = _prepareEvaluationData(evaluation);

      final response = await http.post(
        Uri.parse('$webAppUrl?action=updateStudent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error syncing evaluation: $e');
      return false;
    }
  }

  /// Prepare export data in the format expected by Google Sheets
  Map<String, dynamic> _prepareExportData(List<ProjectEvaluation> evaluations) {
    final rows = evaluations.map((eval) {
      final Map<String, dynamic> row = {
        'Group': eval.groupName,
        'Student Name': eval.studentName,
      };

      // Add all criterion scores
      for (final criterion in EvaluationRubricConfig.allCriteria) {
        row[criterion.name] = eval.scores[criterion.id] ?? 0;
      }

      // Add flags
      row['Comprend parfaitement'] = eval.understandsPerfectly ? 'Oui' : 'Non';
      row['Téléchargé depuis Internet'] = eval.downloadedFromInternet
          ? 'Oui'
          : 'Non';
      row['Document de Spécification Valide'] = eval.specificationValid
          ? 'Oui'
          : 'Non';
      row['Déclaration de l\'IA'] = eval.aiDeclaration ? 'Oui' : 'Non';
      row['Total Score'] = eval.totalScore;

      return row;
    }).toList();

    return {'rows': rows, 'timestamp': DateTime.now().toIso8601String()};
  }

  /// Prepare single evaluation data
  Map<String, dynamic> _prepareEvaluationData(ProjectEvaluation evaluation) {
    final Map<String, dynamic> data = {
      'studentId': evaluation.studentId,
      'studentName': evaluation.studentName,
      'groupName': evaluation.groupName,
      'scores': evaluation.scores,
      'totalScore': evaluation.totalScore,
      'understandsPerfectly': evaluation.understandsPerfectly,
      'downloadedFromInternet': evaluation.downloadedFromInternet,
      'specificationValid': evaluation.specificationValid,
      'aiDeclaration': evaluation.aiDeclaration,
      'isCompleted': evaluation.isCompleted,
      'evaluationDate': evaluation.lastSavedAt?.toIso8601String(),
    };

    return data;
  }
}

/// Example Google Apps Script code to handle the requests
/// 
/// Copy this code to your Google Apps Script project:
/// 
/// ```javascript
/// function doGet(e) {
///   const action = e.parameter.action;
///   
///   if (action === 'getStudents') {
///     return getStudents();
///   }
///   
///   return ContentService.createTextOutput(JSON.stringify({
///     error: 'Invalid action'
///   })).setMimeType(ContentService.MimeType.JSON);
/// }
/// 
/// function doPost(e) {
///   const action = e.parameter.action;
///   const data = JSON.parse(e.postData.contents);
///   
///   if (action === 'export') {
///     return exportEvaluations(data);
///   } else if (action === 'updateStudent') {
///     return updateStudentEvaluation(data);
///   }
///   
///   return ContentService.createTextOutput(JSON.stringify({
///     error: 'Invalid action'
///   })).setMimeType(ContentService.MimeType.JSON);
/// }
/// 
/// function getStudents() {
///   const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Students');
///   const data = sheet.getDataRange().getValues();
///   const headers = data[0];
///   const students = [];
///   
///   for (let i = 1; i < data.length; i++) {
///     const row = data[i];
///     students.push({
///       id: row[0],
///       name: row[1],
///       group: row[2],
///       email: row[3]
///     });
///   }
///   
///   return ContentService.createTextOutput(JSON.stringify(students))
///     .setMimeType(ContentService.MimeType.JSON);
/// }
/// 
/// function exportEvaluations(data) {
///   const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Evaluations');
///   const rows = data.rows;
///   
///   // Clear existing data (except headers)
///   sheet.getRange(2, 1, sheet.getLastRow() - 1, sheet.getLastColumn()).clear();
///   
///   // Add new data
///   rows.forEach((row, index) => {
///     const rowData = Object.values(row);
///     sheet.getRange(index + 2, 1, 1, rowData.length).setValues([rowData]);
///   });
///   
///   return ContentService.createTextOutput(JSON.stringify({
///     success: true,
///     rowsUpdated: rows.length
///   })).setMimeType(ContentService.MimeType.JSON);
/// }
/// 
/// function updateStudentEvaluation(data) {
///   const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('Evaluations');
///   const studentId = data.studentId;
///   
///   // Find or create row for this student
///   const dataRange = sheet.getDataRange().getValues();
///   let rowIndex = -1;
///   
///   for (let i = 1; i < dataRange.length; i++) {
///     if (dataRange[i][0] === studentId) {
///       rowIndex = i + 1;
///       break;
///     }
///   }
///   
///   if (rowIndex === -1) {
///     rowIndex = sheet.getLastRow() + 1;
///   }
///   
///   // Update row
///   sheet.getRange(rowIndex, 1).setValue(data.studentId);
///   sheet.getRange(rowIndex, 2).setValue(data.studentName);
///   sheet.getRange(rowIndex, 3).setValue(data.groupName);
///   sheet.getRange(rowIndex, 4).setValue(data.totalScore);
///   
///   return ContentService.createTextOutput(JSON.stringify({
///     success: true
///   })).setMimeType(ContentService.MimeType.JSON);
/// }
/// ```
