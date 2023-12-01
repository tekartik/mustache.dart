import 'package:tekartik_mustache/src/mustache.dart';

typedef Lambda = LambdaSync;

/// Sync rendering.
String render(String source, Map<String, Object?> values, {Lambda? lambda}) {
  return mustacheRenderSync(source, values, lambda: lambda);
}
