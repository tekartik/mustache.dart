import 'dart:async';
import 'dart:convert';
import 'package:tekartik_mustache/mustache.dart';
import 'package:fs_shim/fs.dart';
import 'package:yaml/yaml.dart';

class MustacheFs {
  final FileSystem fs;

  MustacheFs(this.fs);

  Future<String> renderFile(String path,
      {Map<String, dynamic> values, String yamlPath, String jsonPath}) async {
    if (values == null) {
      if (yamlPath != null) {
        values = (await loadYaml(await fs.file(yamlPath).readAsString()) as Map)
            ?.cast<String, dynamic>();
      } else if (jsonPath != null) {
        values = (json.decode(await fs.file(jsonPath).readAsString()) as Map)
            ?.cast<String, dynamic>();
      }
    }
    var source = await fs.file(path).readAsString();

    // init our stack

    return await render(source, values,
        partialContext: new PartialContext(path),
        partial: (String partial, PartialContext context) async {
      var path = partial;

      var contextPath = context.parent.userData as String;

      var ctx = fs.pathContext;
      // try to resolve from current file

      if (ctx.isRelative(path)) {
        path = ctx.normalize(ctx.join(ctx.dirname(contextPath), path));
      }
      // set current path to the context
      context.userData = path;

      var content = await fs.file(path).readAsString();
      return content;
    });
  }
}

Future<String> renderFile(FileSystem fs, String path,
    {Map<String, dynamic> values, String yamlPath, String jsonPath}) async {
  var mustacheFs = new MustacheFs(fs);
  return await mustacheFs.renderFile(path,
      values: values, yamlPath: yamlPath, jsonPath: jsonPath);
}
