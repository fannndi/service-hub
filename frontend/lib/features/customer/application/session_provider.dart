import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_repositories.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((_) => SessionRepository());
