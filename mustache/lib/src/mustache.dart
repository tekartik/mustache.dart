import 'package:tekartik_mustache/src/renderer.dart';

import 'import.dart';

/// The main entry point
/// [partialResolver] contains an id of the content depth
Future<String> render(String source, Map<String, dynamic> values,
    {PartialResolver partial, PartialContext partialContext}) async {
  if (source == null) {
    return null;
  }
  var renderer = new Renderer()
    ..values = values
    ..partial = partial
    ..partialContext = partialContext;
  return await renderer.render(source);
}

abstract class PartialAnyContext {
  PartialParentContext get parent;
}

abstract class PartialParentContext extends PartialAnyContext {
  dynamic get userData;
}

abstract class PartialContext extends PartialParentContext {
  factory PartialContext(dynamic userData) =>
      new RendererPartialContext(null, userData);

  set userData(dynamic userData);
}

typedef FutureOr<String> PartialResolver(String name, PartialContext context);
typedef FutureOr<String> Lambda(String name);
