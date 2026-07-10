import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/store_admin_repositories.dart';
import '../domain/store_admin_models.dart';
import '../../../core/supabase_service.dart';

final storeAuthRepositoryProvider = Provider<StoreAuthRepository>((_) => StoreAuthRepository());

final storeAuthControllerProvider = AsyncNotifierProvider<StoreAuthController, StoreAdminSession?>(StoreAuthController.new);

class StoreAuthController extends AsyncNotifier<StoreAdminSession?> {
  @override
  Future<StoreAdminSession?> build() async {
    final repo = ref.read(storeAuthRepositoryProvider);
    return repo.restoreSession();
  }

  Future<void> login(String phone, String password) async {
    final repo = ref.read(storeAuthRepositoryProvider);
    final user = await repo.login(phone, password);
    // C9: Update is_first_login to false in Supabase metadata on login
    if (user.isFirstLogin) {
      await Supabase.instance.client.auth.updateUser(UserAttributes(
        userMetadata: {'is_first_login': false, 'role': 'store_admin', 'store_id': user.storeId, 'full_name': user.adminName},
      ));
    }
    state = AsyncData(user.copyWith(isFirstLogin: false));
  }

  Future<void> changePassword(String oldPw, String newPw) async {
    final repo = ref.read(storeAuthRepositoryProvider);
    await repo.changePassword(oldPw, newPw);
    // C9: Update is_first_login to false in Supabase metadata
    await Supabase.instance.client.auth.updateUser(UserAttributes(
      userMetadata: {'is_first_login': false},
    ));
    final session = state.valueOrNull;
    if (session != null) {
      state = AsyncData(session.copyWith(isFirstLogin: false));
    }
  }

  Future<void> logout() async {
    try {
      await SupabaseService.instance.signOut();
    } finally {
      state = const AsyncData(null);
    }
  }
}
