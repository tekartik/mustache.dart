import 'package:fs_shim/fs_io.dart';
import 'package:tekartik_mustache_fs/mustache_fs.dart';

main() async {
  var fs = fileSystemIo;
  var path = fs.pathContext;
  var sourcePath = path.join('example', 'index.html');
  var dataPath = path.join('example', 'data.json');
  var destPath = path.join('example', 'out.html');

  var text = await renderFile(fs, sourcePath, jsonPath: dataPath);
  await fs.file(destPath).writeAsString(text);
  print(text);
}