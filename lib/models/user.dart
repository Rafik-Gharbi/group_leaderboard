import 'package:group_leaderboard/helpers/helper.dart';

import '../constants/constants.dart';

class User {
  final String? uid;
  final String? name;
  final String? email;
  final String? photo;
  final String? group;
  final String? linkedGradeId;
  Map<String, dynamic>? grades;

  User({
    required this.uid,
    required this.name,
    required this.email,
    required this.photo,
    required this.group,
    required this.linkedGradeId,
    this.grades,
  });

  factory User.fromData(Map<String, dynamic> data, {String? picture, String? uid}) => User(
    uid: uid ?? data['uid'],
    name: data['name'] ?? data['studentName'],
    email: data['email'],
    photo: picture,
    group: data['group'],
    linkedGradeId: data['linkedGradesId'],
  );

  bool get isNotCompleted =>
      Helper.isNullOrEmpty(name) ||
      Helper.isNullOrEmpty(email) ||
      Helper.isNullOrEmpty(photo) ||
      Helper.isNullOrEmpty(group);

  bool get isAdmin => email == adminEmail;
}
