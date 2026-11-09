import 'dart:io';

import 'package:tekartik_mustache/mustache_sync.dart';

/// Prints:
/// ```html
/// <h1>Hello</h1>
/// <h2>Some description</h2>
/// <p>World</p>
/// <ul>
///   <li>John</li>
///   <li>Marie</li>
/// </ul>
/// ```
Future<void> main() async {
  // A line holding only a section or a partial tag (standalone) disappears.
  var template = '''
<h1>{{title}}</h1>
{{>header2}}
<p>{{text}}</p>
<ul>
{{#list}}
  <li>{{name}}</li>
{{/list}}
</ul>
''';
  var parts = {'header2': '<h2>{{subtitle}}</h2>\n'};

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
    // The sync partial resolver.
    lambda: (String? name) {
      return parts[name];
    },
  );
  stdout.write(text);
}
