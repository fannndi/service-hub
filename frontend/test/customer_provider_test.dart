import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:servisgadget_foundation/features/customer/application/customer_providers.dart';
import 'package:servisgadget_foundation/features/customer/data/customer_repositories.dart';

class FakeSessionStorage extends CustomerSessionStorage {
  const FakeSessionStorage() : super(const FlutterSecureStorage());

  @override
  Future<String?> readAccessToken() async => null;
}

void main() {
  test('auth provider resolves unauthenticated when no cached access token exists', () async {
    final container = ProviderContainer(overrides: [
      customerSessionProvider.overrideWithValue(const FakeSessionStorage()),
    ]);
    addTearDown(container.dispose);

    final user = await container.read(customerAuthProvider.future);

    expect(user, isNull);
  });
}
