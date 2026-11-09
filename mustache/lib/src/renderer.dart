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

  /// The renderer holding [variable] (this one or a parent) and its raw
  /// value, null if not found.
  (Renderer, Object?)? _lookup(VariableNode variable, {bool recursive = true}) {
    var key = variable.name;

    // Non dotted?
    if (_hasRawKey(key)) {
      return (this, _getRawKeyValue(key));
    }

    var parts = key!.split('.');
    if (parts.length > 1) {
      if (_hasDottedKey(parts)) {
        return (this, _getDottedKeyValue(parts));
      }

      // If it contains the first part resolve (to null, no fix)
      if (_hasRawKey(parts[0])) {
        return (this, null);
      }
    }

    if (recursive) {
      return parent?._lookup(variable, recursive: recursive);
    }

    return null;
  }

  Object? getRawVariableValue(VariableNode variable, {bool recursive = true}) =>
      _lookup(variable, recursive: recursive)?.$2;

  /// Renders a lambda result in the context of the renderer holding the
  /// lambda (its values and parents).
  Renderer _lambdaResultRenderer() => Renderer()
    ..values = values
    ..parent = parent
    ..partial = partial
    ..partialContext = partialContext;

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
        var renderer = _lambdaResultRenderer();
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
        var renderer = _lambdaResultRenderer();
        result = renderer.renderSync(result);
        // escape
        result = fixValueSync(node, key, result) as String?;
      }
      return result;
    } else {
      return value;
    }
  }

  /// The value fixed (escaped, lambda called) by the renderer holding it.
  Future getVariableValue(
    VariableNode variable, {
    bool recursive = true,
  }) async {
    var found = _lookup(variable, recursive: recursive);
    if (found == null) {
      return null;
    }
    var (renderer, value) = found;
    return await renderer.fixValue(variable, variable.name, value);
  }

  Object? getVariableValueSync(VariableNode variable, {bool recursive = true}) {
    var found = _lookup(variable, recursive: recursive);
    if (found == null) {
      return null;
    }
    var (renderer, value) = found;
    return renderer.fixValueSync(variable, variable.name, value);
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
    var renderer = Renderer()
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

  /// The indentation of a standalone partial tag (null if none).
  String? _partialIndent() {
    var previousNode = this.previousNode;
    if (previousNode is TextNode) {
      var text = previousNode.text!;
      if (isInlineWhitespaces(text)) {
        // Ensure previous one was ending a line
        if (nodeNullOrHasLineFeed(getNodeAtOffset(-2))) {
          return text;
        }
      }
    }
    return null;
  }

  /// Reindent the partial [template], keeping whether it has a last line.
  static String _reindent(String template, String? indent) {
    // An empty partial has no line.
    if (template.isEmpty) {
      return template;
    }
    final endsWithLineFeed = hasLineFeed(template);
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
    return sb.toString();
  }

  Future<void> _renderPartialNode(PartialNode node) async {
    var indent = _partialIndent();
    var partialContext = RendererPartialContext(this.partialContext);
    var nodeText = node.text;
    if (nodeText != null) {
      var template = await partial?.call(nodeText, partialContext);

      if (template != null) {
        var nodes = parse(_reindent(template, indent))!;
        await renderChildNodes(nodes, {}, partialContext: partialContext);
      }
    }
  }

  void _renderPartialNodeSync(PartialNode node) {
    var indent = _partialIndent();
    var nodeText = node.text;
    if (nodeText != null) {
      var template = callPartialSync(nodeText);

      if (template != null) {
        var nodes = parse(_reindent(template, indent))!;
        renderChildNodesSync(nodes, {}, partialContext: partialContext);
      }
    }
  }

  /// The source text of a section lambda (the section content as is).
  String _sectionLambdaText(SectionNode node) {
    final keyStart = node.startNode!.sourceContent.end!;
    final keyEnd = node.endNode.sourceContent.start;
    return sourceGetText(
      node.startNode!.sourceContent.source!,
      keyStart,
      keyEnd,
    );
  }

  /// Parse a section lambda [result] with the section delimiters.
  List<ParserNode?> _sectionLambdaNodes(SectionNode node, String result) {
    var scanner = Scanner(result)..delimiter = node.startNode!.delimiter;
    scanner.scan();
    return parseScannerNodes(scanner.nodes)!;
  }

  /// The values to render the section children with, once per item (none
  /// when the section is skipped).
  static List<Map<String, dynamic>> _sectionValues(
    SectionNode node,
    Object? value,
  ) {
    if (node.inverted == true) {
      return _isFalsySectionValue(value) ? [{}] : [];
    }
    if (_isFalsySectionValue(value)) {
      return [];
    } else if (isPositiveValue(value)) {
      return [{}];
    } else if (value is Map) {
      return [value.cast<String, dynamic>()];
    } else if (value is List) {
      return [
        for (var item in value)
          if (item is! Map) {'.': item} else item.cast<String, dynamic>(),
      ];
    }
    throw UnsupportedError('value $value (${value.runtimeType}) node $node');
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

        if (value is Function) {
          // A lambda is truthy: an inverted section is skipped.
          if (node.inverted == true) {
            continue;
          }
          // section lambda, call it with the inner content as is
          // ignore: avoid_dynamic_calls
          var result = await value(_sectionLambdaText(node));

          if (result is String) {
            await renderChildNodes(_sectionLambdaNodes(node, result), values);
          }
          continue;
        }
        value = await fixValue(node.variable, node.key, value);
        for (var itemValues in _sectionValues(node, value)) {
          await renderChildNodes(node.nodes, itemValues);
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

        if (value is Function) {
          // A lambda is truthy: an inverted section is skipped.
          if (node.inverted == true) {
            continue;
          }
          // section lambda, call it with the inner content as is
          // ignore: avoid_dynamic_calls
          var result = value(_sectionLambdaText(node));

          if (result is String) {
            renderChildNodesSync(_sectionLambdaNodes(node, result), values);
          }
          continue;
        }
        value = fixValueSync(node.variable, node.key, value);
        for (var itemValues in _sectionValues(node, value)) {
          renderChildNodesSync(node.nodes, itemValues);
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

/// null, false, an empty list, an empty string or 0.
bool _isFalsySectionValue(Object? value) =>
    value == null ||
    value == false ||
    (value is List && value.isEmpty) ||
    ((value is String || value is num) && !isPositiveValue(value));

bool nodeNullOrHasLineFeed(Node? node) =>
    node == null || node is TextNode && (hasLineFeed(node.text!));

class RendererPartialContext implements PartialContext {
  @override
  final PartialParentContext? parent;

  @override
  Object? userData;

  RendererPartialContext(this.parent, [this.userData]);
}
