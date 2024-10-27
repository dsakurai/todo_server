
// Put public facing types in this file.

class Todo_node {

  final List<Todo_node> children;
  String text;
  final String node_id;

  List<String> child_node_ids() {
    return [ for (var child in children) child.node_id ];
  }

  Map<String, Object?> to_map() {
    return {
      "children":  child_node_ids(),
      "text":    text,
      "hash": node_id,
    };
  }

  Todo_node(
    {
      this.text = "",
      children = const [],
      required this.node_id,
    }):
     children = List.from(children)
     ;
}
