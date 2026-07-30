import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

enum BackendStatus { notConfigured, ready }

final backendStatusProvider = Provider<BackendStatus>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.isBackendConfigured
      ? BackendStatus.ready
      : BackendStatus.notConfigured;
});
