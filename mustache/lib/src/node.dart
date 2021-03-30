// Node must match exact class
abstract class Node {
  final String? text;

  Node(this.text);

  @override
  int get hashCode => text?.hashCode ?? 0;

  @override
  bool operator ==(Object other) {
    if (other is Node && other.runtimeType == runtimeType) {
      return other.text == text;
    }
    return false;
  }

  @override
  String toString() {
    return '$runtimeType: $text';
  }
}
