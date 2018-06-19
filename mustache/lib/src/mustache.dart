import 'package:tekartik_mustache/src/renderer.dart';

import 'import.dart';

/// The main entry point
/// [partialResolver] contains an id of the content depth
Future<String> render(String source, Map<String, dynamic> values,
    {PartialResolver partial, PartialResolverWithId partialResolver}) async {
  if (source == null) {
    return null;
  }
  var renderer = new Renderer()
    ..values = values
    ..partial = partial
    ..partialResolver = partialResolver;
  return await renderer.render(source);
}

typedef FutureOr<String> PartialResolver(String name);
typedef FutureOr<String> PartialResolverWithId(
    String name, int depth); // id is null for root
typedef FutureOr<String> Lambda(String name);
