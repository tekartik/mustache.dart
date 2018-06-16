import 'package:tekartik_mustache/src/node.dart';
import 'package:tekartik_mustache/src/parser.dart';
import 'package:tekartik_mustache/src/source.dart';
import 'dart:convert';
import 'import.dart';

import 'dart:async';

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

  _renderNode(ParserNode node) {
    var text = textAtNode(source, node);
    if (node is TextNode) {
      sb.write(text);
    } else if (node is VariableNode) {
      // escape
      text = htmlEscape.convert(values[text]?.toString());
      sb.write(text);
    }
  }

  Future<String> renderNodes(List<ParserNode> nodes) async {
    for (var node in nodes) {
      if (node is SectionNode) {
        var value = getVariableValue(node.variable);
        if (value == null || value == false) {
          // ignore
        } else if (value == true) {
          var renderer = new Renderer(source)..values = values;
          var subResult = await renderer.renderNodes(node.nodes);
          sb.write(subResult);
        }
      } else {
        var text = textAtNode(source, node);
        if (node is TextNode) {
          sb.write(text);
        } else if (node is VariableNode) {
          // escape
          text = htmlEscape.convert(values[text]?.toString());
          sb.write(text);
        }
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
