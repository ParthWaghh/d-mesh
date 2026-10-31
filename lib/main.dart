import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/tactical_theme.dart';
import 'features/shell/main_shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: DMeshApp(),
    ),
  );
}

class DMeshApp extends StatelessWidget {
  const DMeshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'D-MESH Emergency Network',
      debugShowCheckedModeBanner: false,
      theme: TacticalTheme.darkTheme,
      home: const MainShellScreen(),
    );
  }
}

