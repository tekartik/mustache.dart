import 'package:collection/collection.dart';
import 'package:tekartik_mustache/src/node.dart';
import 'package:tekartik_mustache/src/scanner.dart';
import 'import.dart';

class RootSection extends Section {
  RootSection() : super._();

  VariableNode get variable => null;
}

/// parse [ScannerNode] as [ParserNode]
class Phase1Parser {
  final String source;
  final List<ParserNode> nodes = [];

  Phase1Parser(this.source);

  void addNode(ParserNode node) {
    nodes.add(node);
  }

  // convert scanner node to parse node
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
          case '=':
            var lastChar = text.substring(text.length - 1);
            if (lastChar == '}') {
              text = text.substring(1, text.length - 1);
            } else {
              text = text.substring(1);
            }
            if (_trim(0)) {
              addNode(new DelimitersNode(text));
            }
            break;

          default:
            if (_trim(0)) {
              addNode(new VariableNode(text));
            }
        }
      }
    }
  }
}

class Section {
  SectionNode node;

  List<ParserNode> currentLineNodes = [];

  List<ParserNode> get nodes => node.nodes;

  Section._() {
    node = new SectionNode(null);
  }

  Section(SectionStartNode startNode) {
    node = new SectionNode(new VariableNode(startNode.text),
        inverted: startNode.inverted);
  }

  VariableNode get variable => node.variable;

  void add(ParserNode node) {
    this.node.add(node);
  }
}

// Handle standalone tags, remove comments
class Phase2Parser {
  final List<ParserNode> sourceNodes;
  List<ParserNode> nodes = [];

  List<ParserNode> currentLineNodes = [];

  Phase2Parser(this.sourceNodes);

  void parse() {
    for (int i = 0; i < sourceNodes.length; i++) {
      var node = sourceNodes[i];
      currentLineNodes.add(node);

      if ((node is TextNode) && (hasLineFeed(node.text))) {
        flushLine();
      }
    }
    flushLine();
  }

  // Special partial handling keep text before but not ending line
  void flushLine() {
    bool hasStandaloneNode = false;
    bool hasPartial = false;
    for (var node in currentLineNodes) {
      if (node is TextNode) {
        if (hasStandaloneNode) {
          // only end of line is accepted after the tag
          if (!isLineFeed(node.text)) {
            hasStandaloneNode = false;
            break;
          }
        } else if (!isWhitespaces(node.text)) {
          hasStandaloneNode = false;
          break;
        }
      } else if (!hasStandaloneNode) {
        if (node is CommentNode ||
            node is SectionEndNode ||
            node is SectionStartNode) {
          hasStandaloneNode = true;
        } else if (node is PartialNode) {
          hasPartial = true;
          hasStandaloneNode = true;
        } else {
          hasStandaloneNode = false;
          break;
        }
      } else {
        hasStandaloneNode = false;
        break;
      }
    }
    for (var node in currentLineNodes) {
      if (hasStandaloneNode) {
        if ((node is TextNode) && isWhitespaces(node.text)) {
          // Special partial, remove ending only
          if (hasPartial && !isLineFeed(node.text)) {
            // keep
          } else {
            // skip
            continue;
          }
        }
      }
      if (node is CommentNode) {
        continue;
      }
      nodes.add(node);
    }
    currentLineNodes.clear();
  }
}

// Handle sections
class Phase3Parser {
  final List<ParserNode> sourceNodes;
  List<ParserNode> nodes = [];

  Phase3Parser(this.sourceNodes);

  // sanitize node
  void parse() {
    // Merge in sections
    // Handle white space before/after node
    var sections = <Section>[new RootSection()];

    // no end line

    _addNode(ParserNode node) {
      var section = sections.last;
      section.add(node);
    }

    for (int i = 0; i < sourceNodes.length; i++) {
      var node = sourceNodes[i];
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
      } else {
        _addNode(node);
      }
    }

    nodes.addAll(sections[0].nodes);
  }
}

abstract class ParserNode extends Node {
  ParserNode(String text) : super(text);
}

class VariableNode extends ParserNode {
  VariableNode(String text) : super(text);
  String get name => text;
}

class NoEscapeVariableNode extends VariableNode {
  NoEscapeVariableNode(String text) : super(text);
}

class CommentNode extends ParserNode {
  CommentNode(String text) : super(text);
}

class DelimitersNode extends CommentNode {
  DelimitersNode(String text) : super(text);
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

  String get key => variable.name;

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
          return super == (other);
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

List<ParserNode> parsePhase1(String text) {
  if (text == null) {
    return null;
  }
  var source = new Phase1Parser(text);
  source.parse();
  return source.nodes;
}

List<ParserNode> parsePhase2(String text) =>
    parseNodesPhase2(parsePhase1(text));

List<ParserNode> parseNodesPhase2(List<ParserNode> nodes) {
  if (nodes == null) {
    return null;
  }
  var parser = new Phase2Parser(nodes);
  parser.parse();
  return parser.nodes;
}

List<ParserNode> parseNodesPhase3(List<ParserNode> nodes) {
  if (nodes == null) {
    return null;
  }
  var parser = new Phase3Parser(nodes);
  parser.parse();
  return parser.nodes;
}

List<ParserNode> parse(String text) => parseNodesPhase3(parsePhase2(text));
