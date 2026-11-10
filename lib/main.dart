import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/theme.dart';
import 'state/app_state.dart';
import 'ui/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const RenrenApp());
}

/// 「认认」入口。第一期是纯工具类应用：不注册、不联网，打开就是卡片。
class RenrenApp extends StatefulWidget {
  const RenrenApp({super.key});

  @override
  State<RenrenApp> createState() => _RenrenAppState();
}

class _RenrenAppState extends State<RenrenApp> {
  @override
  void initState() {
    super.initState();
    appState.load();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        return MaterialApp(
          title: '认认',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.build(),
          home: const HomePage(),
        );
      },
    );
  }
}
