import 'dart:async';
import 'dart:convert';

import 'package:tekartik_mustache/src/node.dart';
import 'package:tekartik_mustache/src/parser.dart';
import 'package:tekartik_mustache/src/source.dart';

import 'import.dart';

String textAtNode(String source, Node node) {
  return source.substring(node.start, node.end);
}

class Renderer extends Object with SourceMixin {
  final String source;
  Map<String, dynamic> values;
  Renderer parent;

  Renderer(this.source);

  var sb = new StringBuffer();

  dynamic getVariableValue(VariableNode node) {
    var text = getVariableName(node);
    if (values.containsKey(text)) {
      return values[text];
    } else {
      return parent?.getVariableName(node);
    }
  }

  _renderBasicNode(ParserNode node) {
    var text = textAtNode(source, node);
    if (node is TextNode) {
      sb.write(text);
    } else if (node is VariableNode) {
      var value = getVariableValue(node);
      if (value != null) {
        // escape
        text = htmlEscape.convert(value.toString());
        sb.write(text);
      }
    } else if (node is CommentNode) {
      //ok ignore
    } else {
      throw new UnimplementedError("_renderBasicNode $node");
    }
  }

  Future<String> renderNodes(List<ParserNode> nodes) async {
    for (var node in nodes) {
      if (node is SectionNode) {
        var value = getVariableValue(node.variable);
        if (node.inverted == true) {
          if ((value == null || value == false) ||
              (value is List && value.isEmpty)) {
            var renderer = new Renderer(source)..values = {};
            var subResult = await renderer.renderNodes(node.nodes);
            sb.write(subResult);
          }
        } else {
          if (value == null || value == false) {
            // ignore
          } else if (value == true) {
            var renderer = new Renderer(source)..values = {};
            var subResult = await renderer.renderNodes(node.nodes);
            sb.write(subResult);
          } else if (value is Map) {
            var renderer = new Renderer(source)
              ..values = value.cast<String, dynamic>();
            var subResult = await renderer.renderNodes(node.nodes);
            sb.write(subResult);
          } else if (value is List) {
            for (var item in value) {
              var values = (item as Map).cast<String, dynamic>();

              var renderer = new Renderer(source)..values = values;
              var subResult = await renderer.renderNodes(node.nodes);
              sb.write(subResult);
            }
          } else {
            throw new UnsupportedError("$node");
          }
        }
      } else {
        _renderBasicNode(node);
      }
    }

    return sb.toString();
  }

  Future<String> render() async {
    values ??= {};
    var nodes = parse(source);
    return await renderNodes(nodes);
  }
}

Future<String> render(String source, Map<String, dynamic> values) async {
  if (source == null) {
    return null;
  }
  var renderer = new Renderer(source)..values = values;
  return await renderer.render();
}
