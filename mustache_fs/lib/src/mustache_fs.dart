import 'dart:async';
import 'package:tekartik_mustache/mustache.dart';
import 'package:fs_shim/fs.dart';

class MustacheFs {
  final FileSystem fs;

  MustacheFs(this.fs);

  // current path stack
  List<String> paths = [];

  Future<String> renderFile(String path, Map<String, dynamic> values) async {
    var source = await fs.file(path).readAsString();

    // init our stack
    paths = [path];

    return await render(source, values,
        partialResolver: (String partial, int depth) async {
      var path = partial;

      // Truncate current stack at the given depth
      if (depth + 1 < paths.length) {
        paths = paths.sublist(0, depth + 1);
      }
      var contextPath = paths.last;

      var ctx = fs.pathContext;
      // try to resolve from current file

      if (ctx.isRelative(path)) {
        path = ctx.normalize(ctx.join(ctx.dirname(contextPath), path));
      }
      // add current path to the stack
      paths.add(path);

      var content = await fs.file(path).readAsString();
      return content;
    });
  }
}

Future<String> renderFile(
    FileSystem fs, String path, Map<String, dynamic> values) async {
  var mustacheFs = new MustacheFs(fs);
  return await mustacheFs.renderFile(path, values);
}
