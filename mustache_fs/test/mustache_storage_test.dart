import 'package:tekartik_firebase_sembast/firebase_sembast_io.dart';
import 'package:tekartik_mustache_fs/mustache_storage.dart';

import 'mustache_fs_test.dart';

main() {
  var app = firebaseSembastIo.initializeApp();
  var bucket = app.storage().bucket("test");
  var fs = fileSystemStorage(bucket);
  fsTest(fs);
}
