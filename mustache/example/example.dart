import 'package:tekartik_mustache/mustache_sync.dart';

Future<void> main() async {
  var template = '''
<h1>{{title}}</h1>
{{>header2}}
<p>{{text}}</p>
<ul>{{#list}}
  <li>{{name}}</li>
{{/list}}</ul>
''';
  var parts = {'header2': '<h2>{{subtitle}}</h2>'};

  var text = render(template, {
    'title': 'Hello',
    'subtitle': 'Some description',
    'text': 'World',
    'list': [
      {'name': 'John'},
      {'name': 'Marie'}
    ]
  }, lambda: (String? name) {
    return parts[name];
  });
  print(text);
}
