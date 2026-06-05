enum DemoRole { customer, storeAdmin }

class DemoAccount {
  const DemoAccount({
    required this.role,
    required this.name,
    required this.phone,
    required this.password,
    required this.label,
    this.storeName,
    this.storeId,
    this.isFirstLogin = false,
  });

  final DemoRole role;
  final String name;
  final String phone;
  final String password;
  final String label;
  final String? storeName;
  final String? storeId;
  final bool isFirstLogin;
}

const demoCustomerAccount = DemoAccount(
  role: DemoRole.customer,
  name: 'Budi Santoso',
  phone: '081234567890',
  password: 'customer123',
  label: 'Customer Dummy',
);

const demoStoreAdminAccount = DemoAccount(
  role: DemoRole.storeAdmin,
  name: 'Admin GadgetCare',
  phone: '081298765432',
  password: 'admin123',
  label: 'Admin Toko Dummy',
  storeName: 'GadgetCare Bandung',
  storeId: 'store_demo_gadgetcare',
  isFirstLogin: false,
);

const demoAccounts = [demoCustomerAccount, demoStoreAdminAccount];
