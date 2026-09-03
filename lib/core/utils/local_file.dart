import 'package:job_planner/data/datasources/synced_file_store.dart';

bool localFileExists(String? path) {
  if (path == null || path.isEmpty) return false;
  return SyncedFileStore.instance.exists(path);
}
