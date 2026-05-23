import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:reportes_ai/app/app.dart';
import 'package:reportes_ai/data/local/hive/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  const supabaseUrl = 'https://ytvikiovumjlosbsjmnl.supabase.co';
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  if (supabasePublishableKey.isEmpty) {
    throw Exception('Falta SUPABASE_PUBLISHABLE_KEY');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabasePublishableKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  await HiveService.init();

  runApp(
    const ProviderScope(
      child: AiReportsApp(),
    ),
  );
}