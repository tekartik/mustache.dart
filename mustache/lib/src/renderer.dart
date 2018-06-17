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

class SourceVariable extends SourceNode<VariableNode> {
  SourceVariable(String source, VariableNode node) : super(source, node);

  String get name => getVariableName(node);
}

class SourceNode<T extends ParserNode> extends Object with SourceMixin {
  @override
  final String source;
  final T node;

  SourceNode(this.source, this.node);
}

class SourceText extends SourceNode<TextNode> {
  SourceText(String source, TextNode node) : super(source, node);

  String get text => getText(node);
}

class Renderer extends Object with SourceMixin {
  final String source;
  Map<String, dynamic> values;
  Renderer parent;

  Renderer(this.source);

  var sb = new StringBuffer();

  // no end line
  SourceText pendingWhiteSpaceNode;

  bool hasContentOnCurrentLine = false;
  bool hasTemplateOnCurrentLine = false;
  PartialResolver partialResolver;

  /*
  _writeNode(ParserNode node, String text) {
    previousNode = node;
    _writeText(text);
  }
  */

  _doWriteText(String text) {
    sb.write(text);
    if (hasLineFeed(text)) {
      hasContentOnCurrentLine = false;
      hasTemplateOnCurrentLine = false;
    } else {
      hasContentOnCurrentLine = hasContentOnCurrentLine || text.length > 0;
    }
  }

  _writeText(String text) {
    if (pendingWhiteSpaceNode != null) {
      _doWriteText(pendingWhiteSpaceNode.text);
      pendingWhiteSpaceNode = null;
    }
    _doWriteText(text);
  }

  dynamic getVariableValue(SourceVariable variable, {bool recursive: true}) {
    var node = variable.node;
    var key = variable.name;

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

    // Non dotted?
    if (_hasRawKey(key)) {
      return _fixValue(_getRawKeyValue(key));
    }

    var parts = key.split("\.");
    if (parts.length > 1) {
      if (_hasDottedKey(parts)) {
        return _fixValue(_getDottedKeyValue(parts));
      }

      // If it contains the first part resolve

      if (_hasRawKey(parts[0])) {
        return _getDottedKeyValue(parts);
      }
    }

    if (recursive) {
      return parent?.getVariableValue(variable, recursive: recursive);
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

  _renderBasicNode(ParserNode node) {
    //var previousNode = this.previousNode;
    // this.previousNode = node;

    var text = getText(node);
    if (node is TextNode) {
      bool whitespacesOnly = isWhitespaces(text);
      if (!text.endsWith(nl) && whitespacesOnly) {
        // Write existing pending one first
        if (pendingWhiteSpaceNode != null) {
          _writeText("");
        }
        pendingWhiteSpaceNode = new SourceText(source, node);
      } else {
        // We we know that we have either content or ending with a lf
        // line feed only?
        if (isLineFeed(text)) {
          if (!hasContentOnCurrentLine) {
            // nope and discard
            pendingWhiteSpaceNode = null;
            hasTemplateOnCurrentLine = false;
            return;
          }
        }

        _writeText(text);
      }
    } else if (node is VariableNode) {
      var value = getVariableValue(new SourceVariable(source, node));
      if (value != null) {
        _writeText(value.toString());
      }
    } else if (node is CommentNode) {
      if (!hasContentOnCurrentLine && !hasTemplateOnCurrentLine) {
        //ok ignore
        pendingWhiteSpaceNode = null;
      }
    } else {
      throw new UnimplementedError("_renderBasicNode $node");
    }
  }

  Renderer nestedRenderer(String source) {
    var renderer = new Renderer(source ?? this.source)
      ..partialResolver = partialResolver
      ..hasTemplateOnCurrentLine = true
      ..pendingWhiteSpaceNode = pendingWhiteSpaceNode
      ..hasContentOnCurrentLine = hasContentOnCurrentLine
      ..parent = this;
    return renderer;
  }

  // when returning
  void fromNestedRendered(Renderer renderer) {
    hasContentOnCurrentLine = renderer.hasContentOnCurrentLine;
    hasTemplateOnCurrentLine = renderer.hasTemplateOnCurrentLine;
  }

  Future renderChildNodes(List<ParserNode> nodes, Map<String, dynamic> values,
      {String source}) async {
    // var previousHasTemplateOnCurrentLine = hasTemplateOnCurrentLine;
    var renderer = nestedRenderer(source)..values = values;
    var subResult = await renderer.renderNodes(nodes);
    fromNestedRendered(renderer);
    pendingWhiteSpaceNode = null;
    if (subResult.length > 0) {
      _writeText(subResult);
    }
    pendingWhiteSpaceNode = renderer.pendingWhiteSpaceNode;
    // hasTemplateOnCurrentLine = previousHasTemplateOnCurrentLine;
  }

  Future<String> renderNodes(List<ParserNode> nodes) async {
    await _renderNodes(nodes);
    // Do we need to add the pending white space
    if (pendingWhiteSpaceNode != null) {
      if (!hasContentOnCurrentLine && !hasTemplateOnCurrentLine) {
        // do not write
      } else {
        var text = pendingWhiteSpaceNode.text;
        pendingWhiteSpaceNode = null;
        _writeText(text);
      }
      //}
    }

    return sb.toString();
  }

  Future _renderNodes(List<ParserNode> nodes) async {
    for (var node in nodes) {
      if (!hasTemplateOnCurrentLine) {
        hasTemplateOnCurrentLine = (!(node is TextNode)) &&
            (!(node is CommentNode) && (!(node is PartialNode)));
      }

      if (node is SectionNode) {
        var value = getVariableValue(new SourceVariable(source, node.variable));
        if (node.inverted == true) {
          if ((value == null || value == false) ||
              (value is List && value.isEmpty)) {
            await renderChildNodes(node.nodes, {});
          }
        } else {
          if (value == null || value == false) {
            // ignore
          } else if (value == true) {
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
          } else {
            throw new UnsupportedError("value $value $node");
          }
        }
      } else if (node is PartialNode) {
        String template = await partialResolver(getText(node));
        if (template != null) {
          var nodes = parse(template);
          await renderChildNodes(nodes, {}, source: template);
        }
      } else {
        _renderBasicNode(node);
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
