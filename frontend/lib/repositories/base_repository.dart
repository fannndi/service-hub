import 'package:dio/dio.dart';

abstract class BaseRepository {
  const BaseRepository(this.client);

  final Dio client;
}
