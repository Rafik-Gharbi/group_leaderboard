import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart' show debugPrint;
import 'package:get/get.dart';
import 'package:group_leaderboard/constants/constants.dart';
import 'package:group_leaderboard/views/login/login_page.dart';
import 'package:http/http.dart' as http;

import '../helpers/helper.dart';
import '../models/user.dart';
import '../views/home/leaderboard_page.dart';

class MainController extends GetxController {
  static MainController get find => Get.find<MainController>();
  final List<String> groups = ['All', 'G1', 'G2', 'G3', 'G4', 'G5', 'G6'];
  User? currentUser;
  RxBool isLoading = true.obs;

  MainController() {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      fetchProfile().then((fullUser) {
        isLoading.value = false;
        if (fullUser?.isNotCompleted ?? true) {
          Get.offAllNamed(LoginPage.routeName);
        }
      });
    }
  }

  bool get isApproved =>
      (currentUser?.isAdmin ?? false) ||
      !Helper.isNullOrEmpty(currentUser?.linkedGradeId);

  Future<User?> fetchProfile({String? studentUID}) async {
    final firestore = FirebaseFirestore.instance;
    User? fetchedUser;
    try {
      String? uid = studentUID;
      if (uid == null) {
        final user = firebase_auth.FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("User not logged in");
        uid = user.uid;
      }

      // 1️⃣ Fetch student profile from Firestore
      final doc = await firestore.collection('students').doc(uid).get();
      if (!doc.exists) throw Exception("Profile not found");

      final data = doc.data()!;

      // 2️⃣ Fetch signed picture URL from Supabase
      final picture = await _fetchSignedUrl(uid) ?? '';
      fetchedUser = User.fromData(data, picture);

      // 3️⃣ Fetch linked grades if available
      final linkedGradesId = data['linkedGradesId'];
      if (!Helper.isNullOrEmpty(linkedGradesId)) {
        final gradesDoc = await firestore
            .collection('scores')
            .doc(linkedGradesId)
            .get();
        if (gradesDoc.exists) {
          final grades = gradesDoc.data()!;
          fetchedUser.grades = {
            'totalScore': grades['totalScore'],
            'assignments': grades['assignments'],
          };
          fetchedUser.grades?['assignments']?.sort(
            (a, b) => (a['index'] as int).compareTo((b['index'] as int)),
          );
        }
      }
      if (studentUID == null) currentUser = fetchedUser;
      return fetchedUser;
    } catch (e) {
      // Get.snackbar("Error", e.toString());
      debugPrint("Error fetching profile: $e");
      return fetchedUser;
    } finally {
      isLoading.value = false;
      update();
    }
  }

  void navigateToLeaderboard({String? studentGroup}) {
    final group = studentGroup ?? currentUser?.group;
    if (group != null) {
      Get.offAllNamed('${LeaderboardPage.routeName}/$group');
    } else {
      Get.offAllNamed(LeaderboardPage.routeName);
    }
  }

  Future<String?> _fetchSignedUrl(String userId) async {
    final url = Uri.parse(
      'https://fookupyinkivtjrqzozw.supabase.co/functions/v1/get-signed-url',
    );

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $supabaseAnonKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['signedUrl'];
    } else {
      debugPrint('Error fetching signed URL: ${response.body}');
      return null;
    }
  }

  Future<void> logout() async {
    await firebase_auth.FirebaseAuth.instance.signOut();
    currentUser = null;
    Get.offAllNamed(LoginPage.routeName);
  }

  Future<void> checkUserApproval() async {
    await fetchProfile();
    if (currentUser?.isNotCompleted ?? true) {
      Get.offAllNamed(LoginPage.routeName);
    } else {
      navigateToLeaderboard(studentGroup: currentUser!.group!);
    }
  }
}
