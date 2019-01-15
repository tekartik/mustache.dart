import 'package:collection/collection.dart';
import 'package:tekartik_mustache/src/node.dart';
import 'package:tekartik_mustache/src/scanner.dart';
import 'package:tekartik_mustache/src/source.dart';
import 'import.dart';

class RootSection extends Section {
  RootSection() : super._();

  @override
  VariableNode get variable => null;
}

/// parse [ScannerNode] as [ParserNode]
class Phase1Parser {
  final List<ParserNode> nodes = [];

  Phase1Parser();

  void addNode(ParserNode node) {
    nodes.add(node);
  }

  // convert scanner node to parse node
  void parse(String source) {
    var scannerNodes = scan(source);
    parseScannerNodes(scannerNodes);
  }

  void parseScannerNodes(List<ScannerNode> scannerNodes) {
    // standalone status
    for (var scannerNode in scannerNodes) {
      if (scannerNode is TextScannerNode) {
        addNode(TextNode(scannerNode.text));
      } else if (scannerNode is MustacheScannerNode) {
        var text = scannerNode.text;
        String firstChar = scannerNode.text.substring(0, 1);

        // Return true if valie
        bool _trim(int start) {
          text = text.substring(start).trim();
          return text.isNotEmpty;
        }

        switch (firstChar) {
          case '!':
            if (_trim(1)) {
              addNode(CommentNode(text));
            }

            break;
          case '#':
            if (_trim(1)) {
              addNode(
                  SectionStartNode(scannerNode.delimiter, scannerNode, text));
            }
            break;
          case '^':
            if (_trim(1)) {
              addNode(SectionStartNode(scannerNode.delimiter, scannerNode, text,
                  inverted: true));
            }
            break;
          case '/':
            if (_trim(1)) {
              addNode(SectionEndNode(scannerNode, text));
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
                addNode(NoEscapeVariableNode(text));
              }
            }
            break;
          case '&':
            if (_trim(1)) {
              addNode(NoEscapeVariableNode(text));
            }
            break;
          case '>':
            if (_trim(1)) {
              addNode(PartialNode(text));
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
              addNode(DelimitersNode(text));
            }
            break;

          default:
            if (_trim(0)) {
              addNode(VariableNode(text));
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
    node = SectionNode(null);
  }

  Section(SectionStartNode startNode) {
    node = SectionNode(VariableNode(startNode.text),
        startNode: startNode, inverted: startNode.inverted);
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
    var sections = <Section>[RootSection()];

    // no end line

    void _addNode(ParserNode node) {
      var section = sections.last;
      section.add(node);
    }

    void _endSection(int index, SectionEndNode endNode) {
      // truncate of the first found
      for (int i = sections.length - 1; i >= index; i--) {
        var section = sections[i];
        section.node.endNode = endNode;
      }
      sections = sections.sublist(0, index);
    }

    for (int i = 0; i < sourceNodes.length; i++) {
      var node = sourceNodes[i];
      if (node is SectionStartNode) {
        var section = Section(node);
        // first add the node then the section
        _addNode(section.node);
        sections.add(section);
      } else if (node is SectionEndNode) {
        var variableNode = VariableNode(node.text);
        var variable = variableNode.name;
        // Find the section opened from the top of the stack
        // ignoring root
        for (int i = sections.length - 1; i > 0; i--) {
          var section = sections[i];
          if (section.variable.name == variable) {
            _endSection(i, node);
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
}

class SectionNode extends ParserNode {
  SourceContent innerContent;
  final VariableNode variable;
  final SectionStartNode startNode;
  SectionEndNode endNode;
  final bool inverted;
  final List<ParserNode> nodes = [];

  String get key => variable.name;

  SectionNode(this.variable, {this.startNode, this.inverted}) : super(null);

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

class SectionDelimiterNode extends ParserNode {
  final SourceContent sourceContent;

  SectionDelimiterNode(this.sourceContent, String text) : super(text);
}

class SectionStartNode extends SectionDelimiterNode {
  final ScannerDelimiter delimiter;
  final bool inverted;

  SectionStartNode(this.delimiter, SourceContent source, String text,
      {this.inverted})
      : super(source, text);
}

class SectionEndNode extends SectionDelimiterNode {
  SectionEndNode(SourceContent source, String text) : super(source, text);
}

class PartialNode extends ParserNode {
  PartialNode(String text) : super(text);
}

List<ParserNode> parseScannerNodePhase1(List<ScannerNode> scannerNodes) {
  if (scannerNodes == null) {
    return null;
  }
  var source = Phase1Parser();
  source.parseScannerNodes(scannerNodes);
  return source.nodes;
}

List<ParserNode> parsePhase1(String text) {
  if (text == null) {
    return null;
  }
  var source = Phase1Parser();
  source.parse(text);
  return source.nodes;
}

List<ParserNode> parsePhase2(String text) =>
    parseNodesPhase2(parsePhase1(text));

List<ParserNode> parseNodesPhase2(List<ParserNode> nodes) {
  if (nodes == null) {
    return null;
  }
  var parser = Phase2Parser(nodes);
  parser.parse();
  return parser.nodes;
}

List<ParserNode> parseNodesPhase3(List<ParserNode> nodes) {
  if (nodes == null) {
    return null;
  }
  var parser = Phase3Parser(nodes);
  parser.parse();
  return parser.nodes;
}

List<ParserNode> parse(String text) => parseNodesPhase3(parsePhase2(text));

List<ParserNode> parseScannerNodes(List<ScannerNode> scannerNodes) =>
    parseNodesPhase3(parseNodesPhase2(parseScannerNodePhase1(scannerNodes)));
