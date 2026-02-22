import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'view_models/login_viewmodel.dart';
import 'views/jogo/jogo_page.dart';
import 'views/caregiver/home/caregiver_home_page.dart';
import 'views/onboarding/onboarding_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository(Supabase.instance.client);

    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepository),
        ChangeNotifierProvider(create: (_) => LoginViewModel(authRepository)),
      ],
      child: MaterialApp(
        title: 'ToRemember',
        theme: AppTheme.theme,
        debugShowCheckedModeBanner: false,
        home: _resolveHome(authRepository),
      ),
    );
  }

  Widget _resolveHome(AuthRepository repo) {
    final user = repo.currentUser;
    if (user == null) return const OnboardingPage();

    final role = user.userMetadata?['role'] as String?;
    if (role == 'caregiver') return const CaregiverHomePage();
    return const PatientHomePage();
  }
}
