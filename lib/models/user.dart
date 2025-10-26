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

  factory User.fromData(Map<String, dynamic> data, String picture) => User(
    uid: data['uid'],
    name: data['name'],
    email: data['email'],
    photo: picture,
    group: data['group'],
    linkedGradeId: data['linkedGradesId'],
  );

  bool get isNotCompleted =>
      name == null || email == null || photo == null || group == null;
}
