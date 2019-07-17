@TestOn('vm')
import 'package:tekartik_firebase_local/firebase_local.dart';
import 'package:tekartik_firebase_storage_fs/storage_fs_io.dart';
import 'package:tekartik_mustache_fs/mustache_storage.dart';
import 'package:test/test.dart';

import 'mustache_fs_test.dart';

void main() {
  var app = FirebaseLocal().initializeApp();
  var bucket = storageServiceIo.storage(app).bucket("test");
  var fs = fileSystemStorage(bucket);
  fsTest(fs);
}
