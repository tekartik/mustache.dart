import 'package:collection/collection.dart';
import 'package:tekartik_mustache/src/node.dart';
import 'package:tekartik_mustache/src/scanner.dart';

import 'source.dart';

bool isWhitespaces(String text) => text.trim().length == 0;

class Section {
  SectionNode node;

  Section._() {
    node = new SectionNode(null);
  }

  List<ParserNode> get nodes => node.nodes;

  Section(SectionStartNode startNode) {
    node = new SectionNode(new VariableNode(startNode.start, startNode.end),
        inverted: startNode.inverted);
  }

  VariableNode get variable => node.variable;

  void add(ParserNode node) {
    this.node.add(node);
  }
}

class RootSection extends Section {
  RootSection() : super._();

  VariableNode get variable => null;
}

/// parse [ScannerNode] as [ParserNode]
class Parser extends Object with SourceMixin {
  final String source;
  final List<ParserNode> nodes = [];

  String startDelimiter = '{{';

  Parser(this.source);

  void addNode(ParserNode node) {
    nodes.add(node);
  }

  void parse() {
    var scannerNodes = scan(source);

    for (var scannerNode in scannerNodes) {
      int start = scannerNode.start;
      int end = scannerNode.end;
      if (scannerNode is TextScannerNode) {
        addNode(new TextNode(start, end));
      } else if (scannerNode is MustacheScannerNode) {
        String firstChar = source.substring(start, start + 1);

        // Return true if valie
        bool _trim() {
          start = trimStart(start);
          end = trimEnd(end);
          return end > start;
        }

        switch (firstChar) {
          case '!':
            ++start;
            if (_trim()) {
              addNode(new CommentNode(start, end));
            }

            break;
          case '#':
            ++start;
            if (_trim()) {
              addNode(new SectionStartNode(start, end));
            }
            break;
          case '^':
            ++start;
            if (_trim()) {
              addNode(new SectionStartNode(start, end, inverted: true));
            }
            break;
          case '/':
            ++start;
            if (_trim()) {
              addNode(new SectionEndNode(start, end));
            }
            break;
          case '{':
            {
              var lastChar = source.substring(end - 1, end);
              if (lastChar == '}') {
                end--;
              }
              ++start;
              if (_trim()) {
                addNode(new NoEscapeVariableNode(start, end));
              }
            }
            break;
          case '&':
            ++start;
            if (_trim()) {
              addNode(new NoEscapeVariableNode(start, end));
            }
            break;
          default:
            if (_trim()) {
              addNode(new VariableNode(start, end));
            }
        }
      }
    }

    // Merge in sections
    // Handle white space before/after node
    var newNodes = <ParserNode>[];
    var sections = <Section>[new RootSection()];

    // no end line
    TextNode pendingWhiteSpaceNode;
    ParserNode previousNode;

    _addNode(ParserNode node) {
      previousNode = node;
      var section = sections.length > 0 ? sections.last : null;
      if (section != null) {
        section.add(node);
      } else {
        newNodes.add(node);
      }
    }

    for (var node in nodes) {
      if (node is SectionStartNode) {
        var section = new Section(node);
        // first add the node then the section
        _addNode(section.node);
        sections.add(section);
      } else if (node is SectionEndNode) {
        var variableNode = new VariableNode(node.start, node.end);
        var variable = getVariableName(variableNode);
        // Find the section opened from the top of the stack
        // ignoring root
        for (int i = sections.length - 1; i > 0; i--) {
          var section = sections[i];
          if (getVariableName(section.variable) == variable) {
            // truncate of the first found
            sections = sections.sublist(0, i);
            break;
          }
        }
      } else if (node is TextNode) {
        /*
        // Is it white space and no lines?
        var text = getText(node);
        if (!text.endsWith(nl) && _isWhitespaces(text)) {
          pendingWhiteSpaceNode = node;
        } else {
          // Don't add if previous was comment
          if (previousNode is CommentNode) {

          } else {
            _addNode(node);
          }
        }
        */
        _addNode(node);
      } else if (node is CommentNode) {
        // remove previous pending white space
        pendingWhiteSpaceNode = null;
        _addNode(node);
      } else {
        //throw new UnimplementedError(node.toString());
        _addNode(node);
      }
    }

    // Do we need to add the pending white space
    if (pendingWhiteSpaceNode != null) {
      if (previousNode is CommentNode) {
      } else {
        _addNode(pendingWhiteSpaceNode);
      }
      //}
    }

    nodes
      ..clear()
      ..addAll(sections[0].nodes);
  }
}

abstract class ParserNode extends Node {
  ParserNode(int start, int end) : super(start, end);
}

class VariableNode extends ParserNode {
  VariableNode(int start, int end) : super(start, end);

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is VariableNode && super == (other);
  }

  @override
  String toString() {
    return "Variable ${super.toString()}";
  }
}

class NoEscapeVariableNode extends VariableNode {
  NoEscapeVariableNode(int start, int end) : super(start, end);

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is NoEscapeVariableNode && super == (other);
  }

  @override
  String toString() {
    return "NoEscapeVariable ${super.toString()}";
  }
}

class CommentNode extends ParserNode {
  CommentNode(int start, int end) : super(start, end);

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is CommentNode && super == (other);
  }

  @override
  String toString() {
    return "Comment ${super.toString()}";
  }
}

class TextNode extends ParserNode {
  TextNode(int start, int end) : super(start, end);

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is TextNode && super == (other);
  }

  @override
  String toString() {
    return "Text ${super.toString()}";
  }
}

class SectionNode extends ParserNode {
  final VariableNode variable;
  final bool inverted;
  final List<ParserNode> nodes = [];

  SectionNode(this.variable, {this.inverted}) : super(null, null);

  void add(ParserNode node) {
    nodes.add(node);
  }

  @override
  int get hashCode => variable.hashCode;

  @override
  bool operator ==(other) {
    if (other is SectionNode) {
      if (other.variable == variable) {
        if (const ListEquality().equals(other.nodes, nodes)) {
          return true;
        }
      }
    }
    return false;
  }

  @override
  String toString() {
    return "Section: ${variable} ${nodes}";
  }
}

class SectionStartNode extends ParserNode {
  final bool inverted;

  SectionStartNode(int start, int end, {this.inverted}) : super(start, end);
}

class SectionEndNode extends ParserNode {
  SectionEndNode(int start, int end) : super(start, end);
}

List<ParserNode> parse(String text) {
  if (text == null) {
    return null;
  }
  var source = new Parser(text);
  source.parse();
  return source.nodes;
}
