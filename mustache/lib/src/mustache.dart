import 'package:tekartik_mustache/src/renderer.dart';

import 'import.dart';

/// The main entry point
Future<String> render(String source, Map<String, dynamic> values,
    {PartialResolver partial}) async {
  if (source == null) {
    return null;
  }
  var renderer = new Renderer()
    ..values = values
    ..partialResolver = partial;
  return await renderer.render(source);
}

typedef FutureOr<String> PartialResolver(String name);
typedef FutureOr<String> Lambda(String name);
