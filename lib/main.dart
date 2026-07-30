import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/db/database.dart';
import 'data/repository/news_repository.dart';
import 'services.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting();

  final db = NewsDatabase.instance;
  await db.init();

  final prefs = await SharedPreferences.getInstance();
  appRepository = NewsRepository(db: db);

  final appState = AppState(prefs, db)..load();
  // Housekeeping: enforce retention rules on launch.
  unawaited(appState.runRetention());

  runApp(HindukushApp(appState: appState));
}

void unawaited(Future<void> future) {}
