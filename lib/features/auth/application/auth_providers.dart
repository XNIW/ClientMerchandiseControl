import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/backend/backend_readiness_state.dart';
import '../../../core/backend/secure_supabase_auth_storage.dart';
import '../../../core/backend/supabase_bootstrap.dart';
import '../../../core/config/app_config.dart';
import '../data/auth_callback_source.dart';
import '../data/auth_callback_validator.dart';
import '../data/auth_error_mapper.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/authenticated_customer.dart';

typedef AuthRepositoryFactory =
    Future<AuthRepository> Function(AppConfig config);

typedef AuthenticatedSignOutCleanup =
    Future<void> Function(AuthenticatedCustomer customer);

final authenticatedSignOutCleanupProvider =
    Provider<AuthenticatedSignOutCleanup>((ref) {
      return (_) async {};
    });

final authSecureStorageProvider = Provider<SecureSupabaseAuthStorage>((ref) {
  return SecureSupabaseAuthStorage.standardInstance;
});

final authRepositoryFactoryProvider = Provider<AuthRepositoryFactory>((ref) {
  final storage = ref.watch(authSecureStorageProvider);
  return (config) async {
    final bootstrapState = await SupabaseBootstrap.initialize(
      config,
      authStorage: storage,
    );
    if (bootstrapState != BackendReadinessState.initializing) {
      throw const AuthRepositoryException('supabase_auth_not_initialized');
    }
    return SupabaseAuthRepository(
      authPort: PlatformSupabaseAuthPort(Supabase.instance.client),
      secureStorage: storage,
      redirectUri: config.authRedirectUri!,
    );
  };
});

final authCallbackSourceProvider = Provider<AuthCallbackSource>((ref) {
  final source = AppLinksAuthCallbackSource();
  ref.onDispose(() => unawaited(source.dispose()));
  return source;
});

final authCallbackValidatorProvider = Provider<AuthCallbackValidator>((ref) {
  final callback = Uri.parse(AppConfig.allowedAuthRedirectUri);
  return AuthCallbackValidator(
    allowedScheme: callback.scheme,
    allowedHost: callback.host,
    allowedPath: callback.path,
  );
});

final authErrorMapperProvider = Provider<AuthErrorMapper>((ref) {
  return const AuthErrorMapper();
});
