import 'dart:async';
import 'dart:convert';

import 'package:tekartik_mustache/src/node.dart';
import 'package:tekartik_mustache/src/parser.dart';

import 'import.dart';

class Renderer {
  final String source;
  Map<String, dynamic> values;
  Renderer parent;

  List<ParserNode> nodes;
  int currentNodeIndex;

  ParserNode getNodeAtOffset(int offset) {
    int index = currentNodeIndex + offset;
    if (index >= 0 && index < nodes.length) {
      return nodes[index];
    }
    return null;
  }

  ParserNode get currentNode => nodes[currentNodeIndex];

  ParserNode get nextNode => getNodeAtOffset(1);

  ParserNode get previousNode => getNodeAtOffset(-1);

  Renderer(this.source);

  var sb = new StringBuffer();

  PartialResolver partialResolver;

  void _writeText(String text) {
    sb.write(text);
  }

  dynamic getRawVariableValue(VariableNode variable, {bool recursive: true}) {
    var key = variable.name;

    // Non dotted?
    if (_hasRawKey(key)) {
      return _getRawKeyValue(key);
    }

    var parts = key.split("\.");
    if (parts.length > 1) {
      if (_hasDottedKey(parts)) {
        return _getDottedKeyValue(parts);
      }

      // If it contains the first part resolve

      if (_hasRawKey(parts[0])) {
        return _getDottedKeyValue(parts);
      }
    }

    if (recursive) {
      return parent?.getRawVariableValue(variable, recursive: recursive);
    }

    return null;
  }

  Future fixValue(VariableNode node, String key, dynamic value) async {
    if (value is String) {
      if (node is NoEscapeVariableNode) {
        return value;
      } else {
        // escape
        return htmlEscape.convert(value);
      }
    } else if (value is Function) {
      var result = await value(key) as String;
      if (result != null) {
        var renderer = new Renderer(result)
          ..values = values
          ..partialResolver = partialResolver;
        result = await renderer.render();
        // escape
        result = await fixValue(node, key, result) as String;
      }
      return result;
    } else {
      return value;
    }
  }

  Future getVariableValue(VariableNode variable, {bool recursive: true}) async {
    var node = variable;
    var key = variable.name;

    dynamic _fixValue(value) {
      return fixValue(node, key, value);
    }

    // Non dotted?
    if (_hasRawKey(key)) {
      return await _fixValue(_getRawKeyValue(key));
    }

    var parts = key.split("\.");
    if (parts.length > 1) {
      if (_hasDottedKey(parts)) {
        return await _fixValue(_getDottedKeyValue(parts));
      }

      // If it contains the first part resolve

      if (_hasRawKey(parts[0])) {
        return _getDottedKeyValue(parts);
      }
    }

    if (recursive) {
      return await parent?.getVariableValue(variable, recursive: recursive);
    }

    return null;
  }

  bool _hasRawKey(String key) {
    return values.containsKey(key);
  }

  bool _hasDottedKey(List<String> parts) {
    bool has = true;
    Map<String, dynamic> map = values;
    for (var part in parts) {
      if (map?.containsKey(part) == true) {
        var value = map[part];
        if (value is Map) {
          map = value.cast<String, dynamic>();
        } else {
          // this will make the next step fail
          map = null;
        }
      } else {
        has = false;
        break;
      }
    }
    return has;
  }

