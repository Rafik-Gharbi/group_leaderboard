import 'dart:ui' show PointerDeviceKind;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:group_leaderboard/constants/colors.dart';
import 'package:group_leaderboard/constants/constants.dart';
import 'package:group_leaderboard/controllers/main_controller.dart';

import 'package:group_leaderboard/services/shared_preferences.dart';
import 'package:group_leaderboard/views/grades_matching/grades_matching_controller.dart';
import 'package:group_leaderboard/views/grades_matching/grades_matching_page.dart';
import 'package:group_leaderboard/views/home/leaderboard_controller.dart';
import 'package:group_leaderboard/views/home/leaderboard_page.dart';
import 'package:group_leaderboard/views/login/login_controller.dart';
import 'package:group_leaderboard/views/login/login_page.dart';
import 'package:group_leaderboard/views/pending_approval/pending_approval_page.dart';
import 'package:group_leaderboard/views/profile/profile_controller.dart';
import 'package:group_leaderboard/views/profile/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'helpers/helper.dart';
import 'views/overview/overview_controller.dart';
import 'views/overview/overview_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: 'https://fookupyinkivtjrqzozw.supabase.co',
    anonKey: supabaseAnonKey,
  );
  usePathUrlStrategy();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Leaderboard',
        theme: ThemeData(
          primaryColor: Colors.blue,
          splashColor: Colors.white,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white70,
            surfaceTintColor: Colors.blue.shade200,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(kPrimaryColor),
            ),
          ),
        ),
        initialBinding: InitialBindings(),
        initialRoute: LeaderboardPage.routeName,
        getPages: [
          GetPage(
            name: "${LeaderboardPage.routeName}/:groupID",
            page: () => const LeaderboardPage(),
            binding: BindingsBuilder.put(() => LeaderboardController()),
            middlewares: [AuthGuard(), ApprovalGuard()],
          ),
          GetPage(
            name: LeaderboardPage.routeName,
            page: () => const LeaderboardPage(),
            binding: BindingsBuilder.put(() => LeaderboardController()),
            middlewares: [AuthGuard(), ApprovalGuard()],
          ),
          GetPage(
            name: LoginPage.routeName,
            page: () => const LoginPage(),
            binding: BindingsBuilder.put(() => LoginController()),
          ),
          GetPage(
            name: ProfilePage.routeName,
            page: () => const ProfilePage(),
            binding: BindingsBuilder.put(() => ProfileController()),
            middlewares: [AuthGuard(), ApprovalGuard()],
          ),
          GetPage(
            name: OverviewPage.routeName,
            page: () => const OverviewPage(),
            binding: BindingsBuilder.put(() => OverviewController()),
            middlewares: [AuthGuard(), ApprovalGuard()],
          ),
          GetPage(
            name: GradesMatchingPage.routeName,
            page: () => const GradesMatchingPage(),
            binding: BindingsBuilder.put(() => GradesMatchingController()),
            middlewares: [AuthGuard(), ApprovalGuard()],
          ),
          GetPage(
            name: PendingApprovalPage.routeName,
            page: () => const PendingApprovalPage(),
            middlewares: [AuthGuard()],
          ),
        ],
      ),
    );
  }
}

class InitialBindings implements Bindings {
  @override
  void dependencies() {
    // Controllers & Services
    Get.put(SharedPreferencesService(), permanent: true);
    Get.put(MainController(), permanent: true);
    Get.put(LeaderboardController(), permanent: true);
  }
}

class AuthGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return RouteSettings(name: LoginPage.routeName);
    }
    return null;
  }
}

class ApprovalGuard extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final user = MainController.find.currentUser;
    if (Helper.isNullOrEmpty(user?.linkedGradeId)) {
      return RouteSettings(name: PendingApprovalPage.routeName);
    }
    return null;
  }
}
