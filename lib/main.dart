import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/match_provider.dart';
import 'screens/match_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 縦横どちらでも動作
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const JudoTimerApp());
}

class JudoTimerApp extends StatelessWidget {
  const JudoTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MatchProvider(),
      child: MaterialApp(
        title: '柔道審判タイマー',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F3460),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const MatchScreen(),
      ),
    );
  }
}