  dynamic _getDottedKeyValue(List<String> parts) {
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
      return value;
    } else {
      return null;
    }
  }

  dynamic _getRawKeyValue(String key) {
    return values[key];
  }

  void renderTextNode(TextNode node) {
    var text = node.text;
    _writeText(text);
  }

  Future _renderVariableNode(VariableNode node) async {
    var value = await getVariableValue(node);
    if (value != null) {
      _writeText(value.toString());
    }
  }

  Renderer nestedRenderer(String source) {
    var renderer = new Renderer(source ?? this.source)
      ..partialResolver = partialResolver
      ..parent = this;

    return renderer;
  }

  // when returning
  void fromNestedRendered(Renderer renderer) {}

  Future renderChildNodes(List<ParserNode> nodes, Map<String, dynamic> values,
      {String source}) async {
    // var previousHasTemplateOnCurrentLine = hasTemplateOnCurrentLine;
    var renderer = nestedRenderer(source)..values = values;
    var subResult = await renderer.renderNodes(nodes);
    fromNestedRendered(renderer);
    if (subResult.length > 0) {
      _writeText(subResult);
    }
  }

  Future<String> renderNodes(List<ParserNode> nodes) async {
    await _renderNodes(nodes);
    return sb.toString();
  }

  Future _renderPartialNode(PartialNode node) async {
    // find current indentation
    var previousNode = this.previousNode;
    var indent;
    if (previousNode is TextNode) {
      var text = previousNode.text;
      if (isInlineWhitespaces(text)) {
        // Ensure previous one was ending a line
        if (nodeNullOrHasLineFeed(getNodeAtOffset(-2))) {
          indent = text;
        }
      }
    }
    String template = await partialResolver(node.text);
    if (template != null) {
      bool endsWithLineFeed = hasLineFeed(template);
      // reindent the template
      // Keeping whether it has a last line
      var sb = new StringBuffer();
      var lines = LineSplitter.split(template).toList();

      // First line don't indent
      sb.write(lines.first);

      _indent() {
        if (indent != null) {
          sb.write(indent);
        }
      }

      // Next indent
      if (lines.length > 1) {
        // finish first
        sb.writeln();
        for (int i = 1; i < lines.length - 1; i++) {
          _indent();
          sb.writeln(lines[i]);
        }
        _indent();
        sb.write(lines.last);
      }

      // last re-add line feed or not
      if (endsWithLineFeed) {
        sb.writeln();
      }
      template = sb.toString();

      var nodes = parse(template);
      await renderChildNodes(nodes, {}, source: template);
    }
  }

  Future _renderNodes(List<ParserNode> nodes) async {
    this.nodes = nodes;
    for (currentNodeIndex = 0;
        currentNodeIndex < nodes.length;
        currentNodeIndex++) {
      var node = currentNode;

      if (node is SectionNode) {
        var value = await getRawVariableValue(node.variable);
        var key = node.key;

        if (value is Function) {
          // section lambda
          key = "inner";
          var result = await fixValue(node.variable, key, value) as String;
          _writeText(result);
          /*
          var nodes = parse(template);
          await renderChildNodes(nodes, {}, source: template);
          */
        } else {
          value = await fixValue(node.variable, node.key, value);
        }

        if (node.inverted == true) {
          if ((value == null || value == false) ||
              (value is List && value.isEmpty)) {
            await renderChildNodes(node.nodes, {});
          }
        } else {
          if (value == null || value == false) {
            // ignore
          } else if (isPositiveValue(value)) {
            await renderChildNodes(node.nodes, {});
          } else if (value is Map) {
            await renderChildNodes(node.nodes, value.cast<String, dynamic>());
          } else if (value is List) {
            for (var item in value) {
              Map<String, dynamic> values;
              if (!(item is Map)) {
                values = {'.': item};
              } else {
                values = (item as Map).cast<String, dynamic>();
              }
              await renderChildNodes(node.nodes, values);
            }
          } else if (value is Function) {
          } else {
            throw new UnsupportedError(
                "value $value (${value.runtimeType}) node $node");
          }
        }
      } else if (node is PartialNode) {
        await _renderPartialNode(node);
      } else if (node is TextNode) {
        renderTextNode(node);
      } else if (node is VariableNode) {
        await _renderVariableNode(node);
      } else {
        throw new UnimplementedError("_renderNode $node");
      }
    }
  }

  Future<String> render() async {
    values ??= {};
    var nodes = parse(source);
    return await renderNodes(nodes);
  }
}

/// The main entry point
Future<String> render(String source, Map<String, dynamic> values,
    {PartialResolver partial}) async {
  if (source == null) {
    return null;
  }
  var renderer = new Renderer(source)
    ..values = values
    ..partialResolver = partial;
  return await renderer.render();
}

typedef FutureOr<String> PartialResolver(String name);
typedef FutureOr<String> Lambda(String name);

bool nodeNullOrHasLineFeed(Node node) =>
    node == null || node is TextNode && (hasLineFeed(node.text));
