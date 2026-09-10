import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/board_controller.dart';
import 'ui/screens/board_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BoardController()),
      ],
      child: const DigitalBoardApp(),
    ),
  );
}

class DigitalBoardApp extends StatelessWidget {
  const DigitalBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Board',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const BoardScreen(),
    );
  }
}