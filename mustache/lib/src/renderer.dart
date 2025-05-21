import 'dart:convert';

import 'package:tekartik_mustache/src/mustache.dart';
import 'package:tekartik_mustache/src/node.dart';
import 'package:tekartik_mustache/src/parser.dart';
import 'package:tekartik_mustache/src/scanner.dart';
import 'package:tekartik_mustache/src/source.dart';

import 'import.dart';

class Renderer {
  Map<String, Object?>? values;
  Renderer? parent;
  PartialResolver? partial;
  PartialContext? partialContext;

  String? callLambdaSync(String name) {
    return callPartialSync(name);
  }

  String? callPartialSync(String name) {
    if (partial == null) {
      return null;
    }
    var result = partial!(name, RendererPartialContext(partialContext));
    if (result is String) {
      return result;
    }
    if (result is Future) {
      throw UnsupportedError('Future not supported');
    }
    if (result == null) {
      return null;
    }
    throw UnsupportedError('$result not supported');
  }

  late List<ParserNode?> nodes;
  int? currentNodeIndex;

  ParserNode? getNodeAtOffset(int offset) {
    final index = currentNodeIndex! + offset;
    if (index >= 0 && index < nodes.length) {
      return nodes[index];
    }
    return null;
  }

  ParserNode? get currentNode => nodes[currentNodeIndex!];

  ParserNode? get nextNode => getNodeAtOffset(1);

  ParserNode? get previousNode => getNodeAtOffset(-1);

  var sb = StringBuffer();

  void _writeText(String? text) {
    sb.write(text);
  }

