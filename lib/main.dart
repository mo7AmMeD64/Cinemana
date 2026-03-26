import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/favorites_provider.dart';
import 'utils/app_theme.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // شاشة عرض كاملة
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.surface,
  ));

  runApp(
    ChangeNotifierProvider(
      create: (_) => FavoritesProvider(),
      child: const CinemanaApp(),
    ),
  );
}

class CinemanaApp extends StatelessWidget {
  const CinemanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'سينمانا',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      locale: const Locale('ar'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const MainShell(),
    );
  }
}
