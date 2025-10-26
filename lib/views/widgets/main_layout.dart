import 'package:flutter/material.dart';

import '../../helpers/helper.dart';
import '../../services/theme/theme.dart';
import '../home/components/side_bar.dart';

class MainLayout extends StatelessWidget {
  final String? title;
  final Widget child;
  const MainLayout({super.key, required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Helper.isMobile
          ? AppBar(title: Text(title ?? '', style: AppFonts.x18Bold))
          : null,
      drawer: Helper.isMobile ? SideBar() : null,
      body: Row(
        children: [
          if (!Helper.isMobile) SideBar(),
          Expanded(child: child),
        ],
      ),
    );
  }
}
