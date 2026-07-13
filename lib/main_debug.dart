import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/pairing_screen.dart';
import 'screens/home_screen.dart';
import 'utils/app_routes.dart';

final ValueNotifier<String?> globalError = ValueNotifier<String?>(null);

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Bắt lỗi xảy ra lúc build giao diện (không chỉ lúc khởi tạo)
    FlutterError.onError = (FlutterErrorDetails details) {
      globalError.value = details.exceptionAsString();
      FlutterError.presentError(details);
    };

    try {
      await dotenv.load(fileName: '.env');
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      );
    } catch (e, st) {
      globalError.value = '$e\n\n$st';
    }

    runApp(const RootApp());
  }, (error, stack) {
    // Bắt mọi lỗi bất đồng bộ không được try-catch bắt được
    globalError.value = '$error\n\n$stack';
  });
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: globalError,
      builder: (context, error, _) {
        if (error != null) {
          return ErrorApp(message: error);
        }
        return const MyApp();
      },
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String message;
  const ErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFFFFF0F0),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: SelectableText(
                'Lỗi khởi động app:\n\n$message',
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Dodder',
        theme: ThemeData(
          primaryColor: Colors.pink[300],
          useMaterial3: true,
          fontFamily: 'Quicksand',
        ),
        initialRoute: AppRoutes.login,
        routes: {
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.register: (context) => const RegisterScreen(),
          AppRoutes.profile: (context) => const ProfileSetupScreen(),
          AppRoutes.pairing: (context) => const PairingScreen(),
          AppRoutes.home: (context) => const HomeScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
