import 'dart:async';

import 'package:excelerate_talent_hub/services/mock_api.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await MockApi.preloadPrograms();
  await testMain();
}
