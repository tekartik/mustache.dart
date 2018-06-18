import 'package:collection/collection.dart';
import 'package:tekartik_mustache/src/node.dart';
import 'package:tekartik_mustache/src/scanner.dart';

import 'source.dart';

bool isWhitespaces(String text) => text.trim().length == 0;
bool isLineFeed(String text) => text == nl || text == crnl;

// only valid for node text that always have line cut
bool hasLineFeed(String text) => text.endsWith(nl);

class Section {
  SectionNode node;

  Section._() {
    node = new SectionNode(null);
  }

  List<ParserNode> get nodes => node.nodes;

  Section(SectionStartNode startNode) {
    node = new SectionNode(new VariableNode(startNode.text),
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

    // standalone status
    for (var scannerNode in scannerNodes) {
      if (scannerNode is TextScannerNode) {
        addNode(new TextNode(scannerNode.text));
      } else if (scannerNode is MustacheScannerNode) {
        var text = scannerNode.text;
        String firstChar = scannerNode.text.substring(0, 1);

        // Return true if valie
        bool _trim(int start) {
          text = text.substring(start).trim();
          return text.length > 0;
        }

        switch (firstChar) {
          case '!':
            if (_trim(1)) {
              addNode(new CommentNode(text));
            }

            break;
          case '#':
            if (_trim(1)) {
              addNode(new SectionStartNode(text));
            }
            break;
          case '^':
            if (_trim(1)) {
              addNode(new SectionStartNode(text, inverted: true));
            }
            break;
          case '/':
            if (_trim(1)) {
              addNode(new SectionEndNode(text));
            }
            break;
          case '{':
            {
              var lastChar = text.substring(text.length - 1);
              if (lastChar == '}') {
                text = text.substring(1, text.length - 1);
              } else {
                text = text.substring(1);
              }
              if (_trim(0)) {
                addNode(new NoEscapeVariableNode(text));
              }
            }
            break;
          case '&':
            if (_trim(1)) {
              addNode(new NoEscapeVariableNode(text));
            }
            break;
          case '>':
            if (_trim(1)) {
              addNode(new PartialNode(text));
            }
            break;

          default:
            if (_trim(0)) {
              addNode(new VariableNode(text));
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
        var variableNode = new VariableNode(node.text);
        var variable = variableNode.name;
        // Find the section opened from the top of the stack
        // ignoring root
        for (int i = sections.length - 1; i > 0; i--) {
          var section = sections[i];
          if (section.variable.name == variable) {
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
  ParserNode(String text) : super(text);
}

class VariableNode extends ParserNode {
  VariableNode(String text) : super(text);

  @override
  int get hashCode => super.hashCode;

  String get name => text;

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
  NoEscapeVariableNode(String text) : super(text);

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
  CommentNode(String text) : super(text);

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is CommentNode && super == (other);
  }

  @override
  String toString() {
    return "Comment ${text}";
  }
}

class TextNode extends ParserNode {
  TextNode(String text) : super(text);

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

  SectionNode(this.variable, {this.inverted}) : super(null);

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

  SectionStartNode(String text, {this.inverted}) : super(text);
}

class SectionEndNode extends ParserNode {
  SectionEndNode(String text) : super(text);

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is SectionEndNode && super == (other);
  }
}

class PartialNode extends ParserNode {
  PartialNode(String text) : super(text);

  @override
  int get hashCode => super.hashCode;

  @override
  bool operator ==(other) {
    return other is PartialNode && super == (other);
  }

  @override
  String toString() {
    return "Partial ${super.toString()}";
  }
}

List<ParserNode> parse(String text) {
  if (text == null) {
    return null;
  }
  var source = new Parser(text);
  source.parse();
  return source.nodes;
}
