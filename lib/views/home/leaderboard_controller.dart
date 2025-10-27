// import 'package:web/web.dart' as web;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:group_leaderboard/helpers/helper.dart';

class LeaderboardController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Query<Map<String, dynamic>> baseQuery;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];
  RxBool isLoading = true.obs;
  String? _selectedGroup;
  double? groupSum;
  int totalStudents = 0;

  String? get selectedGroup => _selectedGroup;

  set selectedGroup(String? value) {
    if (value == _selectedGroup) return;
    _selectedGroup = value == 'All' ? null : value;
    if (_selectedGroup != null) {
      Get.parameters['groupID'] = _selectedGroup;
      // web.window.history.pushState(
      //   null,
      //   'Leaderboard $_selectedGroup',
      //   "/leaderboard/$_selectedGroup",
      // );
    } else {
      Get.parameters['groupID'] = '';
      // web.window.history.pushState(null, 'Groups Overview', "/leaderboard");
    }
    update();
    getFirestoreQuery();
  }

  LeaderboardController() {
    getFirestoreQuery();
  }

  Future<void> getFirestoreQuery() async {
    isLoading.value = true;
    baseQuery = _firestore.collection('scores');

    if ((selectedGroup ?? 'All') != 'All') {
      baseQuery = baseQuery.where('group', isEqualTo: selectedGroup);
    }

    // Order by totalScore desc, then studentName asc for tie-breaker
    baseQuery = baseQuery
        .orderBy('totalScore', descending: true)
        .orderBy('studentName');

    try {
      final result = await baseQuery.get();
      docs = result.docs;
      if (selectedGroup != null) {
        groupSum = double.tryParse(
          docs
              .map((e) => e['totalScore'] ?? 0)
              .reduce((value, element) => value + element)
              .toString(),
        );
        totalStudents = docs.length;
      } else {
        groupSum = null;
      }
    } catch (e) {
      Helper.snackBar(message: "Error: $e");
    }
    isLoading.value = false;
  }
}
