enum DemoOrderStatus { waitingApproval, repairing, waitingPayment, completed, disputed }

extension DemoOrderStatusLabel on DemoOrderStatus {
  String get label => switch (this) {
    DemoOrderStatus.waitingApproval => 'Menunggu Persetujuan',
    DemoOrderStatus.repairing => 'Sedang Diperbaiki',
    DemoOrderStatus.waitingPayment => 'Menunggu Pembayaran',
    DemoOrderStatus.completed => 'Selesai',
    DemoOrderStatus.disputed => 'Klaim Garansi',
  };
}

class DemoServiceOrder {
  const DemoServiceOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.device,
    required this.issue,
    required this.status,
    required this.estimatedPrice,
    required this.finalPrice,
  });

  final String id;
  final String orderNumber;
  final String customerName;
  final String device;
  final String issue;
  final DemoOrderStatus status;
  final int estimatedPrice;
  final int? finalPrice;
}

const demoOrders = [
  DemoServiceOrder(
    id: 'ord_001',
    orderNumber: 'SG-8K2L9A',
    customerName: 'Budi Santoso',
    device: 'Samsung A52',
    issue: 'LCD bergaris dan baterai cepat habis',
    status: DemoOrderStatus.waitingApproval,
    estimatedPrice: 750000,
    finalPrice: 820000,
  ),
  DemoServiceOrder(
    id: 'ord_002',
    orderNumber: 'SG-P4M7QZ',
    customerName: 'Siti Aminah',
    device: 'iPhone XR',
    issue: 'Speaker mati',
    status: DemoOrderStatus.repairing,
    estimatedPrice: 450000,
    finalPrice: null,
  ),
  DemoServiceOrder(
    id: 'ord_003',
    orderNumber: 'SG-Z1N8BV',
    customerName: 'Rizky Pratama',
    device: 'Xiaomi Note 10',
    issue: 'Tidak bisa charge',
    status: DemoOrderStatus.waitingPayment,
    estimatedPrice: 300000,
    finalPrice: 350000,
  ),
];

class DemoSparepart {
  const DemoSparepart({required this.name, required this.stock, required this.reserved, required this.price});

  final String name;
  final int stock;
  final int reserved;
  final int price;

  int get available => stock - reserved;
}

const demoSpareparts = [
  DemoSparepart(name: 'LCD Samsung A52', stock: 5, reserved: 2, price: 650000),
  DemoSparepart(name: 'Battery iPhone XR', stock: 3, reserved: 0, price: 420000),
  DemoSparepart(name: 'Connector Charger Xiaomi', stock: 2, reserved: 1, price: 180000),
];

String rupiah(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < text.length; index++) {
    final reverseIndex = text.length - index;
    buffer.write(text[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write('.');
  }
  return 'Rp$buffer';
}
