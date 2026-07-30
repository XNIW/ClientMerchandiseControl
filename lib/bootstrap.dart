import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/client_merchandise_control_app.dart';
import 'core/backend/supabase_bootstrap.dart';
import 'core/config/app_config.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  await SupabaseBootstrap.initialize(config);

  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config)],
      child: const ClientMerchandiseControlApp(),
    ),
  );
}
