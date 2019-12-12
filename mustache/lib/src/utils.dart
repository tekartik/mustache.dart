// Only handle space and tab
bool isInlineWhitespace(String chr) {
  return chr == ' ' || chr == '\t';
}

bool isWhitespace(String chr) {
  return chr == '\r' || chr == '\n' || isInlineWhitespace(chr);
}

bool isInlineWhitespaces(String text) {
  for (final unit in text.codeUnits) {
    if (unit != tabUnit && unit != spaceUnit) {
      return false;
    }
  }
  return true;
}

bool isWhitespaces(String text) => text.trim().isEmpty;

bool isLineFeed(String text) => text == nl || text == crnl;

// only valid for node text that always have line cut
bool hasLineFeed(String text) => text.endsWith(nl);

String nl = '\n';
int nlLength = nl.length;
String crnl = '\r\n';

int crUnit = 13;
int nlUnit = 10;
int tabUnit = 9;
int spaceUnit = 32;

// json positive basic testing
bool isPositiveValue(value) {
  if (value == true) {
    return true;
  }
  if (value is String) {
    return value.isNotEmpty;
  }
  if (value is num) {
    return value != 0;
  }
  return false;
}
