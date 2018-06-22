import 'package:path/path.dart';
import 'package:tekartik_mustache_cli/mustache_cli.dart';

main() async {
  var dir = join('example', 'basic');
  var srcDataPath = join(dir, 'data.json');
  var srcPath = join(dir, 'index.html');
  await mustacheMain([srcDataPath, srcPath]);
}
