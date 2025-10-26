import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:group_leaderboard/controllers/main_controller.dart';
import 'package:group_leaderboard/views/login/login_controller.dart';

import '../../constants/colors.dart';
import '../../services/theme/theme.dart';

class LoginPage extends StatelessWidget {
  static String routeName = '/login';
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<LoginController>(
      builder: (controller) => Material(
        color: Colors.grey.shade300,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800),
            child: Scaffold(
              backgroundColor: Colors.transparent,
              body: Obx(
                () => Center(
                  child: Card(
                    color: Colors.white,
                    margin: const EdgeInsets.all(24),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: controller.formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Spacer(),
                            Text(
                              controller.isCompleteSocialSignIn.value
                                  ? 'Complete Profile'
                                  : controller.isLogin.value
                                  ? 'Login'
                                  : 'Create Account',
                              style: TextStyle(fontSize: 20),
                            ),
                            const SizedBox(height: 32),
                            if (!controller.isLogin.value) ...[
                              GestureDetector(
                                onTap: controller.pickImage,
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundImage: controller.imageBytes != null
                                      ? MemoryImage(controller.imageBytes!)
                                      : null,
                                  child: controller.imageBytes == null
                                      ? const Icon(Icons.add_a_photo, size: 40)
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: controller.nameController,
                                decoration: const InputDecoration(
                                  labelText: "Full Name",
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? "Enter your name"
                                    : null,
                              ),
                              DropdownButtonFormField(
                                items: MainController.find.groups.skip(1)
                                    .map(
                                      (e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    controller.selectedGroup = value!,
                                dropdownColor: Colors.white,
                                decoration: const InputDecoration(
                                  labelText: "Group",
                                ),
                                validator: (v) => v == null || v.isEmpty
                                    ? "Enter your group"
                                    : null,
                              ),
                            ],
                            TextFormField(
                              controller: controller.emailController,
                              decoration: InputDecoration(labelText: 'Email'),
                              validator: (v) => v == null || v.isEmpty
                                  ? "Email is required"
                                  : null,
                            ),
                            if (!controller.isCompleteSocialSignIn.value)
                              TextFormField(
                                controller: controller.passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                ),
                                obscureText: true,
                                validator: (v) => v == null || v.isEmpty
                                    ? "Password is required"
                                    : null,
                              ),
                            const SizedBox(height: 20),
                            controller.isLoading.value
                                ? CircularProgressIndicator()
                                : ElevatedButton(
                                    onPressed: controller.classicLogin,
                                    child: Text(
                                      controller.isCompleteSocialSignIn.value
                                          ? 'Update Profile'
                                          : controller.isLogin.value
                                          ? 'Login'
                                          : 'Sign Up',
                                      style: AppFonts.x16Regular.copyWith(
                                        color: kNeutralColor100,
                                      ),
                                    ),
                                  ),
                            Spacer(),
                            if (!controller.isCompleteSocialSignIn.value) ...[
                              SizedBox(
                                height: 20,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: kBlackColor.withAlpha(150),
                                      ),
                                    ),
                                    Text(
                                      '  ${'or'.tr}  ',
                                      style: AppFonts.x12Regular,
                                    ),
                                    Expanded(
                                      child: Container(
                                        height: 1,
                                        color: kBlackColor.withAlpha(150),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Spacer(),
                              ElevatedButton.icon(
                                icon: Icon(
                                  Icons.login,
                                  color: kNeutralColor100,
                                ),
                                label: Text(
                                  'Sign in with Google',
                                  style: AppFonts.x16Regular.copyWith(
                                    color: kNeutralColor100,
                                  ),
                                ),
                                onPressed: controller.signInWithGoogle,
                              ),
                              Spacer(),
                              TextButton(
                                onPressed: () => controller.isLogin.value =
                                    !controller.isLogin.value,
                                child: Text(
                                  controller.isLogin.value
                                      ? 'Create new account'
                                      : 'Already have an account? Login',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
