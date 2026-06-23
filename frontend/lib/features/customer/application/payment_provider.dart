import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_repositories.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((_) => PaymentRepository());