  Object? getRawVariableValue(VariableNode variable, {bool recursive = true}) {
    var key = variable.name;

    // Non dotted?
    if (_hasRawKey(key)) {
      return _getRawKeyValue(key);
    }

    var parts = key!.split('.');
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

  Future fixValue(VariableNode? node, String? key, dynamic value) async {
    if (value is String) {
      if (node is NoEscapeVariableNode) {
        return value;
      } else {
        // escape
        return htmlEscape.convert(value);
      }
    } else if (value is Function) {
      // ignore: avoid_dynamic_calls
      var result = await value(key);
      if (result is bool) {
        throw UnsupportedError('TODO');
      } else if (result is String) {
        var renderer =
            Renderer()
              ..values = values
              ..partial = partial;
        result = await renderer.render(result);
        // escape
        result = await fixValue(node, key, result) as String?;
      }
      return result;
    } else {
      return value;
    }
  }

  Object? fixValueSync(VariableNode? node, String? key, Object? value) {
    if (value is String) {
      if (node is NoEscapeVariableNode) {
        return value;
      } else {
        // escape
        return htmlEscape.convert(value);
      }
    } else if (value is Function) {
      // ignore: avoid_dynamic_calls
      var result = value(key);
      if (result is bool) {
        throw UnsupportedError('bool not supported');
      } else if (result is Future) {
        throw UnsupportedError('Future not supported');
      } else if (result is String) {
        var renderer =
            Renderer()
              ..values = values
              ..partial = partial;
        result = renderer.renderSync(result);
        // escape
        result = fixValueSync(node, key, result) as String?;
      }
      return result;
    } else {
      return value;
    }
  }

  Future getVariableValue(
    VariableNode variable, {
    bool recursive = true,
  }) async {
    var node = variable;
    var key = variable.name;

    Object? varFixValue(Object? value) {
      return fixValue(node, key, value);
    }

    // Non dotted?
    if (_hasRawKey(key)) {
      return varFixValue(_getRawKeyValue(key));
    }

    var parts = key!.split('.');
    if (parts.length > 1) {
      if (_hasDottedKey(parts)) {
        return varFixValue(_getDottedKeyValue(parts));
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

  Object? getVariableValueSync(VariableNode variable, {bool recursive = true}) {
    var node = variable;
    var key = variable.name;

    Object? varFixValue(Object? value) {
      return fixValueSync(node, key, value);
    }

    // Non dotted?
    if (_hasRawKey(key)) {
      return varFixValue(_getRawKeyValue(key));
    }

    var parts = key!.split('.');
    if (parts.length > 1) {
      if (_hasDottedKey(parts)) {
        return varFixValue(_getDottedKeyValue(parts));
      }

      // If it contains the first part resolve

      if (_hasRawKey(parts[0])) {
        return _getDottedKeyValue(parts);
      }
    }

    if (recursive) {
      return parent?.getVariableValueSync(variable, recursive: recursive);
    }

    return null;
  }

  bool _hasRawKey(String? key) {
    return values!.containsKey(key);
  }

  bool _hasDottedKey(List<String> parts) {
    var has = true;
    var map = values;
    for (var part in parts) {
      if (map?.containsKey(part) == true) {
        var value = map![part];
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

  Object? _getDottedKeyValue(List<String> parts) {
    var contains = true;
    Object? value;
    var map = values;
    for (var part in parts) {
      if (map?.containsKey(part) == true) {
        value = map![part];
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

  Object? _getRawKeyValue(String? key) {
    return values![key!];
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

  void _renderVariableNodeSync(VariableNode node) {
    var value = getVariableValueSync(node);
    if (value != null) {
      _writeText(value.toString());
    }
  }

  Renderer nestedRenderer({PartialContext? partialContext}) {
    var renderer =
        Renderer()
          ..partial = partial
          ..partialContext = partialContext ?? this.partialContext
          ..parent = this;

    return renderer;
  }

  // when returning
  void fromNestedRendered(Renderer renderer) {}

  Future<void> renderChildNodes(
    List<ParserNode?> nodes,
    Map<String, dynamic>? values, {
    PartialContext? partialContext,
  }) async {
    // var previousHasTemplateOnCurrentLine = hasTemplateOnCurrentLine;
    var renderer = nestedRenderer(partialContext: partialContext)
      ..values = values;
    var subResult = await renderer.renderNodes(nodes);
    fromNestedRendered(renderer);
    if (subResult.isNotEmpty) {
      _writeText(subResult);
    }
  }

  void renderChildNodesSync(
    List<ParserNode?> nodes,
    Map<String, dynamic>? values, {
    PartialContext? partialContext,
  }) {
    // var previousHasTemplateOnCurrentLine = hasTemplateOnCurrentLine;
    var renderer = nestedRenderer(partialContext: partialContext)
      ..values = values;
    var subResult = renderer.renderNodesSync(nodes);
    fromNestedRendered(renderer);
    if (subResult.isNotEmpty) {
      _writeText(subResult);
    }
  }

  Future<String> renderNodes(List<ParserNode?> nodes) async {
    await _renderNodes(nodes);
    return sb.toString();
  }

  String renderNodesSync(List<ParserNode?> nodes) {
    _renderNodesSync(nodes);
    return sb.toString();
  }

  Future<void> _renderPartialNode(PartialNode node) async {
    // find current indentation
    var previousNode = this.previousNode;
    String? indent;
    if (previousNode is TextNode) {
      var text = previousNode.text!;
      if (isInlineWhitespaces(text)) {
        // Ensure previous one was ending a line
        if (nodeNullOrHasLineFeed(getNodeAtOffset(-2))) {
          indent = text;
        }
      }
    }
    var partialContext = RendererPartialContext(this.partialContext);
    var nodeText = node.text;
    if (nodeText != null) {
      var template = await partial!(nodeText, partialContext);

      if (template != null) {
        final endsWithLineFeed = hasLineFeed(template);
        // reindent the template
        // Keeping whether it has a last line
        var sb = StringBuffer();
        var lines = LineSplitter.split(template).toList();

        // First line don't indent
        sb.write(lines.first);

        void doIndent() {
          if (indent != null) {
            sb.write(indent);
          }
        }

        // Next indent
        if (lines.length > 1) {
          // finish first
          sb.writeln();
          for (var i = 1; i < lines.length - 1; i++) {
            doIndent();
            sb.writeln(lines[i]);
          }
          doIndent();
          sb.write(lines.last);
        }

        // last re-add line feed or not
        if (endsWithLineFeed) {
          sb.writeln();
        }
        template = sb.toString();

        var nodes = parse(template)!;
        await renderChildNodes(nodes, {}, partialContext: partialContext);
      }
    }
  }

  void _renderPartialNodeSync(PartialNode node) {
    // find current indentation
    var previousNode = this.previousNode;
    String? indent;
    if (previousNode is TextNode) {
      var text = previousNode.text!;
      if (isInlineWhitespaces(text)) {
        // Ensure previous one was ending a line
        if (nodeNullOrHasLineFeed(getNodeAtOffset(-2))) {
          indent = text;
        }
      }
    }

    var nodeText = node.text;
    if (nodeText != null) {
      var template = callPartialSync(nodeText);

      if (template != null) {
        final endsWithLineFeed = hasLineFeed(template);
        // reindent the template
        // Keeping whether it has a last line
        var sb = StringBuffer();
        var lines = LineSplitter.split(template).toList();

        // First line don't indent
        sb.write(lines.first);

        void doIndent() {
          if (indent != null) {
            sb.write(indent);
          }
        }

        // Next indent
        if (lines.length > 1) {
          // finish first
          sb.writeln();
          for (var i = 1; i < lines.length - 1; i++) {
            doIndent();
            sb.writeln(lines[i]);
          }
          doIndent();
          sb.write(lines.last);
        }

        // last re-add line feed or not
        if (endsWithLineFeed) {
          sb.writeln();
        }
        template = sb.toString();

        var nodes = parse(template)!;
        renderChildNodesSync(nodes, {}, partialContext: partialContext);
      }
    }
  }

  Future _renderNodes(List<ParserNode?> nodes) async {
    this.nodes = nodes;
    for (
      currentNodeIndex = 0;
      currentNodeIndex! < nodes.length;
      currentNodeIndex = currentNodeIndex! + 1
    ) {
      var node = currentNode;

      if (node is SectionNode) {
        var value = getRawVariableValue(node.variable!);
        var key = node.key;

        if (value is Function) {
          // section lambda
          // get the inner content as is
          final keyStart = node.startNode!.sourceContent.end!;
          final keyEnd = node.endNode.sourceContent.start;
          key = sourceGetText(
            node.startNode!.sourceContent.source!,
            keyStart,
            keyEnd,
          );

          // call the function
          // ignore: avoid_dynamic_calls
          var result = await value(key);

          if (result is String) {
            // parse it
            var scanner = Scanner(result)
              ..delimiter = node.startNode!.delimiter;
            scanner.scan();

            var parserNodes = parseScannerNodes(scanner.nodes)!;
            await renderChildNodes(parserNodes, values);
          }
          continue;
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
              if (item is! Map) {
                values = {'.': item};
              } else {
                values = item.cast<String, dynamic>();
              }
              await renderChildNodes(node.nodes, values);
            }
          } else {
            throw UnsupportedError(
              'value $value (${value.runtimeType}) node $node',
            );
          }
        }
      } else if (node is PartialNode) {
        await _renderPartialNode(node);
      } else if (node is TextNode) {
        renderTextNode(node);
      } else if (node is VariableNode) {
        await _renderVariableNode(node);
      } else {
        throw UnimplementedError('_renderNode $node');
      }
    }
  }

  void _renderNodesSync(List<ParserNode?> nodes) {
    this.nodes = nodes;
    for (
      currentNodeIndex = 0;
      currentNodeIndex! < nodes.length;
      currentNodeIndex = currentNodeIndex! + 1
    ) {
      var node = currentNode;

      if (node is SectionNode) {
        var value = getRawVariableValue(node.variable!);
        var key = node.key;

        if (value is Function) {
          // section lambda
          // get the inner content as is
          final keyStart = node.startNode!.sourceContent.end!;
          final keyEnd = node.endNode.sourceContent.start;
          key = sourceGetText(
            node.startNode!.sourceContent.source!,
            keyStart,
            keyEnd,
          );

          // call the function
          // ignore: avoid_dynamic_calls
          var result = value(key);

          if (result is String) {
            // parse it
            var scanner = Scanner(result)
              ..delimiter = node.startNode!.delimiter;
            scanner.scan();

            var parserNodes = parseScannerNodes(scanner.nodes)!;
            renderChildNodesSync(parserNodes, values);
          }
          continue;
        } else {
          value = fixValueSync(node.variable, node.key, value);
        }

        if (node.inverted == true) {
          if ((value == null || value == false) ||
              (value is List && value.isEmpty)) {
            renderChildNodesSync(node.nodes, {});
          }
        } else {
          if (value == null || value == false) {
            // ignore
          } else if (isPositiveValue(value)) {
            renderChildNodesSync(node.nodes, {});
          } else if (value is Map) {
            renderChildNodesSync(node.nodes, value.cast<String, dynamic>());
          } else if (value is List) {
            for (var item in value) {
              Map<String, dynamic> values;
              if (item is! Map) {
                values = {'.': item};
              } else {
                values = item.cast<String, dynamic>();
              }
              renderChildNodesSync(node.nodes, values);
            }
          } else {
            throw UnsupportedError(
              'value $value (${value.runtimeType}) node $node',
            );
          }
        }
      } else if (node is PartialNode) {
        _renderPartialNodeSync(node);
      } else if (node is TextNode) {
        renderTextNode(node);
      } else if (node is VariableNode) {
        _renderVariableNodeSync(node);
      } else {
        throw UnimplementedError('_renderNodeSync $node');
      }
    }
  }

  Future<String> render(String source) async {
    values ??= {};
    var nodes = parse(source)!;
    return await renderNodes(nodes);
  }

  String renderSync(String source) {
    values ??= {};
    var nodes = parse(source)!;
    return renderNodesSync(nodes);
  }
}

bool nodeNullOrHasLineFeed(Node? node) =>
    node == null || node is TextNode && (hasLineFeed(node.text!));

class RendererPartialContext implements PartialContext {
  @override
  final PartialParentContext? parent;

  @override
  Object? userData;

  RendererPartialContext(this.parent, [this.userData]);
}
