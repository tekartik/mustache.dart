---
name: tekartik-mustache-render
description: >-
  Use when rendering Mustache templates in Dart with tekartik_mustache: the
  async render(source, values, {partial, partialContext}) of
  package:tekartik_mustache/mustache.dart, the synchronous render(source,
  values, {lambda}) of package:tekartik_mustache/mustache_sync.dart,
  mustacheRenderSync, and the PartialResolver, PartialContext,
  PartialParentContext, Lambda and LambdaSync typedefs, plus the supported
  template syntax ({{var}}, {{{var}}}, {{&var}}, {{#section}}, {{^inverted}},
  {{>partial}}, {{!comment}}, {{=<% %>=}}, dotted names, {{.}}).
---

# Rendering Mustache templates (tekartik_mustache)

`tekartik_mustache` is a small, mirror-free Mustache renderer: values come from
a plain `Map<String, Object?>`, partials are resolved by a callback you provide
(so they can come from a file system, a database or a map), and both the
partial resolver and the lambdas may be asynchronous.

## Guidelines

* Dependency (git only, not on pub.dev):
  ```yaml
  dependencies:
    tekartik_mustache:
      git:
        url: https://github.com/tekartik/mustache.dart
        path: mustache
  ```
* Two entry points, both exporting a top level function called `render`.
  **Never import both in the same file** without a prefix.
  * `package:tekartik_mustache/mustache.dart`:
    `Future<String?> render(String? source, Map<String, dynamic>? values,
    {PartialResolver? partial, PartialContext? partialContext})`. A null
    `source` gives a null result, a null `values` behaves like an empty map.
    The library also exports `mustacheRenderSync`, `PartialResolver`,
    `PartialContext`, `PartialParentContext`, `Lambda` and `LambdaSync`.
  * `package:tekartik_mustache/mustache_sync.dart`:
    `String render(String source, Map<String, Object?> values,
    {Lambda? lambda})` where `Lambda` is `LambdaSync`, i.e.
    `String? Function(String name)`. Here `lambda` is the **partial resolver**:
    it is called with the name of each `{{>name}}` and returns its template
    (or null). It is a thin wrapper over `mustacheRenderSync`.
* Async partials: `PartialResolver` is
  `FutureOr<String?> Function(String name, PartialContext context)`. Return
  the partial template (it is rendered with the current values), or null for
  an unknown partial. A map lookup `(name, _) => partials[name]` covers the
  simple case; an `async` body lets you read a file.
* `partialContext: PartialContext(userData)` carries your own data down the
  partial chain, which is how relative resolution (a partial including another
  partial by relative path) is done. Inside the resolver, `context.userData`
  is the data for the partial being resolved (initially null; set it to give
  its own children a value) and `context.parent!.userData` is the data of the
  including level, `context.parent!.parent!.userData` the one above, up to the
  `PartialContext(...)` you passed to `render`.
* Values: a `String` goes through Dart's `htmlEscape` for `{{var}}` (`&`, `<`,
  `>`, `"`, `'` and `/` are escaped) and is left as is for
  `{{{var}}}` / `{{&var}}`; `null` and a missing key render as an empty string;
  `bool`, `num` and other objects are rendered with `toString()`.
* A value that is a `Function` is a lambda called with a `String` argument:
  for `{{f}}` it receives the key (`'f'`), for `{{#f}}inner{{/f}}` it receives
  the raw inner source (`'inner'`, `'{{x}}'` unexpanded). Its `String` result is
  itself rendered as a template with the same values, then escaped like a
  variable, so `{{f}}` escapes the lambda result twice; use `{{{f}}}` when the
  lambda already produces html. In async rendering the lambda may return a
  `Future<String>`; in sync rendering a `Future` or a `bool` result throws
  `UnsupportedError`.
* Sections: `{{#s}}` renders once for a truthy map/object, once per element for
  a `List` (with the element as the current context, `{{.}}` being the element
  itself), and not at all for `false`, `null`, a missing key or an empty list.
  `{{^s}}` is the inverted section. Dotted names (`{{var.sub}}`,
  `{{#a}}{{b.c}}{{/a}}`) resolve inside the current context only, without
  falling back to the parent for the first segment.
* Also supported: `{{!comment}}`, standalone-line trimming (a line holding only
  a section, partial or comment tag disappears), and delimiter changes
  `{{=<% %>=}}` (triple `{{{ }}}` no-escape only works with the default
  delimiters).
* Testing: the package runs the official Mustache spec (`test/spec/*.json`)
  through `test/run_spec.dart`; `supported_spec_test.dart` lists the spec files
  that pass today (interpolation, sections, inverted, comments, partials,
  delimiters, lambdas). Expect the odd whitespace/indentation difference from
  other implementations: a partial's own indentation is not re-indented.
* Anti-patterns: importing `mustache.dart` and `mustache_sync.dart` together;
  `await`ing the sync `render`; expecting `{{>name}}` to work without a
  `partial` (async) or `lambda` (sync) callback; passing a template object -
  there is no compile/cache step, `render` takes the source string every time.

## Examples

### Synchronous rendering with partials

```dart
import 'package:tekartik_mustache/mustache_sync.dart';

void main() {
  var template = '''
<h1>{{title}}</h1>
{{>header2}}
<p>{{text}}</p>
<ul>{{#list}}
  <li>{{name}}</li>
{{/list}}</ul>
''';
  var partials = {'header2': '<h2>{{subtitle}}</h2>'};

  var text = render(
    template,
    {
      'title': 'Hello',
      'subtitle': 'Some description',
      'text': 'World',
      'list': [
        {'name': 'John'},
        {'name': 'Marie'},
      ],
    },
    lambda: (name) => partials[name],
  );
  print(text);
}
```

### Asynchronous rendering with a partial resolver

```dart
import 'package:tekartik_mustache/mustache.dart';

Future<void> main() async {
  var partials = <String, String>{
    'greeting': 'Hello {{name}}!{{>signature}}',
    'signature': ' -- {{author}}',
  };

  var result = await render(
    '{{>greeting}}',
    {'name': 'world', 'author': 'me'},
    partial: (name, context) async {
      // Could read a file or a database here.
      return partials[name];
    },
  );
  print(result); // Hello world! -- me
}
```

### Partial context: resolving partials relatively

```dart
import 'package:tekartik_mustache/mustache.dart';

/// [dir] is the directory of the top level template, each partial sets its own
/// directory as user data for the partials it includes.
Future<String?> renderInDir(
  String source,
  Map<String, Object?> values,
  String dir,
  Future<String?> Function(String path) readTemplate,
) async {
  return await render(
    source,
    values,
    partialContext: PartialContext(dir),
    partial: (name, context) async {
      var parentDir = context.parent!.userData as String;
      var path = '$parentDir/$name';
      // Partials included by this one resolve against its own directory.
      context.userData = path.substring(0, path.lastIndexOf('/'));
      return await readTemplate(path);
    },
  );
}
```

### Lambdas, sections and escaping

```dart
import 'package:tekartik_mustache/mustache.dart';

Future<void> main() async {
  var values = <String, Object?>{
    'name': '<b>me</b>',
    // Variable lambda: called with the key, result is rendered then escaped.
    'shout': (String key) async => 'HELLO {{name}}',
    // Section lambda: called with the raw inner source.
    'wrap': (String inner) => '[$inner]',
    'items': [
      {'label': 'one'},
      {'label': 'two'},
    ],
    'empty': <Object?>[],
  };

  print(await render('{{name}}', values)); // &lt;b&gt;me&lt;&#47;b&gt;
  print(await render('{{{name}}}', values)); // <b>me</b>
  print(await render('{{shout}}', values));
  print(await render('{{#wrap}}inner{{/wrap}}', values)); // [inner]
  print(await render('{{#items}}{{label}} {{/items}}', values)); // one two
  print(await render('{{^empty}}nothing{{/empty}}', values)); // nothing
  print(await render('{{=<% %>=}}<% name %>', values));
}
```
