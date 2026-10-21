import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/mock_api.dart';
import 'services/program_repository.dart';
import 'services/storage_service.dart';
import 'utils/app_router.dart';
import 'utils/constants.dart';
import 'utils/themes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  runApp(AppConstants.useMock
      ? ExcelerateApp(
          preferences: preferences,
          apiBaseUrl: MockApi.baseUrl,
          apiClient: MockApi().client)
      : ExcelerateApp(preferences: preferences));
}

class ExcelerateApp extends StatelessWidget {
  const ExcelerateApp(
      {super.key,
      required this.preferences,
      this.apiBaseUrl = AppConstants.apiBaseUrl,
      this.apiClient});
  final SharedPreferences preferences;
  final String apiBaseUrl;
  final http.Client? apiClient;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          Provider<StorageService>(create: (_) => StorageService(preferences)),
          Provider<ApiService>(
              create: (_) => ApiService(baseUrl: apiBaseUrl, client: apiClient),
              dispose: (_, api) => api.dispose()),
          Provider<ProgramRepository>(
              create: (context) =>
                  ApiProgramRepository(context.read<ApiService>())),
          ChangeNotifierProvider<AuthService>(create: (context) {
            final auth = AuthService(
                context.read<ApiService>(), context.read<StorageService>());
            unawaited(auth.restoreSession());
            return auth;
          }),
        ],
        child: MaterialApp(
            title: AppConstants.name,
            debugShowCheckedModeBanner: false,
            theme: AppThemes.light,
            initialRoute: AppRoutes.home,
            onGenerateRoute: AppRouter.generate),
      );
}
