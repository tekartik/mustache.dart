# tekartik_mustache_fs

Render Mustache template files with
[tekartik_mustache](../mustache/README.md): `renderFile` reads a template from
an [fs_shim](https://pub.dev/packages/fs_shim) file system, resolves its
`{{> partial }}` includes as files relative to the including file, and takes
its values from a map, a yaml or a json file. Works on the real file system
(Dart VM), in memory (everywhere) and on a Firebase Storage bucket.

## Getting started

Git package, not on pub.dev:

```yaml
dependencies:
  tekartik_mustache_fs:
    git:
      url: https://github.com/tekartik/mustache.dart
      path: mustache_fs
  fs_shim: any
```

```dart
import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_mustache_fs/mustache_fs.dart';

Future<void> main() async {
  var fs = newFileSystemMemory(); // or fileSystemIo (package:fs_shim/fs_io.dart)
  await fs.directory('templates').create();
  await fs.file('templates/page.html').writeAsString('<ul>{{> item}}</ul>');
  // Relative to templates/page.html.
  await fs
      .file('templates/item')
      .writeAsString('{{#items}}<li>{{name}}</li>{{/items}}');

  print(
    await renderFile(
      fs,
      'templates/page.html',
      values: {
        'items': [
          {'name': 'a'},
          {'name': 'b'},
        ],
      },
    ),
  ); // <ul><li>a</li><li>b</li></ul>
}
```

## When to use what

* `renderFile(fs, path, values: ...)`; or `yamlPath:` / `jsonPath:` to read the
  values from a file (ignored when `values` is given).
* `package:tekartik_mustache_fs/mustache_storage.dart`:
  `fileSystemStorage(bucket)` turns a `tekartik_firebase_storage` bucket into
  a (read/write only) file system, for templates stored in a bucket.

## Pitfalls

* A missing partial file fails the whole render (the error of the file
  system), it is not rendered empty.
* Paths use the separator of the file system (`/` in memory and on a bucket).

## Agent skills

`skills/tekartik-mustache-fs-render` (more examples).
