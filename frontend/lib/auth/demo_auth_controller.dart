import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'demo_account.dart';

class DemoAuthState {
  const DemoAuthState({this.account, this.errorMessage});

  final DemoAccount? account;
  final String? errorMessage;

  bool get isLoggedIn => account != null;

  DemoAuthState copyWith({DemoAccount? account, String? errorMessage, bool clearAccount = false}) {
    return DemoAuthState(
      account: clearAccount ? null : account ?? this.account,
      errorMessage: errorMessage,
    );
  }
}

class DemoAuthController extends StateNotifier<DemoAuthState> {
  DemoAuthController() : super(const DemoAuthState());

  void login({required DemoRole role, required String phone, required String password}) {
    final account = demoAccounts.where((item) => item.role == role).first;
    final isValid = account.phone == phone.trim() && account.password == password;
    if (!isValid) {
      state = state.copyWith(errorMessage: 'Nomor HP atau password salah. Pakai kredensial dummy yang tersedia.');
      return;
    }
    state = DemoAuthState(account: account);
  }

  void loginAsDemo(DemoRole role) {
    state = DemoAuthState(account: demoAccounts.where((item) => item.role == role).first);
  }

  void logout() {
    state = const DemoAuthState();
  }
}

final demoAuthProvider = StateNotifierProvider<DemoAuthController, DemoAuthState>((ref) => DemoAuthController());
