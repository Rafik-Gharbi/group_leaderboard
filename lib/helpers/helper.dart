import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constants/colors.dart';
import '../constants/constants.dart';
import '../services/theme/theme.dart';

class Helper {
  static Timer? _searchOnStoppedTyping;

  static void snackBar({
    String message = 'Snack bar test',
    String? title,
    Duration? duration,
    bool includeDismiss = true,
    Widget? overrideButton,
    TextStyle? styleMessage,
  }) => GetSnackBar(
    titleText: title != null
        ? Text(title.tr, style: styleMessage ?? AppFonts.x16Bold)
        : null,
    messageText: Text(message.tr, style: styleMessage ?? AppFonts.x14Regular),
    duration: duration ?? const Duration(seconds: 3),
    isDismissible: true,
    borderColor: kSecondaryColor,
    borderWidth: 2,
    borderRadius: 10,
    margin: isMobile
        ? const EdgeInsets.symmetric(horizontal: 2).copyWith(bottom: 10)
        : EdgeInsets.only(left: (Get.width / 3) * 2, right: 50, bottom: 10),
    backgroundColor: kNeutralColor100,
    snackPosition: SnackPosition.BOTTOM,
    mainButton:
        overrideButton ??
        (includeDismiss
            ? TextButton(onPressed: Get.back, child: Text('dismiss'.tr))
            : null),
  ).show();

  static Future<dynamic> waitAndExecute(
    bool Function() condition,
    Function callback, {
    Duration? duration,
  }) async {
    while (!condition()) {
      await Future.delayed(
        duration ?? const Duration(milliseconds: 800),
        () {},
      );
    }
    return callback();
  }

  static bool isNullOrEmpty(String? value) => value == null || value.isEmpty;

  static void onSearchDebounce(
    void Function() callback, {
    Duration duration = const Duration(milliseconds: 800),
  }) {
    if (_searchOnStoppedTyping != null) _searchOnStoppedTyping!.cancel();
    _searchOnStoppedTyping = Timer(duration, callback);
  }

  static bool get isMobile =>
      Get.width <= kMobileMaxWidth ||
      GetPlatform.isAndroid ||
      GetPlatform.isIOS ||
      GetPlatform.isMobile;

  static void openConfirmationDialog({
    String? title,
    required String content,
    required void Function() onConfirm,
    void Function()? onCancel,
    Color? barrierColor,
  }) => Get.dialog(
    AlertDialog(
      backgroundColor: Colors.white,
      title: Text(title ?? 'Are you sure?'),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () {
            onConfirm.call();
            Get.back();
          },
          child: Text(
            'Yes',
            style: AppFonts.x14Bold.copyWith(color: kPrimaryColor),
          ),
        ),
        TextButton(
          onPressed: onCancel ?? () => Get.back(),
          child: Text(
            'Cancel',
            style: AppFonts.x14Bold.copyWith(color: kErrorColor),
          ),
        ),
      ],
    ),
    barrierColor: barrierColor?.withAlpha(80),
  );
}
