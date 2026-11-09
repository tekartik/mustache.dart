# tekartik_mustache

A small [Mustache](https://mustache.github.io/mustache.5.html) template
renderer in pure Dart: values come from a plain `Map` (no mirrors, no code
generation), partials are resolved by a callback (a map, files, a database) and
partials and lambdas can be asynchronous. It runs on every platform (Dart VM,
Flutter, browser with dart2js or dart2wasm, node).

## Getting started

The package is not on pub.dev, add it as a git dependency:

```yaml
dependencies:
  tekartik_mustache:
    git:
      url: https://github.com/tekartik/mustache.dart
      path: mustache
```

```dart
import 'package:tekartik_mustache/mustache.dart';

Future<void> main() async {
  var partials = {'item': '<li>{{name}}</li>'};
  var text = await render(
    '<h1>{{title}}</h1><ul>{{#items}}{{>item}}{{/items}}</ul>',
    {
      'title': 'Tom & Jerry',
      'items': [
        {'name': 'Tom'},
        {'name': 'Jerry'},
      ],
    },
    // Partials can be read from anywhere (map, file, database), async or not.
    partial: (name, context) => partials[name],
  );
  print(text); // <h1>Tom &amp; Jerry</h1><ul><li>Tom</li><li>Jerry</li></ul>

  // Synchronous variant, the partial resolver is called `lambda`.
  print(mustacheRenderSync('Hello {{name}}', {'name': 'world'})); // Hello world
}
```

## Which function

| Function                                                    | Import               | Use it to                                                              |
|-------------------------------------------------------------|----------------------|------------------------------------------------------------------------|
| `render(source, values, {partial, partialContext})`         | `mustache.dart`      | render with async partials and lambdas (returns a `Future<String?>`)   |
| `mustacheRenderSync(source, values, {lambda})`              | `mustache.dart`      | render synchronously (`lambda` resolves the partials)                  |
| `render(source, values, {lambda})`                          | `mustache_sync.dart` | same as `mustacheRenderSync`                                           |

Both `mustache.dart` and `mustache_sync.dart` export a function named
`render`: do not import both in one file (or use a prefix).

`PartialContext(userData)` passed as `partialContext` reaches the partial
resolver (`context.parent!.userData`), which is how partials are resolved
relatively (a partial including another one from its own directory).

## Template syntax

`{{name}}` (html escaped), `{{{name}}}` and `{{&name}}` (not escaped),
`{{#section}}...{{/section}}` (a map, a truthy value or once per list item),
`{{^inverted}}...{{/inverted}}`, `{{>partial}}`, `{{!comment}}`,
`{{=<% %>=}}` (delimiters), dotted names (`{{a.b}}`), `{{.}}` (the current list
item). A function value is a lambda: called with the key (`{{f}}`) or with the
raw section content (`{{#f}}...{{/f}}`). The mustache spec files of
`test/spec` pass with both renderers.

## Common pitfalls

* Section values must be maps, lists or simple values (`bool`, `String`,
  `num`): a `Set` or another object throws `UnsupportedError`. `''` and `0`
  are falsy.
* Inside the section of a simple value (`{{#name}}`), `{{.}}` is not that
  value: use `{{name}}`.
* The sync renderer throws `UnsupportedError` when a partial or a lambda
  returns a `Future`: use the async `render`.
* A missing partial (no resolver, or `null` returned) renders nothing.

## More

* [example/example.dart](example/example.dart).
* Agent skill: [skills/tekartik-mustache-render](skills/tekartik-mustache-render/SKILL.md).
* `tekartik_mustache_fs` in the same repo renders templates stored in files
  (local or Firebase storage).
