@TestOn('vm')
library tekartik_mustache.spec_test;

import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:tekartik_mustache/mustache.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

bool skipAll = true;
List<String> _filterFileBasenames;
List<String> get filterFileBasenames => _filterFileBasenames;
@deprecated
set filterFileBasenames(List<String> filterFileBasenames) =>
    _filterFileBasenames = filterFileBasenames;

void main() {
  var specsDir = Directory(join('test', 'spec'));
  specsDir.listSync().forEach((FileSystemEntity entity) {
    var filename = entity.path;
    if (entity is File && shouldRun(filename)) {
      var text = entity.readAsStringSync(encoding: utf8);
      _defineGroupFromFile(filename, text);
    }
  });
}

void _defineGroupFromFile(filename, String text) {
  var json = loadYaml(text);
  var tests = json['tests'];
  filename = filename.substring(filename.lastIndexOf('/') + 1);
  group("Specs of $filename", () {
    //Make sure that we reset the state of the Interpolation - Multiple Calls test
    //as for some reason dart can run the group more than once causing the test
    //to fail the second time it runs
    tearDown(() {
      _DummyCallableWithState callable =
          lambdas['Interpolation - Multiple Calls'];
      callable.reset();
    });

    tests.forEach((t) {
      var testDescription = StringBuffer(t['name']);
      testDescription.write(': ');
      testDescription.write(t['desc']);
      var template = t['template'] as String;
      var data = Map<String, dynamic>.from(t['data'] as Map);
      var templateOneline =
          template.replaceAll('\n', '\\n').replaceAll('\r', '\\r');
      var reason =
          StringBuffer("Could not render right '''$templateOneline'''");
      var expected = t['expected'];

      var partials = t['partials'] as Map;
      var partial = (String name, _context) {
        if (partials == null) {
          return null;
        }
        return partials[name] as String;
      };

      //swap the data.lambda with a dart real function
      if (data['lambda'] != null) {
        data['lambda'] = lambdas[t['name']];
      }
      reason.write(" with '$data'");

      if (partials != null) {
        reason.write(" and partial: $partials");
      }

      test(testDescription.toString(), () async {
        expect(await render(template, data, partial: partial), expected,
            reason: reason.toString());
      });
    });
  }, skip: skipAll);
}

bool shouldRun(String filename) {
  // filter out only .yml files
  if (!filename.endsWith('.yml')) {
    return false;
  }
  // Filter out specific files?
  if (filterFileBasenames != null) {
    String fileBasename = basenameWithoutExtension(filename);
    if (!filterFileBasenames.contains(fileBasename)) {
      return false;
    }
  }
  return true;
}

//Until we'll find a way to load a piece of code dynamically,
//we provide the lambdas at the test here
class _DummyCallableWithState {
  var _callCounter = 0;

  String call(arg) => "${++_callCounter}";

  void reset() => _callCounter = 0;
}

dynamic lambdas = {
  'Interpolation': (t) => 'world',
  'Interpolation - Expansion': (t) => '{{planet}}',
  'Interpolation - Alternate Delimiters': (t) => "|planet| => {{planet}}",
  'Interpolation - Multiple Calls': _DummyCallableWithState(),
  //function() { return (g=(function(){return this})()).calls=(g.calls||0)+1 }
  'Escaping': (t) => '>',
  'Section': (txt) => txt == "{{x}}" ? "yes" : "no",
  'Section - Expansion': (txt) => "$txt{{planet}}$txt",
  'Section - Alternate Delimiters': (txt) => "$txt{{planet}} => |planet|$txt",
  'Section - Multiple Calls': (t) => "__${t}__",
  'Inverted Section': (txt) => false
};
