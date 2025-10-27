import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:group_leaderboard/constants/constants.dart';
import 'package:group_leaderboard/controllers/main_controller.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

import '../../helpers/helper.dart';
import '../widgets/image_picker_by_platform/image_picker_platform.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final storage = FirebaseStorage.instance;
  final nameController = TextEditingController();
  String? selectedGroup;
  Uint8List? imageBytes;
  RxBool isLogin = true.obs;
  RxBool isLoading = false.obs;
  RxBool isCompleteSocialSignIn = false.obs;
  final appAuth = FlutterAppAuth();

  LoginController() {
    if (_auth.currentUser != null) {
      MainController.find.fetchProfile().then((fullProfile) {
        if (fullProfile?.isNotCompleted ?? true) {
          _loadCompleteProfile(_auth.currentUser);
        }
      });
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePickerPlatform.getPlatformPicker();
    final picked = await picker.getImageFromSource(source: ImageSource.gallery);
    if (picked != null) {
      imageBytes = await picked.readAsBytes();
    }
    update();
  }

  Future<void> classicLogin() async {
    isLoading.value = false;
    try {
      if (!(formKey.currentState?.validate() ?? false)) return;
      if (isLogin.value) {
        await _auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
      } else {
        if (imageBytes == null) {
          Helper.snackBar(message: "Please upload your picture");
          return;
        }
        String? uid;
        if (isCompleteSocialSignIn.value) {
          uid = _auth.currentUser!.uid;
        } else {
          final cred = await _auth.createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
          uid = cred.user!.uid;
        }

        // Upload image to Supabase Storage
        final photoUrl = await _uploadPicture(uid, imageBytes!);
        if (photoUrl == null) return;
        // Save student data to Firestore
        await FirebaseFirestore.instance.collection("students").doc(uid).set({
          'uid': uid,
          "name": nameController.text.trim(),
          "group": selectedGroup,
          "email": emailController.text.trim(),
          "photo": photoUrl,
          'linkedGradesId': null,
          "createdAt": FieldValue.serverTimestamp(),
        });
        if (!isCompleteSocialSignIn.value) {
          await _auth.signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
        }
      }
      _clearFields();
      MainController.find.fetchProfile();
      MainController.find.navigateToLeaderboard(studentGroup: selectedGroup);
    } on FirebaseAuthException catch (e) {
      Helper.snackBar(message: 'Error ${e.message ?? 'Auth failed'}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      User? user;
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.setCustomParameters({'prompt': 'select_account'});
        await _auth.signInWithPopup(googleProvider);
        user = _auth.currentUser;
      } else {
        user = await _signInWithGoogleDesktop();
      }

      if (user != null) {
        MainController.find.fetchProfile().then((fullUser) {
          if (fullUser?.isNotCompleted ?? true) {
            _loadCompleteProfile(user);
          } else if (fullUser != null) {
            MainController.find.navigateToLeaderboard(
              studentGroup: fullUser.group,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Sign-in error: $e');
      Helper.snackBar(message: 'Sign-in error: $e');
    }
  }

  void _loadCompleteProfile(User? user) {
    nameController.text = user?.displayName ?? '';
    emailController.text = user?.email ?? '';
    isLogin.value = false;
    isCompleteSocialSignIn.value = true;
  }

  Future<String?> _uploadPicture(String userId, Uint8List fileBytes) async {
    final body = jsonEncode({
      'userId': userId,
      'file': base64Encode(fileBytes),
    });

    final response = await http.post(
      Uri.parse(
        'https://fookupyinkivtjrqzozw.supabase.co/functions/v1/picture-upload',
      ),
      headers: {
        'Authorization': 'Bearer $supabaseAnonKey',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['url'];
    } else {
      debugPrint('Upload failed: ${response.statusCode}');
      Helper.snackBar(message: 'Upload failed: ${response.statusCode}');
      return null;
    }
  }

  Future<User?> _signInWithGoogleDesktop() async {
    final result = await appAuth.authorize(
      AuthorizationRequest(
        googleSignInMacOSClientId,
        '$googleSignInMacOSClientIdReversed:/auth',
        discoveryUrl:
            'https://accounts.google.com/.well-known/openid-configuration',
        scopes: ['openid', 'email', 'profile'],
      ),
    );

    final response = await http.post(
      Uri.parse(
        'https://fookupyinkivtjrqzozw.supabase.co/functions/v1/appAuthAuthentication',
      ),
      headers: {
        'Authorization': 'Bearer $supabaseAnonKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'authorizationCode': result.authorizationCode,
        'codeVerifier': result.codeVerifier,
      }),
    );

    final data = jsonDecode(response.body);
    final idToken = data['id_token'];
    final accessToken = data['access_token'];

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
      accessToken: accessToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );

    return userCredential.user;
  }

  void _clearFields() {
    emailController.clear();
    passwordController.clear();
    nameController.clear();
    selectedGroup = null;
    imageBytes = null;
    isLogin.value = true;
    isCompleteSocialSignIn.value = false;
  }
}
