import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_repositories.dart';
import '../domain/customer_models.dart';
import '../../../core/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final customerAuthRepositoryProvider = Provider<CustomerAuthRepository>((_) => CustomerAuthRepository());

final customerAuthProvider = AsyncNotifierProvider<CustomerAuthNotifier, CustomerUser?>(CustomerAuthNotifier.new);

class CustomerAuthNotifier extends AsyncNotifier<CustomerUser?> {
  @override
  Future<CustomerUser?> build() async {
    final repo = ref.read(customerAuthRepositoryProvider);
    return repo.restoreSession();
  }

  Future<CustomerUser> login(String phone, String password) async {
    final repo = ref.read(customerAuthRepositoryProvider);
    final user = await repo.login(phone, password);
    // C8: Update is_first_login to false in Supabase metadata on login
    if (user.isFirstLogin) {
      await Supabase.instance.client.auth.updateUser(UserAttributes(
        userMetadata: {'is_first_login': false, 'full_name': user.fullName},
      ));
    }
    state = AsyncData(user.copyWith(isFirstLogin: false));
    return user;
  }

  Future<void> logout() async {
    try {
      await SupabaseService.instance.signOut();
    } finally {
      state = const AsyncData(null);
    }
  }

  Future<void> changePassword(String oldPw, String newPw) async {
    final repo = ref.read(customerAuthRepositoryProvider);
    await repo.changePassword(oldPw, newPw);
    // C8: Update is_first_login to false in Supabase metadata
    await Supabase.instance.client.auth.updateUser(UserAttributes(
      userMetadata: {'is_first_login': false},
    ));
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(current.copyWith(isFirstLogin: false));
    }
  }

  Future<void> updateProfile({String? fullName, String? address}) async {
    final repo = ref.read(customerAuthRepositoryProvider);
    await repo.updateProfile(fullName: fullName, address: address);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(CustomerUser(
        id: current.id,
        fullName: fullName ?? current.fullName,
        phoneNumber: current.phoneNumber,
        isFirstLogin: current.isFirstLogin,
        address: address ?? current.address,
      ));
    }
  }
}
