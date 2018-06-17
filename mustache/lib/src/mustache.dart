import 'dart:async';
import 'dart:convert';

import 'package:tekartik_mustache/src/node.dart';
import 'package:tekartik_mustache/src/parser.dart';
import 'package:tekartik_mustache/src/scanner.dart';
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

  // no end line
  TextNode pendingWhiteSpaceNode;
  ParserNode previousNode;

  /*
  _writeNode(ParserNode node, String text) {
    previousNode = node;
    _writeText(text);
  }
  */

  _writeText(String text) {
    if (pendingWhiteSpaceNode != null) {
      sb.write(getText(pendingWhiteSpaceNode));
      pendingWhiteSpaceNode = null;
    }
    sb.write(text);
  }

  dynamic getVariableValue(VariableNode node) {
    var text = getVariableName(node);

    T _fixValue<T>(T value) {
      if (value is String) {
        if (node is NoEscapeVariableNode) {
          return value;
        } else {
          // escape
          return htmlEscape.convert(value) as T;
        }
      } else {
        return value;
      }
    }

    if (values.containsKey(text)) {
      return _fixValue(values[text]);
    } else {
      // try dotted case
      var parts = text.split("\.");
      if (parts.length > 1) {
        bool contains = true;
        var value;
        Map<String, dynamic> map = values;
        for (var part in parts) {
          if (map?.containsKey(part) == true) {
            value = map[part];
            if (value is Map) {
              map = value.cast<String, dynamic>();
            } else {
              // this will make the next step fail
              map = null;
            }
          } else {
            contains = false;
            break;
          }
        }
        if (contains) {
          return _fixValue(value);
        }
      }

      return parent?.getVariableValue(node);
    }
  }

  _renderBasicNode(ParserNode node) {
    var previousNode = this.previousNode;
    this.previousNode = node;
    var text = getText(node);
    if (node is TextNode) {
      bool whitespacesOnly = isWhitespaces(text);
      if (!text.endsWith(nl) && whitespacesOnly) {
        pendingWhiteSpaceNode = node;
      } else {
        if (whitespacesOnly) {
          if (previousNode is CommentNode) {
            // nope
            return;
          }
        }
        _writeText(text);
      }
    } else if (node is VariableNode) {
      var value = getVariableValue(node);
      if (value != null) {
        _writeText(value.toString());
      }
    } else if (node is CommentNode) {
      //ok ignore
      pendingWhiteSpaceNode = null;
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
            throw new UnsupportedError("value $value $node");
          }
        }
      } else {
        _renderBasicNode(node);
      }
    }

    // Do we need to add the pending white space
    if (pendingWhiteSpaceNode != null) {
      if (previousNode is CommentNode) {
        // do not write
      } else {
        var text = getText(pendingWhiteSpaceNode);
        pendingWhiteSpaceNode = null;
        _writeText(text);
      }
      //}
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
