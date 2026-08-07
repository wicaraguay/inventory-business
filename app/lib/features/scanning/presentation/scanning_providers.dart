import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventy_app/features/scanning/data/http_scan_repository.dart';
import 'package:inventy_app/features/scanning/domain/scan_repository.dart';
import 'package:inventy_app/shared/api/api_client.dart';

final scanRepositoryProvider = Provider<ScanRepository>((ref) {
  return HttpScanRepository(ref.watch(dioProvider));
});
