import 'dart:convert';

import 'package:group_leaderboard/constants/constants.dart';
import 'package:group_leaderboard/helpers/helper.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class SyncButton extends StatefulWidget {
  const SyncButton({super.key});

  @override
  State<SyncButton> createState() => _SyncButtonState();
}

class _SyncButtonState extends State<SyncButton> {
  bool _isLoading = false;
  String _statusMessage = '';

  Future<void> _runSync() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      final url =
          'https://fookupyinkivtjrqzozw.supabase.co/functions/v1/syncGrades';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $supabaseAnonKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'key': appsScriptSecretKey}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("Sync result: ${data['message']}");
        _statusMessage = "✅ Sync completed successfully!";
      } else {
        debugPrint("Sync failed: ${response.body}");
        _statusMessage = "❌ Sync failed: ${response.statusCode}";
      }
    } catch (e) {
      _statusMessage = "⚠️ Error: $e";
      debugPrint('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
    Helper.snackBar(message: _statusMessage);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Sync Students Grades',
      onPressed: _isLoading ? null : _runSync,
      icon: _isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync),
    );
  }
}
